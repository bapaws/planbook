import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class DatabaseTaskInboxApi extends DatabaseTaskApi {
  DatabaseTaskInboxApi({
    required super.db,
    required super.tagApi,
  });

  /// 获取指定日期内的 inbox 任务数量
  Stream<int> getInboxTaskCount({
    Jiffy? date,
    bool? isCompleted,
    String? userId,
    TaskPriority? priority,
  }) {
    var exp =
        db.tasks.parentId.isNull() &
        db.tasks.dueAt.isNull() &
        db.tasks.startAt.isNull() &
        db.tasks.endAt.isNull() &
        db.tasks.deletedAt.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));
    if (date != null) {
      exp &= db.tasks.createdAt.isSmallerOrEqualValue(
        date.endOf(Unit.day).dateTime,
      );
    }
    if (isCompleted != null) {
      exp &= isCompleted
          ? db.taskActivities.id.isNotNull()
          : db.taskActivities.id.isNull();
    }

    if (priority != null) {
      exp &= db.tasks.priority.equals(priority.name);
    }

    final query = db.selectOnly(db.tasks, distinct: true)
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
      ..where(exp);

    return query.watch().map(
      (rows) => rows.isEmpty ? 0 : rows.first.read(db.tasks.id.count()) ?? 0,
    );
  }

  Stream<List<TaskEntity>> getInboxTaskEntities({
    String? tagId,
    TaskPriority? priority,
    bool? isCompleted,
    String? userId,
  }) {
    var exp =
        db.tasks.parentId.isNull() &
        db.tasks.dueAt.isNull() &
        db.tasks.startAt.isNull() &
        db.tasks.endAt.isNull() &
        db.tasks.deletedAt.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));
    if (isCompleted != null) {
      exp &= isCompleted
          ? db.taskActivities.id.isNotNull()
          : db.taskActivities.id.isNull();
    }
    // 当 tagId 为 null 时，在 where 条件中筛选没有 tag 的任务
    if (tagId == null) {
      exp &= db.taskTags.id.isNull();
    }

    if (priority != null) {
      exp &= db.tasks.priority.equals(priority.name);
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
            // 当 tagId 为 null 时，使用 leftOuterJoin 来筛选没有 tag 的任务
            // 当 tagId 不为 null 时，使用 innerJoin 来筛选有该 tag 的任务
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
          ])
          ..where(exp)
          ..orderBy([
            OrderingTerm.asc(db.tasks.order),
            OrderingTerm.asc(db.tasks.createdAt.datetime),
            OrderingTerm.desc(db.taskActivities.completedAt.datetime),
          ]);

    return query.watch().asyncMap(buildTaskEntities);
  }

  /// 获取所有 inbox 中，今天的任务，包括今天未完成和已完成任务
  Stream<List<TaskEntity>> getAllInboxTodayTaskEntities({
    String? tagId,
    TaskPriority? priority,
    bool? isCompleted,
    String? userId,
  }) {
    var exp =
        db.tasks.parentId.isNull() &
        db.tasks.dueAt.isNull() &
        db.tasks.startAt.isNull() &
        db.tasks.endAt.isNull() &
        db.tasks.deletedAt.isNull() &
        (userId == null
            ? db.tasks.userId.isNull()
            : db.tasks.userId.equals(userId));
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
}
