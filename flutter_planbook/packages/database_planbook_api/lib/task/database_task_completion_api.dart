import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseTaskCompletionApi extends DatabaseTaskApi {
  DatabaseTaskCompletionApi({
    required super.db,
    required super.tagApi,
  });

  /// 切换任务完成状态
  ///
  /// 任务未完成时创建 TaskActivity，任务已完成时软删除对应记录。
  /// 同时根据子任务状态递归更新上级任务。
  /// 切换任务完成状态
  ///
  /// 通过查询数据库检查当前任务是否完成，如果已完成则取消完成，如果未完成则完成
  /// 同时根据子任务状态递归更新上级任务。
  ///
  /// 返回所有创建或标记删除的 taskActivities 对象
  Future<List<TaskActivity>> completeTaskById(String taskId) async {
    final task = await getTaskById(taskId);
    if (task == null) return [];

    final isRecurring = _isRecurringTask(task);
    Jiffy? occurrenceAt;

    if (isRecurring) {
      final today = Jiffy.now().startOf(Unit.day);
      final todayDateTime = today.toUtc().dateTime;

      var occurrence =
          await (db.select(db.taskOccurrences)
                ..where(
                  (to) =>
                      to.taskId.equals(taskId) &
                      to.deletedAt.isNull() &
                      to.occurrenceAt.isBiggerOrEqualValue(todayDateTime),
                )
                ..orderBy([
                  (to) => OrderingTerm(expression: to.occurrenceAt),
                ])
                ..limit(1))
              .getSingleOrNull();

      occurrence ??=
          await (db.select(db.taskOccurrences)
                ..where(
                  (to) =>
                      to.taskId.equals(taskId) &
                      to.deletedAt.isNull() &
                      to.occurrenceAt.isSmallerOrEqualValue(todayDateTime),
                )
                ..orderBy([
                  (to) => OrderingTerm(
                    expression: to.occurrenceAt,
                    mode: OrderingMode.desc,
                  ),
                ])
                ..limit(1))
              .getSingleOrNull();

      if (occurrence == null) {
        return [];
      }

      occurrenceAt = occurrence.occurrenceAt;
    } else {
      occurrenceAt = null;
    }

    final existingActivity = await getTaskActivityForTask(
      task,
      occurrenceAt: occurrenceAt,
    );

    if (existingActivity != null) {
      return _deleteCompletionActivity(
        task: task,
        activity: existingActivity,
        occurrenceAt: occurrenceAt,
      );
    } else {
      return _insertCompletionActivity(
        task: task,
        occurrenceAt: occurrenceAt,
      );
    }
  }

  bool _isRecurringTask(Task task) =>
      task.recurrenceRule != null && task.detachedFromTaskId == null;

  Future<TaskActivity?> getTaskActivityForTask(
    Task task, {
    required Jiffy? occurrenceAt,
  }) async {
    final query = db.select(db.taskActivities)
      ..where(
        (ta) =>
            ta.taskId.equals(task.id) &
            ta.completedAt.isNotNull() &
            ta.deletedAt.isNull(),
      );

    if (_isRecurringTask(task)) {
      if (occurrenceAt == null) return null;
      final occurrenceAtDateTime = occurrenceAt.toUtc().dateTime;
      query.where((ta) => ta.occurrenceAt.equals(occurrenceAtDateTime));
    } else {
      query.where((ta) => ta.occurrenceAt.isNull());
    }

    return query.getSingleOrNull();
  }

  Future<List<TaskActivity>> _insertCompletionActivity({
    required Task task,
    required Jiffy? occurrenceAt,
    bool cascade = true,
  }) async {
    final activityOccurrence = _isRecurringTask(task) ? occurrenceAt : null;

    final activity = await db
        .into(db.taskActivities)
        .insertReturning(
          TaskActivitiesCompanion.insert(
            taskId: Value(task.id),
            occurrenceAt: Value(activityOccurrence),
            completedAt: Value(Jiffy.now()),
            activityType: const Value('completed'),
          ),
        );

    final activities = [activity];

    if (cascade) {
      final parentActivities = await _maybeCompleteParentTask(
        task,
        occurrenceAt,
      );
      activities.addAll(parentActivities);
    }

    return activities;
  }

  Future<List<TaskActivity>> _deleteCompletionActivity({
    required Task task,
    required TaskActivity activity,
    required Jiffy? occurrenceAt,
    bool cascade = true,
  }) async {
    await (db.update(db.taskActivities)..where(
          (ta) => ta.id.equals(activity.id),
        ))
        .write(
          TaskActivitiesCompanion(
            deletedAt: Value(Jiffy.now()),
          ),
        );

    // 重新查询更新后的 activity（包含 deletedAt）
    final updatedActivity = await (db.select(
      db.taskActivities,
    )..where((ta) => ta.id.equals(activity.id))).getSingle();

    final activities = [updatedActivity];

    if (cascade) {
      final parentActivities = await _maybeUncompleteParentTask(
        task,
        occurrenceAt,
      );
      activities.addAll(parentActivities);
    }

    return activities;
  }

  Future<List<TaskActivity>> _maybeCompleteParentTask(
    Task childTask,
    Jiffy? occurrenceAt,
  ) async {
    final parentId = childTask.parentId;
    if (parentId == null) return [];

    final parentTask = await getTaskById(parentId);
    if (parentTask == null) return [];

    final allChildrenCompleted = await _areAllChildrenCompleted(
      parentId,
      occurrenceAt,
    );
    if (!allChildrenCompleted) return [];

    // 子任务与父任务的重复规则一致，直接使用传入的 occurrenceAt
    final parentActivity = await getTaskActivityForTask(
      parentTask,
      occurrenceAt: occurrenceAt,
    );

    if (parentActivity != null) {
      // 父任务已完成，继续向上递归
      return _maybeCompleteParentTask(parentTask, occurrenceAt);
    }

    return _insertCompletionActivity(
      task: parentTask,
      occurrenceAt: occurrenceAt,
    );
  }

  Future<List<TaskActivity>> _maybeUncompleteParentTask(
    Task childTask,
    Jiffy? occurrenceAt,
  ) async {
    final parentId = childTask.parentId;
    if (parentId == null) return [];

    final parentTask = await getTaskById(parentId);
    if (parentTask == null) return [];

    // 子任务刚被取消完成，如果父任务已完成，则取消完成
    // 子任务与父任务的重复规则一致，直接使用传入的 occurrenceAt
    final parentActivity = await getTaskActivityForTask(
      parentTask,
      occurrenceAt: occurrenceAt,
    );

    if (parentActivity == null) return [];

    return _deleteCompletionActivity(
      task: parentTask,
      activity: parentActivity,
      occurrenceAt: occurrenceAt,
    );
  }

  Future<bool> _areAllChildrenCompleted(
    String parentId,
    Jiffy? occurrenceAt,
  ) async {
    Expression<bool> activityCondition;
    if (occurrenceAt != null) {
      activityCondition = db.taskActivities.occurrenceAt.equals(
        occurrenceAt.toUtc().dateTime,
      );
    } else {
      activityCondition = db.taskActivities.occurrenceAt.isNull();
    }

    final query =
        db.select(db.tasks).join([
          leftOuterJoin(
            db.taskActivities,
            db.taskActivities.taskId.equalsExp(db.tasks.id) &
                activityCondition &
                db.taskActivities.completedAt.isNotNull() &
                db.taskActivities.deletedAt.isNull(),
          ),
        ])..where(
          db.tasks.parentId.equals(parentId) & db.tasks.deletedAt.isNull(),
        );

    final results = await query.get();
    if (results.isEmpty) return false;
    return !results.any(
      (row) => row.readTableOrNull(db.taskActivities) == null,
    );
  }

  Stream<List<TaskEntity>> getCompletedTaskEntities({
    required Jiffy date,
    TaskPriority? priority,
    int limit = 10,
  }) {
    final startOfDay = date.startOf(Unit.day);
    final endOfDay = date.endOf(Unit.day);
    final startOfDayDateTime = startOfDay.toUtc().dateTime;
    final endOfDayDateTime = endOfDay.toUtc().dateTime;

    // 查询 1: 通过 TaskOccurrences 表查询重复任务实例（在指定日期完成）
    var recurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        db.tasks.recurrenceRule.isNotNull() &
        db.tasks.detachedFromTaskId.isNull() &
        db.taskOccurrences.deletedAt.isNull();

    if (priority != null) {
      recurringExp &= db.tasks.priority.equals(priority.name);
    }

    final recurringTasksQuery =
        db.select(db.tasks).join([
            innerJoin(
              db.taskOccurrences,
              db.taskOccurrences.taskId.equalsExp(db.tasks.id),
            ),
            innerJoin(
              db.taskActivities,
              db.taskActivities.taskId.equalsExp(db.tasks.id) &
                  db.taskActivities.occurrenceAt.equalsExp(
                    db.taskOccurrences.occurrenceAt,
                  ) &
                  db.taskActivities.completedAt.isNotNull() &
                  db.taskActivities.completedAt.isBiggerOrEqualValue(
                    startOfDayDateTime,
                  ) &
                  db.taskActivities.completedAt.isSmallerOrEqualValue(
                    endOfDayDateTime,
                  ) &
                  db.taskActivities.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.taskTags,
              db.taskTags.taskId.equalsExp(db.tasks.id) &
                  db.taskTags.deletedAt.isNull(),
            ),
          ])
          ..where(recurringExp)
          ..orderBy([
            OrderingTerm.desc(db.taskActivities.completedAt.datetime),
            OrderingTerm.asc(db.tasks.order),
            OrderingTerm.asc(db.tasks.createdAt.datetime),
          ])
          ..limit(limit);

    // 查询 2: 非重复任务和分离实例（在指定日期完成）
    var nonRecurringExp =
        db.tasks.parentId.isNull() & db.tasks.deletedAt.isNull();

    if (priority != null) {
      nonRecurringExp &= db.tasks.priority.equals(priority.name);
    }

    final nonRecurringTasksQuery =
        db.select(db.tasks).join([
            innerJoin(
              db.taskActivities,
              db.taskActivities.taskId.equalsExp(db.tasks.id) &
                  db.taskActivities.occurrenceAt.isNull() &
                  db.taskActivities.completedAt.isNotNull() &
                  db.taskActivities.completedAt.isBiggerOrEqualValue(
                    startOfDayDateTime,
                  ) &
                  db.taskActivities.completedAt.isSmallerOrEqualValue(
                    endOfDayDateTime,
                  ) &
                  db.taskActivities.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.taskTags,
              db.taskTags.taskId.equalsExp(db.tasks.id) &
                  db.taskTags.deletedAt.isNull(),
            ),
          ])
          ..where(nonRecurringExp)
          ..orderBy([
            OrderingTerm.desc(db.taskActivities.completedAt.datetime),
            OrderingTerm.asc(db.tasks.order),
            OrderingTerm.asc(db.tasks.createdAt.datetime),
          ])
          ..limit(limit);

    // 合并两个查询的 Stream
    return CombineLatestStream.list<List<TypedResult>>([
      recurringTasksQuery.watch(),
      nonRecurringTasksQuery.watch(),
    ]).asyncMap((List<List<TypedResult>> results) async {
      final rows = [...results[0], ...results[1]];
      return buildTaskEntities(rows);
    });
  }

  Stream<int> getCompletedTaskCount({
    required Jiffy date,
  }) {
    final startOfDay = date.startOf(Unit.day);
    final endOfDay = date.endOf(Unit.day);
    final startOfDayDateTime = startOfDay.toUtc().dateTime;
    final endOfDayDateTime = endOfDay.toUtc().dateTime;

    final query = db.selectOnly(db.taskActivities)
      ..addColumns([db.taskActivities.taskId.count(distinct: true)])
      ..where(
        db.taskActivities.completedAt.isNotNull() &
            db.taskActivities.completedAt.isBiggerOrEqualValue(
              startOfDayDateTime,
            ) &
            db.taskActivities.completedAt.isSmallerOrEqualValue(
              endOfDayDateTime,
            ) &
            db.taskActivities.deletedAt.isNull() &
            db.taskActivities.taskId.isNotNull(),
      );

    return query.watch().map(
      (rows) => rows.firstOrNull?.read(db.taskActivities.id.count()) ?? 0,
    );
  }
}
