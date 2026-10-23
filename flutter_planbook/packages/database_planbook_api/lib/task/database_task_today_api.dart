import 'dart:async';
import 'dart:developer' as developer;

import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:database_planbook_api/task/task_preparation_budget.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseTaskTodayApi extends DatabaseTaskApi {
  DatabaseTaskTodayApi({
    required super.db,
    required super.tagApi,
    required super.outboxApi,
  });

  static const _preparedLifetime = Duration(seconds: 30);
  final _prepared = <_PreparedDayKey, _PreparedDayTasks>{};
  var _preparationEpoch = 0;
  var _foregroundStarted = false;

  /// 只预加载默认日列表（显示全部完成状态），不建立任务订阅或等待网络。
  /// 筛选状态不同的首页仍走原查询；大分组整组跳过，不缓存截断结果。
  Future<int> prepareHomeTaskEntities({
    required Jiffy date,
    String? userId,
    bool Function()? isCurrent,
  }) async {
    if (_foregroundStarted) return 0;
    final epoch = ++_preparationEpoch;
    _prepared.clear();
    bool valid() =>
        epoch == _preparationEpoch &&
        !_foregroundStarted &&
        (isCurrent?.call() ?? true);

    await preGenerateTaskOccurrences(fromDate: date);
    if (!valid()) return 0;
    final stopwatch = Stopwatch()..start();
    final tags =
        await (db.selectOnly(db.tags)
              ..addColumns([db.tags.id])
              ..where(
                db.tags.deletedAt.isNull() &
                    db.tags.parentId.isNull() &
                    (userId == null
                        ? db.tags.userId.isNull()
                        : db.tags.userId.equals(userId)),
              )
              ..orderBy([
                OrderingTerm.asc(db.tags.level),
                OrderingTerm.asc(db.tags.order),
                OrderingTerm.asc(db.tags.createdAt),
              ])
              ..limit(2))
            .get();
    var preparedCount = 0;
    for (final tagId in <String?>[
      null,
      ...tags.map((t) => t.read(db.tags.id)!),
    ]) {
      final budget = TaskPreparationBudget(
        isCurrent: valid,
        elapsed: () => stopwatch.elapsed,
      );
      try {
        await budget.yieldAndCheck();
        final queries = _todayQueries(date: date, tagId: tagId, userId: userId);
        queries.recurring.limit(TaskPreparationBudget.maxRows + 1);
        queries.nonRecurring.limit(TaskPreparationBudget.maxRows + 1);
        final recurring = await queries.recurring.get();
        budget.check();
        if (recurring.length > TaskPreparationBudget.maxRows) continue;
        await budget.yieldAndCheck();
        final nonRecurring = await queries.nonRecurring.get();
        budget.check();
        final rows = [...recurring, ...nonRecurring];
        if (rows.isEmpty || rows.length > TaskPreparationBudget.maxRows) {
          continue;
        }
        for (var i = 0; i < rows.length; i++) {
          if (i % TaskPreparationBudget.batchSize == 0) {
            await budget.yieldAndCheck();
          }
          for (final value in rows[i].rawData.data.values) {
            if (value is String) budget.addText(value);
          }
        }
        final entities = await assembleTaskEntities(
          rows,
          yieldBetweenBatches: true,
          preparationBudget: budget,
        );
        final entry = await _PreparedDayTasks.create(rows, entities, budget);
        budget.check();
        _prepared[_preparationKey(date, tagId, null, null, userId)] = entry;
        preparedCount++;
      } on TaskPreparationAborted catch (error) {
        // 只丢弃本组；超时/取消停止排队，不把任何部分结果交给首页。
        if (error.interrupted) break;
      }
    }
    developer.log(
      '预组装 $preparedCount 组，耗时 ${stopwatch.elapsedMilliseconds}ms',
      name: 'StartupTaskPreload',
    );
    return preparedCount;
  }

  _PreparedDayKey _preparationKey(
    Jiffy date,
    String? tagId,
    bool? isCompleted,
    TaskPriority? priority,
    String? userId,
  ) {
    final start = date.startOf(Unit.day).dateTime;
    final end = date.endOf(Unit.day).dateTime;
    return (
      start: start.microsecondsSinceEpoch,
      end: end.microsecondsSinceEpoch,
      utc: start.isUtc,
      zone: start.timeZoneName,
      userId: userId,
      tagId: tagId,
      isCompleted: isCompleted,
      priority: priority,
    );
  }

  void _retainContext(_PreparedDayKey key) {
    _prepared.removeWhere(
      (k, value) =>
          k.start != key.start ||
          k.end != key.end ||
          k.utc != key.utc ||
          k.zone != key.zone ||
          k.userId != key.userId ||
          value.age.elapsed >= _preparedLifetime,
    );
  }

  Future<List<TaskEntity>> _assembleWithPrepared(
    _PreparedDayKey key,
    List<TypedResult> rows,
  ) async {
    final entry = _prepared[key];
    if (entry == null) return buildTaskEntities(rows);
    // 不依赖通知、时间戳或哈希：完整比较本次真实查询行，顺序也必须相同。
    // 因此同步、其他连接写入、实例改期和子任务变化均不能误命中。
    if (entry.age.elapsed >= _preparedLifetime ||
        rows.length != entry.rows.length) {
      _prepared.remove(key);
      return buildTaskEntities(rows);
    }
    for (var i = 0; i < rows.length; i++) {
      if (!mapEquals(rows[i].rawData.data, entry.rows[i])) {
        _prepared.remove(key);
        return buildTaskEntities(rows);
      }
    }
    // task_tags 没有投影，tags 也不在任务 JOIN 中；仍按原逻辑读最新关联和父标签。
    final currentTags = await tagApi.getTagEntitiesByTaskIds({
      for (final entity in entry.entities) entity.id: entity.task.userId,
    });
    if (identical(_prepared[key], entry) &&
        entry.age.elapsed < _preparedLifetime &&
        entry.entities.every(
          (e) => listEquals(e.tags, currentTags[e.id] ?? const <TagEntity>[]),
        )) {
      developer.log('复用日列表组装结果', name: 'StartupTaskPreload');
      return List<TaskEntity>.of(entry.entities);
    }
    if (identical(_prepared[key], entry)) _prepared.remove(key);
    return assembleTaskEntities(rows, currentTags: currentTags);
  }

  Stream<int> getTodayTaskCount({
    required Jiffy date,
    TaskPriority? priority,
    bool? isCompleted,
    String? userId,
  }) {
    _foregroundStarted = true;
    _preparationEpoch++;
    final startOfDay = date.startOf(Unit.day);
    final endOfDay = date.endOf(Unit.day);
    final startOfDayDateTime = startOfDay.dateTime;
    final endOfDayDateTime = endOfDay.dateTime;

    // 异步预生成实例（不阻塞 Stream）
    preGenerateTaskOccurrences(fromDate: date).ignore();

    // 查询 1: 通过 TaskOccurrences 表查询重复任务实例（未完成）
    var recurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        db.tasks.recurrenceRule.isNotNull() &
        db.tasks.detachedFromTaskId.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));

    if (isCompleted != null) {
      recurringExp &= isCompleted
          ? db.taskActivities.id.isNotNull()
          : db.taskActivities.id.isNull();
    }
    if (priority != null) {
      recurringExp &= db.tasks.priority.equals(priority.name);
    }

    final recurringTasksQuery = db.selectOnly(db.tasks, distinct: true)
      ..addColumns([db.tasks.id.count()])
      ..join([
        innerJoin(
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
        leftOuterJoin(
          db.taskActivities,
          db.taskActivities.taskId.equalsExp(db.tasks.id) &
              db.taskActivities.occurrenceAt.equalsExp(
                db.taskOccurrences.occurrenceAt,
              ) &
              db.taskActivities.completedAt.isNotNull() &
              db.taskActivities.deletedAt.isNull(),
        ),
      ])
      ..where(recurringExp);

    // 查询 2: 非重复任务和分离实例（未完成）
    var nonRecurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));
    if (priority != null) {
      nonRecurringExp &= db.tasks.priority.equals(priority.name);
    }
    // 非重复任务：日期在指定日期范围内
    final nonRecurringTaskCondition =
        db.tasks.recurrenceRule.isNull() &
        db.tasks.detachedFromTaskId.isNull() &
        ((db.tasks.startAt.isNotNull() &
                db.tasks.startAt.isSmallerOrEqualValue(endOfDayDateTime) &
                ((db.tasks.endAt.isNotNull() &
                        db.tasks.endAt.isBiggerOrEqualValue(
                          startOfDayDateTime,
                        )) |
                    (db.tasks.endAt.isNull() &
                        db.tasks.startAt.isBiggerOrEqualValue(
                          startOfDayDateTime,
                        )))) |
            (db.tasks.dueAt.isNotNull() &
                db.tasks.dueAt.isBiggerOrEqualValue(startOfDayDateTime) &
                db.tasks.dueAt.isSmallerOrEqualValue(endOfDayDateTime)));

    // 分离实例按实际安排的 start/end/due 落在这一天。
    // detachedRecurrenceAt 只记录被替换的原始重复日，改期后不能再用它决定显示日期。
    final detachedInstanceCondition =
        db.tasks.detachedFromTaskId.isNotNull() &
        ((db.tasks.startAt.isNotNull() &
                db.tasks.startAt.isSmallerOrEqualValue(endOfDayDateTime) &
                ((db.tasks.endAt.isNotNull() &
                        db.tasks.endAt.isBiggerOrEqualValue(
                          startOfDayDateTime,
                        )) |
                    (db.tasks.endAt.isNull() &
                        db.tasks.startAt.isBiggerOrEqualValue(
                          startOfDayDateTime,
                        )))) |
            (db.tasks.dueAt.isNotNull() &
                db.tasks.dueAt.isBiggerOrEqualValue(startOfDayDateTime) &
                db.tasks.dueAt.isSmallerOrEqualValue(endOfDayDateTime))) &
        // 排除已完成分离的实例
        (db.tasks.detachedReason.isNull() |
            db.tasks.detachedReason.isNotValue(DetachedReason.completed.name));

    // 组合非重复任务和分离实例的条件
    nonRecurringExp &= nonRecurringTaskCondition | detachedInstanceCondition;

    if (isCompleted != null) {
      nonRecurringExp &= isCompleted
          ? db.taskActivities.id.isNotNull()
          : db.taskActivities.id.isNull();
    }

    final nonRecurringTasksQuery = db.selectOnly(db.tasks, distinct: true)
      ..addColumns([db.tasks.id.count()])
      ..join([
        leftOuterJoin(
          db.taskActivities,
          db.taskActivities.taskId.equalsExp(db.tasks.id) &
              db.taskActivities.occurrenceAt.isNull() &
              db.taskActivities.completedAt.isNotNull() &
              db.taskActivities.deletedAt.isNull(),
        ),
      ])
      ..where(nonRecurringExp);

    // 合并两个查询的计数
    return CombineLatestStream.list<int>([
      recurringTasksQuery.watch().map(
        (rows) => rows.isEmpty ? 0 : rows.first.read(db.tasks.id.count()) ?? 0,
      ),
      nonRecurringTasksQuery.watch().map(
        (rows) => rows.isEmpty ? 0 : rows.first.read(db.tasks.id.count()) ?? 0,
      ),
    ]).map((counts) => counts[0] + counts[1]);
  }

  Stream<List<TaskEntity>> getTaskEntities({
    required Jiffy date,
    String? tagId,
    bool? isCompleted,
    TaskPriority? priority,
    String? userId,
  }) {
    // 首页保持原来的查询和订阅；不等待尚未结束的预加载。
    _foregroundStarted = true;
    _preparationEpoch++;
    preGenerateTaskOccurrences(fromDate: date).ignore();
    final key = _preparationKey(date, tagId, isCompleted, priority, userId);
    _retainContext(key);
    final queries = _todayQueries(
      date: date,
      tagId: tagId,
      isCompleted: isCompleted,
      priority: priority,
      userId: userId,
    );
    return CombineLatestStream.list<List<TypedResult>>([
      queries.recurring.watch(),
      queries.nonRecurring.watch(),
    ]).asyncMap(
      (results) => _assembleWithPrepared(
        key,
        [...results[0], ...results[1]],
      ),
    );
  }

  ({
    JoinedSelectStatement<HasResultSet, dynamic> recurring,
    JoinedSelectStatement<HasResultSet, dynamic> nonRecurring,
  })
  _todayQueries({
    required Jiffy date,
    String? tagId,
    bool? isCompleted,
    TaskPriority? priority,
    String? userId,
  }) {
    final startOfDay = date.startOf(Unit.day).dateTime;
    final endOfDay = date.endOf(Unit.day).dateTime;

    // 查询 1: 通过 TaskOccurrences 表查询重复任务实例
    var recurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        db.tasks.recurrenceRule.isNotNull() &
        db.tasks.detachedFromTaskId.isNull() &
        db.taskOccurrences.deletedAt.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));
    if (isCompleted != null) {
      recurringExp &= isCompleted
          ? db.taskActivities.id.isNotNull()
          : db.taskActivities.id.isNull();
    }
    if (tagId == null) {
      recurringExp &= db.taskTags.id.isNull();
    }
    if (priority != null) {
      recurringExp &= db.tasks.priority.equals(priority.name);
    }

    final recurringTasksQuery = db.select(db.tasks).join([
      innerJoin(
        db.taskOccurrences,
        db.taskOccurrences.taskId.equalsExp(db.tasks.id) &
            db.taskOccurrences.deletedAt.isNull() &
            ((db.taskOccurrences.dueAt.isNotNull() &
                    db.taskOccurrences.dueAt.isBiggerOrEqualValue(
                      startOfDay,
                    ) &
                    db.taskOccurrences.dueAt.isSmallerThanValue(
                      endOfDay,
                    )) |
                (db.taskOccurrences.startAt.isNotNull() &
                    db.taskOccurrences.startAt.isSmallerThanValue(
                      endOfDay,
                    ) &
                    db.taskOccurrences.endAt.isNotNull() &
                    db.taskOccurrences.endAt.isBiggerOrEqualValue(
                      startOfDay,
                    ))),
      ),
      // LEFT JOIN TaskActivities 来检查完成状态
      // 对于重复任务，需要匹配 occurrenceAt
      leftOuterJoin(
        db.taskActivities,
        db.taskActivities.taskId.equalsExp(db.tasks.id) &
            db.taskActivities.occurrenceAt.equalsExp(
              db.taskOccurrences.occurrenceAt,
            ) &
            db.taskActivities.completedAt.isNotNull() &
            db.taskActivities.deletedAt.isNull(),
      ),
      // 如果需要按标签筛选，则 JOIN TaskTags
      if (tagId != null)
        innerJoin(
          db.taskTags,
          db.taskTags.taskId.equalsExp(db.tasks.id) &
              db.taskTags.tagId.equals(tagId) &
              db.taskTags.deletedAt.isNull(),
          useColumns: false,
        )
      else
        leftOuterJoin(
          db.taskTags,
          db.taskTags.taskId.equalsExp(db.tasks.id) &
              db.taskTags.deletedAt.isNull(),
          useColumns: false,
        ),
      leftOuterJoin(
        childrenTasks,
        childrenTasks.parentId.equalsExp(db.tasks.id) &
            childrenTasks.deletedAt.isNull(),
      ),
      leftOuterJoin(
        childrenTaskActivities,
        childrenTaskActivities.taskId.equalsExp(childrenTasks.id) &
            childrenTaskActivities.occurrenceAt.equalsExp(
              db.taskOccurrences.occurrenceAt,
            ) &
            childrenTaskActivities.completedAt.isNotNull() &
            childrenTaskActivities.deletedAt.isNull(),
      ),
    ])..where(recurringExp);

    // 查询 2: 非重复任务和分离实例
    // 构建基础条件
    var nonRecurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));

    // 非重复任务：日期在指定日期范围内
    final nonRecurringTaskCondition =
        db.tasks.recurrenceRule.isNull() &
        db.tasks.detachedFromTaskId.isNull() &
        ((db.tasks.startAt.isNotNull() &
                db.tasks.startAt.isSmallerOrEqualValue(endOfDay) &
                ((db.tasks.endAt.isNotNull() &
                        db.tasks.endAt.isBiggerOrEqualValue(
                          startOfDay,
                        )) |
                    (db.tasks.endAt.isNull() &
                        db.tasks.startAt.isBiggerOrEqualValue(
                          startOfDay,
                        )))) |
            (db.tasks.dueAt.isNotNull() &
                db.tasks.dueAt.isBiggerOrEqualValue(startOfDay) &
                db.tasks.dueAt.isSmallerOrEqualValue(endOfDay)));

    // 分离实例按实际安排的 start/end/due 落在这一天。
    // detachedRecurrenceAt 只记录被替换的原始重复日。
    var detachedInstanceCondition =
        db.tasks.detachedFromTaskId.isNotNull() &
        ((db.tasks.startAt.isNotNull() &
                db.tasks.startAt.isSmallerOrEqualValue(endOfDay) &
                ((db.tasks.endAt.isNotNull() &
                        db.tasks.endAt.isBiggerOrEqualValue(startOfDay)) |
                    (db.tasks.endAt.isNull() &
                        db.tasks.startAt.isBiggerOrEqualValue(startOfDay)))) |
            (db.tasks.dueAt.isNotNull() &
                db.tasks.dueAt.isBiggerOrEqualValue(startOfDay) &
                db.tasks.dueAt.isSmallerOrEqualValue(endOfDay)));

    // 根据 isCompleted 参数决定是否排除已完成分离的实例
    if (isCompleted != null && !isCompleted) {
      detachedInstanceCondition &=
          db.tasks.detachedReason.isNull() |
          db.tasks.detachedReason.isNotValue(DetachedReason.completed.name);
    }

    // 组合非重复任务和分离实例的条件
    nonRecurringExp &= nonRecurringTaskCondition | detachedInstanceCondition;

    // 根据 isCompleted 参数决定是否排除已完成的任务
    if (isCompleted != null) {
      nonRecurringExp &= isCompleted
          ? db.taskActivities.id.isNotNull()
          : db.taskActivities.id.isNull();
    }

    // 如果指定了标签筛选，添加标签条件
    if (tagId == null) {
      nonRecurringExp &= db.taskTags.id.isNull();
    }

    if (priority != null) {
      nonRecurringExp &= db.tasks.priority.equals(priority.name);
    }

    final nonRecurringTasksQuery = db.select(db.tasks).join([
      // LEFT JOIN TaskActivities 来检查完成状态
      // 对于非重复任务，不需要匹配 occurrenceAt
      leftOuterJoin(
        db.taskActivities,
        db.taskActivities.taskId.equalsExp(db.tasks.id) &
            db.taskActivities.occurrenceAt.isNull() &
            db.taskActivities.completedAt.isNotNull() &
            db.taskActivities.deletedAt.isNull(),
      ),
      // 如果需要按标签筛选，则 JOIN TaskTags
      if (tagId != null)
        innerJoin(
          db.taskTags,
          db.taskTags.taskId.equalsExp(db.tasks.id) &
              db.taskTags.tagId.equals(tagId) &
              db.taskTags.deletedAt.isNull(),
          useColumns: false,
        )
      else
        leftOuterJoin(
          db.taskTags,
          db.taskTags.taskId.equalsExp(db.tasks.id) &
              db.taskTags.deletedAt.isNull(),
          useColumns: false,
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
    ])..where(nonRecurringExp);

    return (
      recurring: recurringTasksQuery,
      nonRecurring: nonRecurringTasksQuery,
    );
  }

  /// 获取所有今天需要执行的任务，包括今天未完成和已完成任务
  Stream<List<TaskEntity>> getAllTodayTaskEntities({
    Jiffy? day,
    String? tagId,
    TaskPriority? priority,
    bool? isCompleted,
    String? userId,
  }) {
    _foregroundStarted = true;
    _preparationEpoch++;
    final date = day ?? Jiffy.now();
    final startOfDay = date.startOf(Unit.day).dateTime;
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // 异步预生成实例（不阻塞 Stream）
    preGenerateTaskOccurrences(fromDate: date).ignore();

    // 查询 1: 通过 TaskOccurrences 表查询重复任务实例
    var recurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        db.tasks.recurrenceRule.isNotNull() &
        db.tasks.detachedFromTaskId.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));
    if (priority != null) {
      recurringExp &= db.tasks.priority.equals(priority.name);
    }
    if (tagId != null) {
      recurringExp &= db.taskTags.tagId.equals(tagId);
    }
    if (isCompleted != null) {
      recurringExp &= isCompleted
          ? db.taskActivities.id.isNotNull()
          : db.taskActivities.id.isNull();
    }
    final recurringTasksQuery =
        db.select(db.tasks).join([
            innerJoin(
              db.taskOccurrences,
              db.taskOccurrences.taskId.equalsExp(db.tasks.id) &
                  db.taskOccurrences.deletedAt.isNull() &
                  ((db.taskOccurrences.dueAt.isNotNull() &
                          db.taskOccurrences.dueAt.isBiggerOrEqualValue(
                            startOfDay,
                          ) &
                          db.taskOccurrences.dueAt.isSmallerThanValue(
                            endOfDay,
                          )) |
                      (db.taskOccurrences.startAt.isNotNull() &
                          db.taskOccurrences.startAt.isSmallerThanValue(
                            endOfDay,
                          ) &
                          db.taskOccurrences.endAt.isNotNull() &
                          db.taskOccurrences.endAt.isBiggerOrEqualValue(
                            startOfDay,
                          ))),
            ),
            // LEFT JOIN TaskActivities 来检查完成状态
            // 对于重复任务，需要匹配 occurrenceAt
            leftOuterJoin(
              db.taskActivities,
              db.taskActivities.taskId.equalsExp(db.tasks.id) &
                  db.taskActivities.occurrenceAt.equalsExp(
                    db.taskOccurrences.occurrenceAt,
                  ) &
                  db.taskActivities.completedAt.isNotNull() &
                  db.taskActivities.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.taskTags,
              db.taskTags.taskId.equalsExp(db.tasks.id) &
                  db.taskTags.deletedAt.isNull(),
              useColumns: false,
            ),
            leftOuterJoin(
              childrenTasks,
              childrenTasks.parentId.equalsExp(db.tasks.id) &
                  childrenTasks.deletedAt.isNull(),
            ),
            leftOuterJoin(
              childrenTaskActivities,
              childrenTaskActivities.taskId.equalsExp(childrenTasks.id) &
                  childrenTaskActivities.occurrenceAt.equalsExp(
                    db.taskOccurrences.occurrenceAt,
                  ) &
                  childrenTaskActivities.deletedAt.isNull(),
            ),
          ])
          ..where(recurringExp)
          ..orderBy([
            OrderingTerm.asc(db.tasks.order),
            OrderingTerm.desc(db.tasks.endAt.datetime, nulls: NullsOrder.last),
            OrderingTerm.asc(db.tasks.priority),
          ]);

    // 查询 2: 非重复任务和分离实例
    // 构建基础条件
    var nonRecurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));
    if (priority != null) {
      nonRecurringExp &= db.tasks.priority.equals(priority.name);
    }
    if (tagId != null) {
      nonRecurringExp &= db.taskTags.tagId.equals(tagId);
    }

    // 非重复任务：日期在指定日期范围内
    final nonRecurringTaskCondition =
        db.tasks.recurrenceRule.isNull() &
        db.tasks.detachedFromTaskId.isNull() &
        ((db.tasks.startAt.isNotNull() &
                db.tasks.startAt.isSmallerThanValue(endOfDay) &
                ((db.tasks.endAt.isNotNull() &
                        db.tasks.endAt.isBiggerOrEqualValue(
                          startOfDay,
                        )) |
                    (db.tasks.endAt.isNull() &
                        db.tasks.startAt.isBiggerOrEqualValue(
                          startOfDay,
                        )))) |
            (db.tasks.dueAt.isNotNull() &
                db.tasks.dueAt.isBiggerOrEqualValue(startOfDay) &
                db.tasks.dueAt.isSmallerThanValue(endOfDay)));

    // 分离实例按实际安排的 start/end/due 落在这一天。
    // detachedRecurrenceAt 只记录被替换的原始重复日。
    var detachedInstanceCondition =
        db.tasks.detachedFromTaskId.isNotNull() &
        ((db.tasks.startAt.isNotNull() &
                db.tasks.startAt.isSmallerThanValue(endOfDay) &
                ((db.tasks.endAt.isNotNull() &
                        db.tasks.endAt.isBiggerOrEqualValue(startOfDay)) |
                    (db.tasks.endAt.isNull() &
                        db.tasks.startAt.isBiggerOrEqualValue(startOfDay)))) |
            (db.tasks.dueAt.isNotNull() &
                db.tasks.dueAt.isBiggerOrEqualValue(startOfDay) &
                db.tasks.dueAt.isSmallerThanValue(endOfDay)));
    // 根据 isCompleted 参数决定是否排除已完成分离的实例
    if (isCompleted != null && !isCompleted) {
      detachedInstanceCondition &=
          db.tasks.detachedReason.isNull() |
          db.tasks.detachedReason.isNotValue(DetachedReason.completed.name);
    }

    // 组合非重复任务和分离实例的条件
    nonRecurringExp &= nonRecurringTaskCondition | detachedInstanceCondition;

    if (isCompleted != null) {
      nonRecurringExp &= isCompleted
          ? db.taskActivities.id.isNotNull()
          : db.taskActivities.id.isNull();
    }

    final nonRecurringTasksQuery =
        db.select(db.tasks).join([
            // LEFT JOIN TaskActivities 来检查完成状态
            // 对于非重复任务，不需要匹配 occurrenceAt
            leftOuterJoin(
              db.taskActivities,
              db.taskActivities.taskId.equalsExp(db.tasks.id) &
                  db.taskActivities.occurrenceAt.isNull() &
                  db.taskActivities.completedAt.isNotNull() &
                  db.taskActivities.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.taskTags,
              db.taskTags.taskId.equalsExp(db.tasks.id) &
                  db.taskTags.deletedAt.isNull(),
              useColumns: false,
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
          ..where(nonRecurringExp)
          ..orderBy([
            OrderingTerm.asc(db.tasks.order),
            OrderingTerm.desc(db.tasks.endAt.datetime, nulls: NullsOrder.last),
            OrderingTerm.asc(db.tasks.priority),
          ]);

    // 合并两个查询的 Stream
    return CombineLatestStream.list<List<TypedResult>>([
      recurringTasksQuery.watch(),
      nonRecurringTasksQuery.watch(),
    ]).asyncMap((List<List<TypedResult>> results) async {
      final rows = [...results[0], ...results[1]];
      return buildTaskEntities(rows);
    });
  }
}

typedef _PreparedDayKey = ({
  int start,
  int end,
  bool utc,
  String zone,
  String? userId,
  String? tagId,
  bool? isCompleted,
  TaskPriority? priority,
});

class _PreparedDayTasks {
  _PreparedDayTasks(this.rows, this.entities);

  final List<Map<String, dynamic>> rows;
  final List<TaskEntity> entities;
  final Stopwatch age = Stopwatch()..start();

  static Future<_PreparedDayTasks> create(
    List<TypedResult> rows,
    List<TaskEntity> entities,
    TaskPreparationBudget budget,
  ) async {
    final snapshots = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (snapshots.length % TaskPreparationBudget.batchSize == 0) {
        await budget.yieldAndCheck();
      }
      snapshots.add(Map.unmodifiable(row.rawData.data));
    }
    final frozen = <TaskEntity>[];
    for (final entity in entities) {
      if (frozen.length % TaskPreparationBudget.batchSize == 0) {
        await budget.yieldAndCheck();
      }
      frozen.add(await _freeze(entity, budget));
    }
    budget.check();
    return _PreparedDayTasks(snapshots, frozen);
  }

  static Future<TaskEntity> _freeze(
    TaskEntity entity,
    TaskPreparationBudget budget,
  ) async {
    budget.check();
    final children = <TaskEntity>[];
    for (final child in entity.children) {
      if (children.length % TaskPreparationBudget.batchSize == 0) {
        await budget.yieldAndCheck();
      }
      children.add(await _freeze(child, budget));
    }
    final task = entity.task;
    final rule = task.recurrenceRule;
    // 旧月份字段也需隔离，不能在缓存中改写存量规则。
    // ignore: deprecated_member_use
    final legacyMonths = rule?.monthsOfYear;
    // 拷贝并冻结 Task 内部所有集合，不能只冻结 TaskEntity 外层列表。
    final frozenRule = rule?.copyWith(
      daysOfWeek: rule.daysOfWeek == null
          ? null
          : List.unmodifiable(rule.daysOfWeek!),
      daysOfMonth: rule.daysOfMonth == null
          ? null
          : List.unmodifiable(rule.daysOfMonth!),
      weeksOfMonth: rule.weeksOfMonth == null
          ? null
          : List.unmodifiable(rule.weeksOfMonth!),
      monthsOfYear: legacyMonths == null
          ? null
          : List.unmodifiable(legacyMonths),
      daysOfYear: rule.daysOfYear == null
          ? null
          : List.unmodifiable(rule.daysOfYear!),
    );
    budget.check();
    return entity.copyWith(
      task: task.copyWith(
        alarms: List<EventAlarm>.unmodifiable(task.alarms),
        recurrenceRule: Value(frozenRule),
      ),
      tags: List.unmodifiable(entity.tags),
      taskTags: List.unmodifiable(entity.taskTags),
      children: List.unmodifiable(children),
    );
  }
}
