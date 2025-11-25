import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:database_planbook_api/task/recurrence_rule_calculator.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class DatabaseTaskApi {
  DatabaseTaskApi({
    required this.db,
    required this.tagApi,
  });

  final AppDatabase db;
  final DatabaseTagApi tagApi;

  Future<void> create({
    required Task task,
    List<TagEntity>? tags,
  }) async {
    await db.into(db.tasks).insert(task);
    if (tags != null) {
      for (final tag in tags) {
        await db
            .into(db.taskTags)
            .insert(
              TaskTagsCompanion.insert(
                taskId: task.id,
                tagId: tag.id,
              ),
            );
        var parent = tag.parent;
        while (parent != null) {
          await db
              .into(db.taskTags)
              .insert(
                TaskTagsCompanion.insert(
                  taskId: task.id,
                  tagId: parent.id,
                  isParent: const Value(true),
                ),
              );
          parent = parent.parent;
        }
      }
    }
  }

  Future<void> update({
    required Task task,
    List<TagEntity>? tags,
  }) async {
    await (db.update(
      db.tasks,
    )..where((t) => t.id.equals(task.id))).write(task.toCompanion(true));
    if (tags != null) {
      // 获取当前 task 的所有 tags（排除已删除的）
      final currentTaskTags =
          await (db.select(
                db.taskTags,
              )..where(
                (tt) => tt.taskId.equals(task.id) & tt.deletedAt.isNull(),
              ))
              .get();
      final currentTagIds = currentTaskTags
          .map((tt) => tt.tagId)
          .whereType<String>()
          .toSet();
      final newTagIds = tags.map((tag) => tag.id).toSet();

      // 找出需要添加的 tags（新 tags 中有，旧 tags 中没有）
      final tagsToAdd = newTagIds.difference(currentTagIds);
      for (final tagId in tagsToAdd) {
        await db
            .into(db.taskTags)
            .insert(
              TaskTagsCompanion.insert(
                taskId: task.id,
                tagId: tagId,
              ),
            );
      }

      // 找出需要删除的 tags（旧 tags 中有，新 tags 中没有）
      // 使用软删除：设置 deletedAt 字段
      final tagsToDelete = currentTagIds.difference(newTagIds);
      if (tagsToDelete.isNotEmpty) {
        await (db.update(db.taskTags)..where(
              (tt) =>
                  tt.taskId.equals(task.id) &
                  tt.tagId.isIn(tagsToDelete) &
                  tt.deletedAt.isNull(),
            ))
            .write(
              TaskTagsCompanion(
                deletedAt: Value(Jiffy.now()),
              ),
            );
      }
    }
  }

  Future<Task?> getTaskById(String taskId) async {
    return (db.select(db.tasks)
          ..where((t) => t.id.equals(taskId) & t.deletedAt.isNull()))
        .getSingleOrNull();
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
        // 由于需要获取 tag 的 parent，所以无法使用 join
        final taskTags =
            await ((db.select(db.taskTags))..where(
                  (t) =>
                      t.taskId.equals(task.id) &
                      t.isParent.equals(false) &
                      t.deletedAt.isNull(),
                ))
                .get();
        final tags = await Future.wait(
          taskTags.map((t) => tagApi.getTagEntityById(t.tagId)),
        );
        tasks[task.id] = TaskEntity(
          task: task,
          activity: row.readTableOrNull(db.taskActivities),
          tags: tags.nonNulls.cast<TagEntity>().toList(),
        );
      }
    }

    return tasks.values.toList();
  }

  Future<void> deleteTaskById(String taskId) async {
    if (kDebugMode) {
      await (db.delete(db.tasks)..where(
            (t) => t.id.equals(taskId),
          ))
          .go();
    } else {
      await (db.update(db.tasks)..where(
            (t) => t.id.equals(taskId) & t.deletedAt.isNull(),
          ))
          .write(
            TasksCompanion(
              deletedAt: Value(Jiffy.now()),
            ),
          );
    }
  }
}
