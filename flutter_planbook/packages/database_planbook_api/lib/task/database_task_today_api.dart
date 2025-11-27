import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseTaskTodayApi extends DatabaseTaskApi {
  DatabaseTaskTodayApi({
    required super.db,
    required super.tagApi,
  });

  Stream<int> getTodayTaskCount({required Jiffy date}) {
    final startOfDay = date.startOf(Unit.day);
    final endOfDay = date.endOf(Unit.day);
    final startOfDayDateTime = startOfDay.toUtc().dateTime;
    final endOfDayDateTime = endOfDay.toUtc().dateTime;

    // 异步预生成实例（不阻塞 Stream）
    preGenerateTaskOccurrences(fromDate: date).ignore();

    // 查询 1: 通过 TaskOccurrences 表查询重复任务实例（未完成）
    final recurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        db.tasks.recurrenceRule.isNotNull() &
        db.tasks.detachedFromTaskId.isNull() &
        db.taskOccurrences.deletedAt.isNull() &
        db.taskOccurrences.occurrenceAt.isBiggerOrEqualValue(
          startOfDayDateTime,
        ) &
        db.taskOccurrences.occurrenceAt.isSmallerOrEqualValue(
          endOfDayDateTime,
        ) &
        // 未完成任务：不存在对应的 taskActivity
        db.taskActivities.id.isNull();

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

    // 查询 2: 非重复任务和分离实例（未完成）
    var nonRecurringExp =
        db.tasks.parentId.isNull() & db.tasks.deletedAt.isNull();

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

    // 分离实例：detachedRecurrenceAt 匹配指定日期
    final detachedInstanceCondition =
        db.tasks.detachedFromTaskId.isNotNull() &
        db.tasks.detachedRecurrenceAt.isNotNull() &
        db.tasks.detachedRecurrenceAt.isBiggerOrEqualValue(
          startOfDayDateTime,
        ) &
        db.tasks.detachedRecurrenceAt.isSmallerOrEqualValue(
          endOfDayDateTime,
        ) &
        // 排除已完成分离的实例
        (db.tasks.detachedReason.isNull() |
            db.tasks.detachedReason.isNotValue(DetachedReason.completed.name));

    // 组合非重复任务和分离实例的条件
    nonRecurringExp &= nonRecurringTaskCondition | detachedInstanceCondition;

    // 未完成任务：不存在对应的 taskActivity
    nonRecurringExp &= db.taskActivities.id.isNull();

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
  }) {
    final startOfDay = date.startOf(Unit.day);
    final endOfDay = date.endOf(Unit.day);
    final startOfDayDateTime = startOfDay.toUtc().dateTime;
    final endOfDayDateTime = endOfDay.toUtc().dateTime;

    // 异步预生成实例（不阻塞 Stream）
    preGenerateTaskOccurrences(fromDate: date).ignore();

    // 查询 1: 通过 TaskOccurrences 表查询重复任务实例
    var recurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        db.tasks.recurrenceRule.isNotNull() &
        db.tasks.detachedFromTaskId.isNull() &
        db.taskOccurrences.deletedAt.isNull() &
        db.taskOccurrences.occurrenceAt.isBiggerOrEqualValue(
          startOfDayDateTime,
        ) &
        db.taskOccurrences.occurrenceAt.isSmallerOrEqualValue(
          endOfDayDateTime,
        );
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
        db.taskOccurrences.taskId.equalsExp(db.tasks.id),
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
        )
      else
        leftOuterJoin(
          db.taskTags,
          db.taskTags.taskId.equalsExp(db.tasks.id) &
              db.taskTags.deletedAt.isNull(),
        ),
    ])..where(recurringExp);

    // 查询 2: 非重复任务和分离实例
    // 构建基础条件
    var nonRecurringExp =
        db.tasks.parentId.isNull() & db.tasks.deletedAt.isNull();

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

    // 分离实例：detachedRecurrenceAt 匹配指定日期
    var detachedInstanceCondition =
        db.tasks.detachedFromTaskId.isNotNull() &
        db.tasks.detachedRecurrenceAt.isNotNull() &
        db.tasks.detachedRecurrenceAt.isBiggerOrEqualValue(
          startOfDayDateTime,
        ) &
        db.tasks.detachedRecurrenceAt.isSmallerOrEqualValue(
          endOfDayDateTime,
        );

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
        )
      else
        leftOuterJoin(
          db.taskTags,
          db.taskTags.taskId.equalsExp(db.tasks.id) &
              db.taskTags.deletedAt.isNull(),
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

  /// 获取所有今天需要执行的任务，包括今天未完成和已完成任务
  Stream<List<TaskEntity>> getAllTodayTaskEntities({
    Jiffy? day,
    String? tagId,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    final date = day ?? Jiffy.now();
    final startOfDay = date.startOf(Unit.day);
    final endOfDay = date.endOf(Unit.day);
    final startOfDayDateTime = startOfDay.toUtc().dateTime;
    final endOfDayDateTime = endOfDay.toUtc().dateTime;

    // 异步预生成实例（不阻塞 Stream）
    preGenerateTaskOccurrences(fromDate: date).ignore();

    // 查询 1: 通过 TaskOccurrences 表查询重复任务实例
    var recurringExp =
        db.tasks.parentId.isNull() &
        db.tasks.deletedAt.isNull() &
        db.tasks.recurrenceRule.isNotNull() &
        db.tasks.detachedFromTaskId.isNull() &
        db.taskOccurrences.deletedAt.isNull() &
        db.taskOccurrences.occurrenceAt.isBiggerOrEqualValue(
          startOfDayDateTime,
        ) &
        db.taskOccurrences.occurrenceAt.isSmallerOrEqualValue(
          endOfDayDateTime,
        );
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
    final recurringTasksQuery = db.select(db.tasks).join([
      innerJoin(
        db.taskOccurrences,
        db.taskOccurrences.taskId.equalsExp(db.tasks.id),
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
      ),
    ])..where(recurringExp);

    // 查询 2: 非重复任务和分离实例
    // 构建基础条件
    var nonRecurringExp =
        db.tasks.parentId.isNull() & db.tasks.deletedAt.isNull();
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

    // 分离实例：detachedRecurrenceAt 匹配指定日期
    final detachedInstanceCondition =
        db.tasks.detachedFromTaskId.isNotNull() &
        db.tasks.detachedRecurrenceAt.isNotNull() &
        db.tasks.detachedRecurrenceAt.isBiggerOrEqualValue(
          startOfDayDateTime,
        ) &
        db.tasks.detachedRecurrenceAt.isSmallerOrEqualValue(
          endOfDayDateTime,
        );

    // 组合非重复任务和分离实例的条件
    nonRecurringExp &= nonRecurringTaskCondition | detachedInstanceCondition;

    if (isCompleted != null) {
      nonRecurringExp &= isCompleted
          ? db.taskActivities.id.isNotNull()
          : db.taskActivities.id.isNull();
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
      leftOuterJoin(
        db.taskTags,
        db.taskTags.taskId.equalsExp(db.tasks.id) &
            db.taskTags.deletedAt.isNull(),
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

  /// 获取所有 inbox 中，今天的任务，包括今天未完成和已完成任务
  Stream<List<TaskEntity>> getAllInboxTodayTaskEntities({
    String? tagId,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    var exp =
        db.tasks.dueAt.isNull() &
        db.tasks.startAt.isNull() &
        db.tasks.endAt.isNull() &
        db.tasks.deletedAt.isNull();
    if (priority != null) {
      exp &= db.tasks.priority.equals(priority.name);
    }
    if (tagId != null) {
      exp &= db.taskTags.tagId.equals(tagId);
    }
    if (isCompleted != null) {
      exp &= isCompleted
          ? db.taskActivities.id.isNotNull()
          : db.taskActivities.id.isNull();
    }
    final query =
        db.select(db.tasks).join([
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
          ])
          ..where(exp)
          ..orderBy([
            OrderingTerm.asc(db.tasks.order),
            OrderingTerm.desc(db.taskActivities.completedAt),
            OrderingTerm.asc(db.tasks.createdAt),
          ]);

    return query.watch().asyncMap(buildTaskEntities);
  }

  Stream<List<TaskEntity>> getAllTodayOverdueTaskEntities({
    bool? isCompleted,
    TaskPriority? priority,
    Jiffy? day,
    String? tagId,
  }) {
    final date = day ?? Jiffy.now();
    final startOfDay = date.startOf(Unit.day);
    final startOfDayDateTime = startOfDay.toUtc().dateTime;
    var exp =
        (db.tasks.dueAt.isNotNull() &
            db.tasks.dueAt.isSmallerThanValue(startOfDayDateTime)) |
        (db.tasks.endAt.isNotNull() &
            db.tasks.endAt.isSmallerThanValue(startOfDayDateTime));
    if (priority != null) {
      exp &= db.tasks.priority.equals(priority.name);
    }
    if (tagId != null) {
      exp &= db.taskTags.tagId.equals(tagId);
    }
    if (isCompleted != null) {
      exp &= isCompleted
          ? db.taskActivities.id.isNotNull()
          : db.taskActivities.id.isNull();
    }
    final query = db.select(db.tasks).join([
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
    ])..where(exp);
    return query.watch().asyncMap(buildTaskEntities);
  }
}
