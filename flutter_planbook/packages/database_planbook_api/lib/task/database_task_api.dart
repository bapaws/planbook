import 'dart:async';

import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:database_planbook_api/task/recurrence_rule_calculator.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:uuid/uuid.dart';

class DatabaseTaskApi {
  DatabaseTaskApi({
    required this.db,
    required this.tagApi,
  });

  final AppDatabase db;
  final DatabaseTagApi tagApi;

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
  }) async {
    await db.into(db.tasks).insertOnConflictUpdate(task);
  }

  List<TaskTag> generateTaskTags({
    required Task task,
    required List<TagEntity>? tags,
    required String? userId,
  }) {
    if (tags == null || tags.isEmpty) return [];

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
          createdAt: now.toUtc(),
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
            createdAt: now.toUtc(),
          ),
        );
        parent = parent.parent;
      }
    }
    return taskTags;
  }

  Future<void> create({
    required Task task,
    required List<TaskTag> taskTags,
  }) async {
    await db.transaction(() async {
      await db.into(db.tasks).insert(task);
      for (final taskTag in taskTags) {
        await db.into(db.taskTags).insert(taskTag);
      }
    });

    if (task.recurrenceRule != null) {
      unawaited(
        preGenerateTaskOccurrences(
          fromDate: task.startAt ?? task.dueAt ?? Jiffy.now(),
        ),
      );
    }
  }

  Future<void> update({
    required Task task,
    required List<TaskTag> taskTags,
  }) async {
    final existingTask = await getTaskById(task.id);

    await db.transaction(() async {
      await (db.update(
        db.tasks,
      )..where((t) => t.id.equals(task.id))).write(task.toCompanion(false));
      await (db.delete(
        db.taskTags,
      )..where((tt) => tt.taskId.equals(task.id))).go();
      for (final taskTag in taskTags) {
        await db.into(db.taskTags).insert(taskTag);
      }
    });

    if (existingTask == null) return;
    final recurrenceChanged =
        existingTask.recurrenceRule != task.recurrenceRule ||
        existingTask.startAt != task.startAt ||
        existingTask.endAt != task.endAt ||
        existingTask.dueAt != task.dueAt;

    if (!recurrenceChanged) return;
    await (db.delete(db.taskOccurrences)..where(
          (to) => to.taskId.equals(task.id),
        ))
        .go();
    unawaited(
      preGenerateTaskOccurrences(
        fromDate: task.startAt ?? task.dueAt ?? Jiffy.now(),
      ),
    );
  }

  Future<Task?> getTaskById(String taskId) async {
    return (db.select(db.tasks)
          ..where((t) => t.id.equals(taskId) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<TaskEntity?> getTaskEntityById(String taskId) async {
    final query =
        db.select(db.tasks).join([
            // 获取所有活动（completedAt 不为 null 的）
            leftOuterJoin(
              db.taskActivities,
              db.taskActivities.taskId.equalsExp(db.tasks.id) &
                  db.taskActivities.deletedAt.isNull() &
                  db.taskActivities.completedAt.isNotNull(),
            ),
            leftOuterJoin(
              db.taskTags,
              db.taskTags.taskId.equalsExp(db.tasks.id) &
                  db.taskTags.deletedAt.isNull(),
            ),
          ])
          ..where(
            db.tasks.id.equals(taskId) & db.tasks.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.desc(db.taskActivities.completedAt.datetime),
            OrderingTerm.desc(db.taskActivities.createdAt.datetime),
          ]);

    final rows = await query.get();

    if (rows.isEmpty) return null;

    // 取第一行（最新的活动）
    final row = rows.first;
    final task = row.readTable(db.tasks);
    final activity = row.readTableOrNull(db.taskActivities);

    // 查询标签（需要递归获取 parent，所以单独查询）
    final tags = await tagApi.getTagEntitiesByTaskId(task.id, task.userId);

    // 查询子任务（需要递归，所以单独查询）
    final children = await getChildTaskEntitiesById(task.id);

    return TaskEntity(
      task: task,
      tags: tags,
      activity: activity,
      children: children,
    );
  }

  Future<List<TaskEntity>> getChildTaskEntitiesById(String parentId) async {
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
      final childEntity = await getTaskEntityById(child.id);
      if (childEntity != null) {
        childEntities.add(childEntity);
      }
    }

    return childEntities;
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
  }) async {
    final startOfDay = fromDate.startOf(Unit.day);
    final endOfDay = fromDate.endOf(Unit.day);
    final startOfDayDateTime = startOfDay.toUtc().dateTime;
    final endOfDayDateTime = endOfDay.toUtc().dateTime;

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

    final recurringTasksRows = await query.get();
    final recurringTasks = recurringTasksRows
        .map((row) => row.readTable(db.tasks))
        .toList();

    if (recurringTasks.isEmpty) return;

    // 为每个任务生成所有实例
    final occurrencesToInsert = <TaskOccurrencesCompanion>[];
    for (final task in recurringTasks) {
      final startDate = task.startAt ?? task.dueAt;
      if (startDate == null) continue;

      // 生成所有实例日期
      final occurrenceDates = RecurrenceRuleCalculator.generateOccurrences(
        rule: task.recurrenceRule!,
        startDate: startDate,
        rangeStart: fromDate,
        rangeEnd: rangeEnd,
      );

      if (occurrenceDates.isEmpty) continue;

      // 为每个实例日期生成 TaskOccurrence
      for (final occurrenceDate in occurrenceDates) {
        // 计算实例的时间信息：将任务的原始时间调整到实例日期，保持时间部分不变
        final daysDiff = occurrenceDate.diff(startDate, unit: Unit.day).toInt();
        final occurrenceStartAt = task.startAt?.add(days: daysDiff);
        final occurrenceEndAt = task.endAt?.add(days: daysDiff);
        final occurrenceDueAt = task.dueAt?.add(days: daysDiff);

        occurrencesToInsert.add(
          TaskOccurrencesCompanion.insert(
            taskId: Value(task.id),
            occurrenceAt: occurrenceDate.startOf(Unit.day),
            startAt: Value(occurrenceStartAt),
            endAt: Value(occurrenceEndAt),
            dueAt: Value(occurrenceDueAt),
          ),
        );
      }
    }

    // 批量插入实例
    if (occurrencesToInsert.isNotEmpty) {
      await db.batch((batch) {
        for (final occurrence in occurrencesToInsert) {
          batch.insert(
            db.taskOccurrences,
            occurrence,
            mode: InsertMode.insertOrIgnore,
          );
        }
      });
    }
  }

  Future<List<TaskEntity>> buildTaskEntities(List<TypedResult> rows) async {
    if (rows.isEmpty) return [];

    final tasks = <String, TaskEntity>{};
    for (final row in rows) {
      final task = row.readTable(db.tasks);
      if (!tasks.containsKey(task.id)) {
        tasks[task.id] = TaskEntity(
          task: task,
          occurrence: row.readTableOrNull(db.taskOccurrences),
          activity: row.readTableOrNull(db.taskActivities),
          tags: await tagApi.getTagEntitiesByTaskId(task.id, task.userId),
        );
      }
    }
    return tasks.values.toList();
  }

  Future<Task?> deleteTaskById(String taskId) async {
    if (kDebugMode) {
      return (db.delete(db.tasks)..where(
            (t) => t.id.equals(taskId),
          ))
          .goAndReturn()
          .then((value) => value.firstOrNull);
    } else {
      return (db.update(db.tasks)..where(
            (t) => t.id.equals(taskId) & t.deletedAt.isNull(),
          ))
          .writeReturning(
            TasksCompanion(
              deletedAt: Value(Jiffy.now()),
            ),
          )
          .then((value) => value.firstOrNull);
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
}
