import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseTaskOverdueApi extends DatabaseTaskApi {
  DatabaseTaskOverdueApi({
    required super.db,
    required super.tagApi,
  });

  /// 获取指定日期内的 overdue 任务数量
  Stream<int> getOverdueTaskCount({
    required Jiffy date,
    String? userId,
    TaskPriority? priority,
  }) {
    final startOfDay = date.startOf(Unit.day).dateTime;

    // 查询 1: 重复任务的逾期实例
    // 通过 TaskOccurrences 表查询 occurrenceAt < 今天 且未完成的实例
    var recurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        db.tasks.recurrenceRule.isNotNull() &
        db.tasks.detachedFromTaskId.isNull() &
        db.taskOccurrences.deletedAt.isNull() &
        db.taskOccurrences.occurrenceAt.isSmallerThanValue(startOfDay) &
        db.taskActivities.id.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));
    if (priority != null) {
      recurringExp &= db.tasks.priority.equals(priority.name);
    }

    final recurringTasksQuery = db.selectOnly(db.tasks, distinct: true)
      ..addColumns([db.tasks.id.count()])
      ..join([
        innerJoin(
          db.taskOccurrences,
          db.taskOccurrences.taskId.equalsExp(db.tasks.id),
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

    // 查询 2: 非重复任务的逾期
    // dueAt 或 endAt < 今天 且未完成
    var nonRecurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        db.tasks.recurrenceRule.isNull() &
        db.tasks.detachedFromTaskId.isNull() &
        ((db.tasks.dueAt.isNotNull() &
                db.tasks.dueAt.isSmallerThanValue(startOfDay)) |
            (db.tasks.endAt.isNotNull() &
                db.tasks.endAt.isSmallerThanValue(startOfDay))) &
        db.taskActivities.id.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));
    if (priority != null) {
      nonRecurringExp &= db.tasks.priority.equals(priority.name);
    }

    // 查询 3: 分离实例的逾期
    // detachedRecurrenceAt < 今天 且未完成
    final detachedExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        db.tasks.detachedFromTaskId.isNotNull() &
        db.tasks.detachedRecurrenceAt.isNotNull() &
        db.tasks.detachedRecurrenceAt.isSmallerThanValue(startOfDay) &
        // 排除已完成分离的实例
        (db.tasks.detachedReason.isNull() |
            db.tasks.detachedReason.isNotValue(DetachedReason.completed.name)) &
        db.taskActivities.id.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));

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
      ..where(nonRecurringExp | detachedExp);

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

  @override
  Future<List<TaskEntity>> buildTaskEntities(
    List<TypedResult> rows, {
    Jiffy? occurrenceAt,
  }) async {
    final entities = await super.buildTaskEntities(
      rows,
      occurrenceAt: occurrenceAt,
    );
    return entities..sort((a, b) {
      final aOccurrenceAt = a.occurrence?.occurrenceAt ?? a.endAt ?? a.dueAt;
      final bOccurrenceAt = b.occurrence?.occurrenceAt ?? b.endAt ?? b.dueAt;
      if (aOccurrenceAt == null && bOccurrenceAt == null) {
        return 0;
      }
      if (aOccurrenceAt == null) {
        return 1;
      }
      if (bOccurrenceAt == null) {
        return -1;
      }
      return aOccurrenceAt.isBefore(bOccurrenceAt) ? -1 : 1;
    });
  }

  /// 获取指定日期内的 overdue 任务（已完成任务不返回）
  Stream<List<TaskEntity>> getOverdueTaskEntities({
    required Jiffy date,
    TaskPriority? priority,
    String? tagId,
    String? userId,
  }) {
    final startOfDay = date.startOf(Unit.day).dateTime;

    // 查询 1: 重复任务的逾期实例
    // 通过 TaskOccurrences 表查询 occurrenceAt < 今天 且未完成的实例
    var recurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        db.tasks.recurrenceRule.isNotNull() &
        db.tasks.detachedFromTaskId.isNull() &
        db.taskActivities.id.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));

    if (priority != null) {
      recurringExp &= db.tasks.priority.equals(priority.name);
    }

    final recurringTasksQuery = db.select(db.tasks).join([
      innerJoin(
        db.taskOccurrences,
        db.taskOccurrences.taskId.equalsExp(db.tasks.id) &
            ((db.taskOccurrences.endAt.isNotNull() &
                    db.taskOccurrences.endAt.isSmallerThanValue(
                      date.dateTime,
                    )) |
                (db.taskOccurrences.endAt.isNull() &
                    db.taskOccurrences.dueAt.isNotNull() &
                    db.taskOccurrences.dueAt.isSmallerThanValue(startOfDay))) &
            db.taskOccurrences.deletedAt.isNull(),
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
      if (tagId != null)
        innerJoin(
          db.taskTags,
          db.taskTags.taskId.equalsExp(db.tasks.id) &
              db.taskTags.tagId.equals(tagId) &
              db.taskTags.deletedAt.isNull(),
        )
      else
        leftOuterJoin(
          db.taskTags,
          db.taskTags.taskId.equalsExp(db.tasks.id) &
              db.taskTags.deletedAt.isNull(),
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

    // 查询 2: 非重复任务和分离实例的逾期
    var nonRecurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));

    // 非重复任务条件：dueAt 或 endAt < 今天
    final nonRecurringTaskCondition =
        db.tasks.recurrenceRule.isNull() &
        db.tasks.detachedFromTaskId.isNull() &
        ((db.tasks.endAt.isNotNull() &
                db.tasks.endAt.isSmallerThanValue(
                  date.dateTime,
                )) |
            (db.tasks.endAt.isNull() &
                db.tasks.dueAt.isNotNull() &
                db.tasks.dueAt.isSmallerThanValue(startOfDay))) &
        db.tasks.deletedAt.isNull();

    // 分离实例条件：detachedRecurrenceAt < 今天
    final detachedInstanceCondition =
        db.tasks.detachedFromTaskId.isNotNull() &
        db.tasks.detachedRecurrenceAt.isNotNull() &
        db.tasks.detachedRecurrenceAt.isSmallerThanValue(startOfDay) &
        // 排除已完成分离的实例
        (db.tasks.detachedReason.isNull() |
            db.tasks.detachedReason.isNotValue(DetachedReason.completed.name));

    // 组合非重复任务和分离实例的条件
    nonRecurringExp &= nonRecurringTaskCondition | detachedInstanceCondition;
    // 只查询未完成的任务
    nonRecurringExp &= db.taskActivities.id.isNull();

    if (priority != null) {
      nonRecurringExp &= db.tasks.priority.equals(priority.name);
    }

    final nonRecurringTasksQuery = db.select(db.tasks).join([
      leftOuterJoin(
        db.taskActivities,
        db.taskActivities.taskId.equalsExp(db.tasks.id) &
            db.taskActivities.occurrenceAt.isNull() &
            db.taskActivities.completedAt.isNotNull() &
            db.taskActivities.deletedAt.isNull(),
      ),
      if (tagId != null)
        innerJoin(
          db.taskTags,
          db.taskTags.taskId.equalsExp(db.tasks.id) &
              db.taskTags.tagId.equals(tagId) &
              db.taskTags.deletedAt.isNull(),
        )
      else
        leftOuterJoin(
          db.taskTags,
          db.taskTags.taskId.equalsExp(db.tasks.id) &
              db.taskTags.deletedAt.isNull(),
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

    // 合并两个查询的 Stream
    return CombineLatestStream.list<List<TypedResult>>([
      recurringTasksQuery.watch(),
      nonRecurringTasksQuery.watch(),
    ]).asyncMap((List<List<TypedResult>> results) async {
      final rows = [...results[0], ...results[1]];
      return buildTaskEntities(rows);
    });
  }

  Stream<List<TaskEntity>> getAllTodayOverdueTaskEntities({
    TaskPriority? priority,
    Jiffy? day,
    String? tagId,
    String? userId,
  }) {
    final date = day ?? Jiffy.now();
    final startOfDay = date.startOf(Unit.day).dateTime;

    // 查询 1: 重复任务的逾期实例
    // 通过 TaskOccurrences 表查询 occurrenceAt < 今天 且未完成的实例
    var recurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        db.tasks.recurrenceRule.isNotNull() &
        db.tasks.detachedFromTaskId.isNull() &
        db.taskActivities.id.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));

    if (priority != null) {
      recurringExp &= db.tasks.priority.equals(priority.name);
    }
    if (tagId != null) {
      recurringExp &= db.taskTags.tagId.equals(tagId);
    }

    final recurringTasksQuery = db.select(db.tasks).join([
      innerJoin(
        db.taskOccurrences,
        db.taskOccurrences.taskId.equalsExp(db.tasks.id) &
            ((db.taskOccurrences.endAt.isNotNull() &
                    db.taskOccurrences.endAt.isSmallerThanValue(
                      date.dateTime,
                    )) |
                (db.taskOccurrences.endAt.isNull() &
                    db.taskOccurrences.dueAt.isNotNull() &
                    db.taskOccurrences.dueAt.isSmallerThanValue(startOfDay))) &
            db.taskOccurrences.deletedAt.isNull(),
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
      leftOuterJoin(
        db.taskTags,
        db.taskTags.taskId.equalsExp(db.tasks.id) &
            db.taskTags.deletedAt.isNull(),
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

    // 查询 2: 非重复任务和分离实例的逾期
    var nonRecurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));

    // 非重复任务条件：dueAt 或 endAt < 今天
    final nonRecurringTaskCondition =
        db.tasks.recurrenceRule.isNull() &
        db.tasks.detachedFromTaskId.isNull() &
        ((db.tasks.endAt.isNotNull() &
                db.tasks.endAt.isSmallerThanValue(
                  date.dateTime,
                )) |
            (db.tasks.endAt.isNull() &
                db.tasks.dueAt.isNotNull() &
                db.tasks.dueAt.isSmallerThanValue(startOfDay)));

    // 分离实例条件：detachedRecurrenceAt < 今天
    final detachedInstanceCondition =
        db.tasks.detachedFromTaskId.isNotNull() &
        db.tasks.detachedRecurrenceAt.isNotNull() &
        db.tasks.detachedRecurrenceAt.isSmallerThanValue(startOfDay) &
        // 排除已完成分离的实例
        (db.tasks.detachedReason.isNull() |
            db.tasks.detachedReason.isNotValue(DetachedReason.completed.name));

    // 组合非重复任务和分离实例的条件
    nonRecurringExp &= nonRecurringTaskCondition | detachedInstanceCondition;
    // 只查询未完成的任务
    nonRecurringExp &= db.taskActivities.id.isNull();

    if (priority != null) {
      nonRecurringExp &= db.tasks.priority.equals(priority.name);
    }
    if (tagId != null) {
      nonRecurringExp &= db.taskTags.tagId.equals(tagId);
    }

    final nonRecurringTasksQuery = db.select(db.tasks).join([
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
