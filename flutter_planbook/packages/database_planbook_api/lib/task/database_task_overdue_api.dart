import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class DatabaseTaskOverdueApi extends DatabaseTaskApi {
  DatabaseTaskOverdueApi({
    required super.db,
    required super.tagApi,
  });

  Stream<int> getOverdueTaskCount({required Jiffy date}) {
    final startOfDay = date.startOf(Unit.day).toUtc().dateTime;
    final exp =
        ((db.tasks.dueAt.isNotNull() &
                db.tasks.dueAt.isSmallerThanValue(startOfDay)) |
            (db.tasks.endAt.isNotNull() &
                db.tasks.endAt.isSmallerThanValue(startOfDay))) &
        db.tasks.deletedAt.isNull() &
        // 未完成任务：不存在对应的 taskActivity
        db.taskActivities.id.isNull();

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

  Stream<List<TaskEntity>> getOverdueTaskEntities({
    required Jiffy date,
    TaskPriority? priority,
    String? tagId,
  }) {
    final startOfDay = date.startOf(Unit.day).toUtc().dateTime;
    var exp =
        ((db.tasks.dueAt.isNotNull() &
                db.tasks.dueAt.isSmallerThanValue(startOfDay)) |
            (db.tasks.endAt.isNotNull() &
                db.tasks.endAt.isSmallerThanValue(startOfDay))) &
        db.tasks.deletedAt.isNull();
    // 只查询未完成的任务：taskActivities.id 为 null 表示未完成
    exp &= db.taskActivities.id.isNull();
    if (tagId != null) {
      exp &= db.taskTags.tagId.equals(tagId) & db.taskTags.deletedAt.isNull();
    } else {
      exp &= db.taskTags.id.isNull() & db.taskTags.deletedAt.isNull();
    }
    if (priority != null) {
      exp &= db.tasks.priority.equals(priority.name);
    }

    final query = db.select(db.tasks).join([
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
    ])..where(exp);
    return query.watch().asyncMap(buildTaskEntities);
  }
}
