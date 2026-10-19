import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:database_planbook_api/task/task_occurrence_generator.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:uuid/uuid.dart';

class DatabaseTaskApi {
  DatabaseTaskApi({
    required this.db,
    required this.tagApi,
    required this.outboxApi,
    TaskOccurrenceGenerator? occurrenceGenerator,
  }) : occurrenceGenerator =
           occurrenceGenerator ?? TaskOccurrenceGenerator.shared;

  final AppDatabase db;
  final DatabaseTagApi tagApi;
  final OutboxApi outboxApi;
  final TaskOccurrenceGenerator occurrenceGenerator;

  // 事务上下文分别合并，避免事务内等待排在其后面的外部写入。
  // 请求完成后移除；并发调用要求再检查一次，防止期间创建的新任务漏生成。
  static final _occurrenceRequests =
      Expando<Map<(Zone, int, int), _OccurrenceRequest>>();

  late final $TasksTable childrenTasks = db.alias(db.tasks, 'children_tasks');
  late final $TaskActivitiesTable childrenTaskActivities = db.alias(
    db.taskActivities,
    'children_task_activities',
  );

  Future<bool> hasPendingChanges(String taskId) => outboxApi.hasPending(taskId);

  Future<int> getTotalCount({required String? userId}) async {
    final query = db.selectOnly(db.tasks, distinct: true)
      ..addColumns([db.tasks.id.count()])
      ..where(
        db.tasks.deletedAt.isNull() &
            (userId == null
                ? db.tasks.userId.isNull()
                : db.tasks.userId.equals(userId)),
      );
    final result = await query.getSingleOrNull();
    return result?.read(db.tasks.id.count()) ?? 0;
  }

  Future<void> insertOrUpdate({
    required Task task,
    bool refreshOccurrences = false,
  }) async {
    await db.transaction(() async {
      final existingTask = await getTaskById(task.id);
      await db.into(db.tasks).insertOnConflictUpdate(task);
      final scheduleChanged =
          existingTask?.recurrenceRule != task.recurrenceRule ||
          existingTask?.startAt != task.startAt ||
          existingTask?.endAt != task.endAt ||
          existingTask?.dueAt != task.dueAt ||
          existingTask?.deletedAt != task.deletedAt ||
          existingTask?.parentId != task.parentId ||
          existingTask?.detachedFromTaskId != task.detachedFromTaskId;
      if (scheduleChanged || refreshOccurrences) {
        await _refreshCachedTaskOccurrences(task);
      }
    });
  }

  /// 同步的规则计算在事务外执行；提交时重验本地任务、实例和 Outbox。
  /// 关联写入仍与任务、实例一起提交；重试不覆盖期间到达的本地修改。
  Future<bool> applySyncedTask({
    required Task task,
    required bool refreshOccurrences,
    required Future<void> Function() writeRelated,
    required void Function() validateAccount,
    bool localRepair = false,
    Future<bool> Function(String)? protectLocal,
  }) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      validateAccount();
      if (!localRepair &&
          (await hasPendingChanges(task.id) ||
              (protectLocal != null && await protectLocal(task.id)))) {
        return false;
      }
      final previous = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(task.id))).getSingleOrNull();
      if (localRepair &&
          jsonEncode(previous?.toJson()) != jsonEncode(task.toJson())) {
        return false;
      }
      final cached =
          await (db.select(db.taskOccurrences)
                ..where((o) => o.taskId.equals(task.id))
                ..orderBy([(o) => OrderingTerm.asc(o.occurrenceAt)]))
              .get();
      final rebuild =
          refreshOccurrences ||
          previous?.recurrenceRule != task.recurrenceRule ||
          previous?.startAt != task.startAt ||
          previous?.endAt != task.endAt ||
          previous?.dueAt != task.dueAt ||
          previous?.deletedAt != task.deletedAt ||
          previous?.parentId != task.parentId ||
          previous?.detachedFromTaskId != task.detachedFromTaskId;
      final generated =
          rebuild &&
              cached.isNotEmpty &&
              task.deletedAt == null &&
              task.parentId == null &&
              task.detachedFromTaskId == null &&
              task.recurrenceRule != null
          ? await occurrenceGenerator.generate(
              schedules: [occurrenceScheduleOf(task)],
              rangeStart: cached.first.occurrenceAt,
              rangeEnd: cached.last.occurrenceAt,
            )
          : <TaskOccurrencesCompanion>[];
      final hiddenDates = cached
          .where((o) => o.deletedAt != null)
          .map((o) => o.occurrenceAt.dateTime.microsecondsSinceEpoch)
          .toSet();
      final expected = {
        for (final row in generated)
          if (!hiddenDates.contains(
            row.occurrenceAt.value.dateTime.microsecondsSinceEpoch,
          ))
            row.occurrenceAt.value.dateTime.microsecondsSinceEpoch: row,
      };
      final live = cached.where((o) => o.deletedAt == null).toList();
      final cacheMatches =
          live.length == expected.length &&
          live.every((row) {
            final wanted =
                expected[row.occurrenceAt.dateTime.microsecondsSinceEpoch];
            return wanted != null &&
                wanted.startAt.value == row.startAt &&
                wanted.endAt.value == row.endAt &&
                wanted.dueAt.value == row.dueAt;
          });
      final result = await db.transaction<bool?>(() async {
        validateAccount();
        if (!localRepair &&
            (await hasPendingChanges(task.id) ||
                (protectLocal != null && await protectLocal(task.id)))) {
          return false;
        }
        // Drift 的列表转换列默认按 List 身份比较；用序列化值核验完整快照。
        final current = await (db.select(
          db.tasks,
        )..where((t) => t.id.equals(task.id))).getSingleOrNull();
        if (jsonEncode(current?.toJson()) != jsonEncode(previous?.toJson())) {
          return null;
        }
        final latest =
            await (db.select(db.taskOccurrences)
                  ..where((o) => o.taskId.equals(task.id))
                  ..orderBy([(o) => OrderingTerm.asc(o.occurrenceAt)]))
                .get();
        if (!listEquals(cached, latest)) return null;
        if (!localRepair &&
            jsonEncode(previous?.toJson()) != jsonEncode(task.toJson())) {
          await db.into(db.tasks).insertOnConflictUpdate(task);
        }
        // 旧实例修复与远程全量解耦；内容等价时不重写，避免唤醒全部首页订阅。
        if (rebuild && cached.isNotEmpty && !cacheMatches) {
          await (db.delete(db.taskOccurrences)..where(
                (o) => o.taskId.equals(task.id) & o.deletedAt.isNull(),
              ))
              .go();
          await db.batch((batch) {
            batch.insertAll(
              db.taskOccurrences,
              generated,
              mode: InsertMode.insertOrIgnore,
            );
          });
        }
        await writeRelated();
        validateAccount();
        return true;
      });
      if (result != null) return result;
    }
    throw StateError('同步快照持续变化，停止本次合并并保留游标重试');
  }

  /// 升级时按本地权威规则校正旧缓存。即使存在 Outbox 也只修缓存，不回写任务。
  /// 已取消规则、已删除任务也必须清理有效实例，并保留隐藏标记。
  Future<void> repairLegacyOccurrences({
    required String? userId,
    required void Function() validateAccount,
  }) async {
    final ids = await (db.selectOnly(
      db.taskOccurrences,
      distinct: true,
    )..addColumns([db.taskOccurrences.taskId])).get();
    for (final row in ids) {
      final id = row.read(db.taskOccurrences.taskId)!;
      for (var attempt = 0; ; attempt++) {
        validateAccount();
        final task =
            await (db.select(db.tasks)..where(
                  (t) =>
                      t.id.equals(id) &
                      (userId == null
                          ? t.userId.isNull()
                          : t.userId.equals(userId)),
                ))
                .getSingleOrNull();
        if (task == null) break;
        if (await applySyncedTask(
          task: task,
          refreshOccurrences: true,
          localRepair: true,
          writeRelated: () async {},
          validateAccount: validateAccount,
        )) {
          break;
        }
        if (attempt >= 7) throw StateError('旧实例修复期间任务持续变化，保留标记重试');
      }
    }
    validateAccount();
  }

  /// 按最新规则重建已缓存的日期范围，保留单次删除或分离实例的隐藏标记。
  Future<void> _refreshCachedTaskOccurrences(Task task) async {
    final cached =
        await (db.select(db.taskOccurrences)
              ..where((o) => o.taskId.equals(task.id))
              ..orderBy([(o) => OrderingTerm.asc(o.occurrenceAt)]))
            .get();
    if (cached.isEmpty) return;

    await (db.delete(db.taskOccurrences)..where(
          (o) => o.taskId.equals(task.id) & o.deletedAt.isNull(),
        ))
        .go();
    if (task.deletedAt != null ||
        task.parentId != null ||
        task.detachedFromTaskId != null ||
        task.recurrenceRule == null) {
      return;
    }

    // 保持原有缓存窗口，确保正在浏览的历史或未来日期也能立即刷新。
    final occurrences = await occurrenceGenerator.generate(
      schedules: [occurrenceScheduleOf(task)],
      rangeStart: cached.first.occurrenceAt,
      rangeEnd: cached.last.occurrenceAt,
    );
    await db.batch((batch) {
      batch.insertAll(
        db.taskOccurrences,
        occurrences,
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  List<TaskTag>? generateTaskTags({
    required Task task,
    required List<TagEntity>? tags,
    required String? userId,
  }) {
    if (tags == null) return null;

    final taskTags = <TaskTag>[];
    const uuid = Uuid();
    final now = Jiffy.now();
    for (final tag in tags) {
      taskTags.add(
        TaskTag(
          id: uuid.v4(),
          taskId: task.id,
          tagId: tag.id,
          userId: userId,
          createdAt: now,
        ),
      );
      var parent = tag.parent;
      while (parent != null) {
        taskTags.add(
          TaskTag(
            id: uuid.v4(),
            taskId: task.id,
            tagId: parent.id,
            linkedTagId: tag.id,
            userId: userId,
            createdAt: now,
          ),
        );
        parent = parent.parent;
      }
    }
    return taskTags;
  }

  Future<void> create({
    required Task task,
    List<TaskTag>? taskTags,
    List<Task>? children,
  }) async {
    await db.transaction(() async {
      await db.into(db.tasks).insert(task);
      await outboxApi.enqueue(
        tableName: 'tasks',
        recordId: task.id,
        operation: 'insert',
        payload: jsonEncode(task.toJson()),
      );

      if (taskTags != null && taskTags.isNotEmpty) {
        for (final taskTag in taskTags) {
          await db.into(db.taskTags).insert(taskTag);
        }
        await outboxApi.enqueue(
          tableName: 'task_tags',
          recordId: task.id,
          operation: 'replace_associations',
          payload: jsonEncode({
            'parent_id': task.id,
            'associations': taskTags.map((e) => e.toJson()).toList(),
          }),
        );
      }

      if (children != null && children.isNotEmpty) {
        for (final child in children) {
          await db.into(db.tasks).insert(child);
          await outboxApi.enqueue(
            tableName: 'tasks',
            recordId: child.id,
            operation: 'insert',
            payload: jsonEncode(child.toJson()),
          );
        }
      }
    });

    if (task.recurrenceRule != null) {
      preGenerateTaskOccurrencesInBackground(
        fromDate: task.startAt ?? task.dueAt ?? Jiffy.now(),
      );
    }
  }

  Future<Task?> getTaskById(String taskId) async {
    return (db.select(db.tasks)
          ..where((t) => t.id.equals(taskId) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// 获取所有带闹钟的重复任务（用于滚动补 schedule）
  Future<List<Task>> getRecurringTasksWithAlarms({
    required String? userId,
  }) async {
    final query = db.select(db.tasks)
      ..where(
        (t) =>
            t.deletedAt.isNull() &
            t.recurrenceRule.isNotNull() &
            t.alarms.isNotNull() &
            (userId == null ? t.userId.isNull() : t.userId.equals(userId)),
      );
    final list = await query.get();
    return list
        .where(
          (t) => t.alarms.isNotEmpty && (t.startAt != null || t.dueAt != null),
        )
        .toList();
  }

  Future<TaskEntity?> getTaskEntityById(
    String taskId, {
    Jiffy? occurrenceAt,
  }) async {
    var taskActivitiesExp =
        db.taskActivities.taskId.equals(taskId) &
        db.taskActivities.deletedAt.isNull() &
        db.taskActivities.completedAt.isNotNull();
    var taskOccurrencesExp = db.taskOccurrences.taskId.equalsExp(
      db.tasks.id,
    );
    var childrenTaskActivitiesExp =
        childrenTaskActivities.taskId.equalsExp(childrenTasks.id) &
        childrenTaskActivities.deletedAt.isNull() &
        childrenTaskActivities.completedAt.isNotNull();
    if (occurrenceAt != null) {
      final dateTime = occurrenceAt.dateTime;
      taskActivitiesExp &= db.taskActivities.occurrenceAt.equals(dateTime);

      taskOccurrencesExp &= db.taskOccurrences.occurrenceAt.equals(dateTime);

      childrenTaskActivitiesExp &= childrenTaskActivities.occurrenceAt.equals(
        dateTime,
      );
    }
    final query =
        db.select(db.tasks).join([
            // 获取所有活动（completedAt 不为 null 的）
            leftOuterJoin(db.taskActivities, taskActivitiesExp),
            leftOuterJoin(
              db.taskTags,
              db.taskTags.taskId.equalsExp(db.tasks.id) &
                  db.taskTags.deletedAt.isNull(),
            ),
            leftOuterJoin(db.taskOccurrences, taskOccurrencesExp),

            leftOuterJoin(
              childrenTasks,
              childrenTasks.parentId.equalsExp(db.tasks.id) &
                  childrenTasks.deletedAt.isNull(),
            ),
            leftOuterJoin(childrenTaskActivities, childrenTaskActivitiesExp),
          ])
          ..where(
            db.tasks.id.equals(taskId) & db.tasks.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.desc(db.taskActivities.completedAt.datetime),
            OrderingTerm.desc(db.taskActivities.createdAt.datetime),
          ]);

    final rows = await query.get();

    final tasks = await buildTaskEntities(rows, occurrenceAt: occurrenceAt);
    return tasks.firstOrNull;
  }

  Future<TaskOccurrence?> getTaskOccurrenceById(
    String taskId, {
    Jiffy? occurrenceAt,
  }) async {
    return (db.select(db.taskOccurrences)..where((t) {
          var exp = t.taskId.equals(taskId) & t.deletedAt.isNull();
          if (occurrenceAt != null) {
            final startOfDay = occurrenceAt.startOf(Unit.day).dateTime;
            final endOfDay = occurrenceAt.endOf(Unit.day).dateTime;
            exp &=
                t.occurrenceAt.isBiggerOrEqualValue(startOfDay) &
                t.occurrenceAt.isSmallerOrEqualValue(endOfDay);
          }
          return exp;
        }))
        .getSingleOrNull();
  }

  Future<List<TaskEntity>> getChildTaskEntitiesById(
    String parentId, {
    Jiffy? occurrenceAt,
  }) async {
    final children =
        await (db.select(db.tasks)
              ..where(
                (t) => t.parentId.equals(parentId) & t.deletedAt.isNull(),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.order),
                (t) => OrderingTerm.asc(t.createdAt.datetime),
              ]))
            .get();

    final childEntities = <TaskEntity>[];
    for (final child in children) {
      final childEntity = await getTaskEntityById(
        child.id,
        occurrenceAt: occurrenceAt,
      );
      if (childEntity != null) {
        childEntities.add(childEntity);
      }
    }

    return childEntities;
  }

  /// 创建/编辑后的派生缓存异步补齐，错误独立记录，不改变主任务的提交结果。
  void preGenerateTaskOccurrencesInBackground({required Jiffy fromDate}) {
    unawaited(
      preGenerateTaskOccurrences(fromDate: fromDate).then<void>(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          developer.log(
            '后台实例生成失败，后续查询仍可重试',
            name: 'TaskOccurrences',
            error: error,
            stackTrace: stackTrace,
          );
        },
      ),
    );
  }

  /// 预生成任务实例
  ///
  /// 为有重复规则的任务从指定日期开始预生成未来一段时间内的所有实例。
  /// 这样可以提高查询性能，避免每次查询时重复计算重复规则。
  ///
  /// [fromDate] 开始日期，从该日期开始生成实例
  /// [monthsAhead] 预生成的月数，默认为3个月
  ///
  /// 使用 insertOrIgnore 模式，数据库会自动忽略重复的实例（基于唯一约束 {taskId, occurrenceAt}）
  Future<void> preGenerateTaskOccurrences({
    required Jiffy fromDate,
    int monthsAhead = 3,
  }) {
    final requests = _occurrenceRequests[db] ??= {};
    final key = (
      Zone.current,
      fromDate.startOf(Unit.day).dateTime.microsecondsSinceEpoch,
      monthsAhead,
    );
    final pending = requests[key];
    if (pending != null) {
      pending.checkAgain = true;
      return pending.future;
    }
    final request = _OccurrenceRequest();
    requests[key] = request;
    return request.future =
        (() async {
          do {
            request.checkAgain = false;
            await _preGenerateTaskOccurrences(
              fromDate: fromDate.startOf(Unit.day),
              monthsAhead: monthsAhead,
            );
          } while (request.checkAgain);
        })().whenComplete(() {
          requests.remove(key);
        });
  }

  Future<void> _preGenerateTaskOccurrences({
    required Jiffy fromDate,
    required int monthsAhead,
  }) async {
    final startOfDay = fromDate.startOf(Unit.day);
    final endOfDay = fromDate.endOf(Unit.day);
    final startOfDayDateTime = startOfDay.dateTime;
    final endOfDayDateTime = endOfDay.dateTime;

    // 计算预生成范围
    final rangeEnd = fromDate.add(months: monthsAhead);

    // 查询有重复规则但可能没有对应日期实例的任务
    // 使用 LEFT JOIN 排除已经存在实例的任务（在指定日期）
    final query =
        db.select(db.tasks).join([
          leftOuterJoin(
            db.taskOccurrences,
            db.taskOccurrences.taskId.equalsExp(db.tasks.id) &
                db.taskOccurrences.deletedAt.isNull() &
                db.taskOccurrences.occurrenceAt.isBiggerOrEqualValue(
                  startOfDayDateTime,
                ) &
                db.taskOccurrences.occurrenceAt.isSmallerOrEqualValue(
                  endOfDayDateTime,
                ),
          ),
        ])..where(
          db.tasks.parentId.isNull() &
              db.tasks.deletedAt.isNull() &
              db.tasks.recurrenceRule.isNotNull() &
              db.tasks.detachedFromTaskId.isNull() &
              // 起始日期在指定日期之前或等于指定日期
              ((db.tasks.startAt.isNotNull() &
                      db.tasks.startAt.isSmallerOrEqualValue(
                        endOfDayDateTime,
                      )) |
                  (db.tasks.dueAt.isNotNull() &
                      db.tasks.dueAt.isSmallerOrEqualValue(
                        endOfDayDateTime,
                      ))) &
              // 排除已经存在实例的任务（taskOccurrences.id 为 null 表示没有匹配的实例）
              db.taskOccurrences.id.isNull(),
        );

    // 候选查询与规则计算都在本方法自己的写事务之外。
    // 最后再扫描一次新任务/新规则，覆盖计算期间已到达的同步结果。
    final processed = <TaskOccurrenceSchedule>{};
    while (true) {
      final rows = await query.get();
      final candidates = rows
          .map((row) => row.readTable(db.tasks))
          .where((task) => !processed.contains(occurrenceScheduleOf(task)))
          .toList();
      if (candidates.isEmpty) return;

      const batchSize = 32;
      for (var offset = 0; offset < candidates.length; offset += batchSize) {
        var pending = candidates.skip(offset).take(batchSize).toList();
        final covered = await _coveredSchedules(
          pending.map(occurrenceScheduleOf).toList(),
          fromDate,
          rangeEnd,
        );
        processed.addAll(covered);
        pending = pending
            .where(
              (task) => !covered.contains(occurrenceScheduleOf(task)),
            )
            .toList();
        while (pending.isNotEmpty) {
          final schedules = pending.map(occurrenceScheduleOf).toList();
          final generated = await occurrenceGenerator.generate(
            schedules: schedules,
            rangeStart: fromDate,
            rangeEnd: rangeEnd,
          );
          pending = await _writeGeneratedOccurrences(
            schedules: schedules,
            generated: generated,
            rangeStart: fromDate,
            rangeEnd: rangeEnd,
          );
          processed.addAll(schedules);
        }
      }
    }
  }

  /// 纯计算摘要即使命中，也必须确认原表中每个日期仍存在（含隐藏标记）。
  Future<Set<TaskOccurrenceSchedule>> _coveredSchedules(
    List<TaskOccurrenceSchedule> schedules,
    Jiffy rangeStart,
    Jiffy rangeEnd,
  ) async {
    final expected = <TaskOccurrenceSchedule, List<int>>{};
    final window = occurrenceGenerator.cacheWindowFor(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    for (final schedule in schedules) {
      final dates = occurrenceGenerator.expectedDates(
        cacheWindow: window,
        schedule: schedule,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
      if (dates != null) expected[schedule] = dates;
    }
    if (expected.isEmpty) return {};
    final keys = <(String?, int)>{};
    final ids = expected.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key.taskId)
        .toList();
    if (ids.isNotEmpty) {
      final rows =
          await (db.select(db.taskOccurrences)..where(
                (o) =>
                    o.taskId.isIn(ids) &
                    o.occurrenceAt.isBiggerOrEqualValue(
                      rangeStart.startOf(Unit.day).dateTime,
                    ) &
                    o.occurrenceAt.isSmallerOrEqualValue(
                      rangeEnd.endOf(Unit.day).dateTime,
                    ),
              ))
              .get();
      keys.addAll(
        rows.map(
          (o) => (o.taskId, o.occurrenceAt.dateTime.microsecondsSinceEpoch),
        ),
      );
    }
    return {
      for (final entry in expected.entries)
        if (entry.value.every(
          (date) => keys.contains((entry.key.taskId, date)),
        ))
          entry.key,
    };
  }

  /// 校验和写入之间保持原子性，但不在事务里等待规则计算。
  Future<List<Task>> _writeGeneratedOccurrences({
    required List<TaskOccurrenceSchedule> schedules,
    required List<TaskOccurrencesCompanion> generated,
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
  }) => db.transaction(() async {
    final expected = {
      for (final schedule in schedules) schedule.taskId: schedule,
    };
    final latest = await (db.select(
      db.tasks,
    )..where((t) => t.id.isIn(expected.keys))).get();
    final validIds = <String>{};
    final retry = <Task>[];
    for (final task in latest) {
      // 已删除、变成子任务/分离实例或移到窗口之后时，旧结果直接丢弃。
      final anchor = rangeStart.endOf(Unit.day);
      final eligible =
          task.deletedAt == null &&
          task.parentId == null &&
          task.detachedFromTaskId == null &&
          task.recurrenceRule != null &&
          ((task.startAt != null && !task.startAt!.isAfter(anchor)) ||
              (task.dueAt != null && !task.dueAt!.isAfter(anchor)));
      if (!eligible) continue;
      if (occurrenceScheduleOf(task) == expected[task.id]) {
        validIds.add(task.id);
      } else {
        // 规则变化不能被当作准备成功，下一轮按最新快照重新计算。
        retry.add(task);
      }
    }
    if (validIds.isEmpty || generated.isEmpty) return retry;

    // 包含已删除的行，保护单次删除/分离的隐藏标记；只补真正缺失的实例。
    final existing =
        await (db.select(db.taskOccurrences)..where(
              (o) =>
                  o.taskId.isIn(validIds) &
                  o.occurrenceAt.isBiggerOrEqualValue(
                    rangeStart.startOf(Unit.day).dateTime,
                  ) &
                  o.occurrenceAt.isSmallerOrEqualValue(
                    rangeEnd.endOf(Unit.day).dateTime,
                  ),
            ))
            .get();
    final keys = {
      for (final row in existing) (row.taskId, row.occurrenceAt.dateTime),
    };
    final missing = generated
        .where(
          (row) =>
              validIds.contains(row.taskId.value) &&
              !keys.contains((
                row.taskId.value,
                row.occurrenceAt.value.dateTime,
              )),
        )
        .toList();
    if (missing.isNotEmpty) {
      await db.batch(
        (batch) => batch.insertAll(
          db.taskOccurrences,
          missing,
          mode: InsertMode.insertOrIgnore,
        ),
      );
    }
    return retry;
  });

  Stream<int> getPlannedTaskCountByDateRange(
    Jiffy from,
    Jiffy to, {
    String? userId,
  }) {
    final start = from.startOf(Unit.day).dateTime;
    final end = to.endOf(Unit.day).dateTime;

    var exp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));

    final inRange =
        (db.tasks.startAt.isSmallerOrEqualValue(end) &
            db.tasks.endAt.isBiggerOrEqualValue(start)) |
        (db.tasks.dueAt.isBiggerOrEqualValue(start) &
            db.tasks.dueAt.isSmallerOrEqualValue(end)) |
        (db.tasks.recurrenceRule.isNotNull() &
            db.tasks.startAt.isSmallerOrEqualValue(end));

    exp &= inRange;

    final column = db.tasks.id.count(distinct: true);
    final query = db.selectOnly(db.tasks)
      ..addColumns([column])
      ..where(exp);

    return query.watch().map(
      (rows) => rows.firstOrNull?.read(column) ?? 0,
    );
  }

  Future<List<TaskEntity>> buildTaskEntities(
    List<TypedResult> rows, {
    Jiffy? occurrenceAt,
  }) async {
    if (rows.isEmpty) return [];

    // JOIN 会把标签、活动、实例和子任务组合成多行；只在最终组装时创建父实体，
    // 子任务按主键保留首次出现顺序，避免每行查找/复制不断增长的 children 列表。
    final grouped = <String, _TaskEntityRows>{};
    for (final row in rows) {
      final task = row.readTable(db.tasks);
      final group = grouped.putIfAbsent(task.id, () => _TaskEntityRows(task));
      group.occurrence =
          row.readTableOrNull(db.taskOccurrences) ?? group.occurrence;
      group.activity = row.readTableOrNull(db.taskActivities) ?? group.activity;
      final child = row.readTableOrNull(childrenTasks);
      if (child != null && !group.children.containsKey(child.id)) {
        group.children[child.id] = TaskEntity(
          task: child,
          activity: row.readTableOrNull(childrenTaskActivities),
        );
      }
    }
    final tagsByTaskId = await tagApi.getTagEntitiesByTaskIds({
      for (final group in grouped.values) group.task.id: group.task.userId,
    });
    return [
      for (final group in grouped.values)
        TaskEntity(
          task: group.task,
          tags: tagsByTaskId[group.task.id] ?? const [],
          occurrence: group.occurrence,
          activity: group.activity,
          children: group.children.values.toList(),
        ),
    ];
  }

  Future<Task?> deleteTaskById(String taskId) async {
    if (kDebugMode) {
      return (db.delete(db.tasks)..where(
            (t) => t.id.equals(taskId),
          ))
          .goAndReturn()
          .then((value) => value.firstOrNull);
    } else {
      return db.transaction(() async {
        final result =
            await (db.update(db.tasks)..where(
                  (t) => t.id.equals(taskId) & t.deletedAt.isNull(),
                ))
                .writeReturning(
                  TasksCompanion(
                    deletedAt: Value(Jiffy.now()),
                  ),
                );
        final task = result.firstOrNull;
        if (task != null) {
          await outboxApi.enqueue(
            tableName: 'tasks',
            recordId: task.id,
            operation: 'delete',
            payload: jsonEncode(task.toJson()),
          );
        }
        return task;
      });
    }
  }

  Future<Jiffy?> getStartDate() async {
    final row =
        await (db.select(
                db.tasks,
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt.datetime)])
              ..limit(1))
            .getSingleOrNull();
    return row?.createdAt;
  }

  /// 获取指定标签下的任务
  Stream<List<TaskEntity>> getTaskEntitiesByTag({
    required String tagId,
    bool? isCompleted,
    String? userId,
  }) {
    return getTaskEntitiesByTags(
      tagIds: [tagId],
      isCompleted: isCompleted,
      userId: userId,
    );
  }

  /// 获取指定多个标签下的任务（命中任一标签即可）
  Stream<List<TaskEntity>> getTaskEntitiesByTags({
    required List<String> tagIds,
    bool? isCompleted,
    String? userId,
  }) {
    if (tagIds.isEmpty) {
      return Stream.value(const []);
    }

    var exp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));

    if (isCompleted != null) {
      exp &= isCompleted
          ? db.taskActivities.id.isNotNull()
          : db.taskActivities.id.isNull();
    }

    final query =
        db.select(db.tasks).join([
            innerJoin(
              db.taskTags,
              db.taskTags.taskId.equalsExp(db.tasks.id) &
                  db.taskTags.tagId.isIn(tagIds) &
                  db.taskTags.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.taskActivities,
              db.taskActivities.taskId.equalsExp(db.tasks.id) &
                  db.taskActivities.occurrenceAt.isNull() &
                  db.taskActivities.completedAt.isNotNull() &
                  db.taskActivities.deletedAt.isNull(),
            ),
            leftOuterJoin(
              childrenTasks,
              childrenTasks.parentId.equalsExp(db.tasks.id) &
                  childrenTasks.deletedAt.isNull(),
            ),
            leftOuterJoin(
              childrenTaskActivities,
              childrenTaskActivities.taskId.equalsExp(childrenTasks.id) &
                  childrenTaskActivities.occurrenceAt.isNull() &
                  childrenTaskActivities.completedAt.isNotNull() &
                  childrenTaskActivities.deletedAt.isNull(),
            ),
          ])
          ..where(exp)
          ..orderBy([
            OrderingTerm.asc(db.tasks.order),
            OrderingTerm.desc(db.taskActivities.completedAt.datetime),
            OrderingTerm.asc(db.tasks.createdAt.datetime),
          ]);

    return query.watch().asyncMap(buildTaskEntities);
  }

  /// 按关键词搜索任务（标题 / 备注内容）
  Future<List<TaskEntity>> searchTaskEntities({
    required String query,
    required String? userId,
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final pattern = '%${_escapeLikePattern(trimmed)}%';
    final userExp = userId == null
        ? db.tasks.userId.isNull()
        : db.tasks.userId.equals(userId);
    final matchExp =
        db.tasks.title.like(pattern, escapeChar: r'\') |
        db.tasks.notes.like(pattern, escapeChar: r'\');

    final idQuery = db.selectOnly(db.tasks)
      ..addColumns([
        db.tasks.id,
        db.tasks.updatedAt,
        db.tasks.createdAt,
      ])
      ..where(db.tasks.deletedAt.isNull() & userExp & matchExp)
      ..orderBy([
        OrderingTerm.desc(db.tasks.updatedAt),
        OrderingTerm.desc(db.tasks.createdAt),
      ])
      ..limit(limit);

    final ids = await idQuery.map((row) => row.read(db.tasks.id)!).get();
    if (ids.isEmpty) return [];

    final results = <TaskEntity>[];
    for (final id in ids) {
      final entity = await getTaskEntityById(id);
      if (entity != null) results.add(entity);
    }
    return results;
  }
}

class _OccurrenceRequest {
  late Future<void> future;
  bool checkAgain = false;
}

String _escapeLikePattern(String input) {
  return input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// 仅限一次查询结果的临时组装，不跨查询缓存业务数据。
class _TaskEntityRows {
  _TaskEntityRows(this.task);
  final Task task;
  TaskOccurrence? occurrence;
  TaskActivity? activity;
  final children = <String, TaskEntity>{};
}
