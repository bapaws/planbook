import 'package:database_planbook_api/task/database_task_delay_api.dart';
import 'package:database_planbook_api/task/database_task_update_api.dart';
import 'package:database_planbook_api/task/recurring_task_edit_mode.dart';
import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:uuid/uuid.dart';

/// 任务删除 API（Apple Calendar 风格）
///
/// 负责处理任务删除的数据库操作，支持重复任务的三种删除模式：
/// - 仅此事件：软删除该日期的 occurrence，并写入可同步的分离墓碑
/// - 此事件及将来事件：提前结束原始重复规则
/// - 所有事件：软删除整个重复序列（主任务）
class DatabaseTaskDeleteApi extends DatabaseTaskUpdateApi {
  DatabaseTaskDeleteApi({
    required super.db,
    required super.tagApi,
    required super.outboxApi,
  });

  /// 根据删除模式删除任务
  ///
  /// [entity] 要删除的任务实体
  /// [mode] 重复任务的删除模式
  /// [occurrenceAt] 重复任务的发生时间（用于标识是哪个实例被删除）
  ///
  /// 返回：thisAndFutureEvents 模式下返回更新后的主任务，用于重新调度提醒
  Future<Task?> deleteTask({
    required TaskEntity entity,
    required RecurringTaskDeleteMode mode,
    Jiffy? occurrenceAt,
  }) async {
    switch (mode) {
      case RecurringTaskDeleteMode.thisEventOnly:
        await _deleteThisEventOnly(entity, occurrenceAt);
        return null;
      case RecurringTaskDeleteMode.thisAndFutureEvents:
        return _deleteThisAndFutureEvents(entity, occurrenceAt);
      case RecurringTaskDeleteMode.allEvents:
        return deleteTaskById(entity.id);
    }
  }

  Future<void> _deleteThisEventOnly(
    TaskEntity entity,
    Jiffy? occurrenceAt,
  ) async {
    final effectiveOccurrenceAt =
        occurrenceAt ??
        entity.occurrence?.occurrenceAt ??
        entity.task.dueAt ??
        entity.task.startAt;
    if (effectiveOccurrenceAt == null) {
      throw ArgumentError('无法确定重复任务的发生时间');
    }

    final occurrenceDay = effectiveOccurrenceAt.startOf(Unit.day);
    final delayApi = DatabaseTaskDelayApi(db: db, tagApi: tagApi);

    // 本机立刻从列表消失
    await delayApi.ensureSoftDeleteOccurrence(
      taskId: entity.id,
      occurrenceAt: occurrenceDay,
      task: entity.task,
    );

    // 写入软删除的分离墓碑，经 tasks outbox 同步到其他设备
    final tombstone = delayApi
        .createDetachedInstance(
          taskId: const Uuid().v4(),
          originalTask: entity.task,
          originalOccurrenceAt: occurrenceDay,
          delayTo: occurrenceDay,
          userId: entity.task.userId,
        )
        .copyWith(
          detachedReason: const Value(DetachedReason.deleted),
          deletedAt: Value(Jiffy.now()),
          updatedAt: Value(Jiffy.now()),
        );
    await create(task: tombstone);
  }

  Future<Task> _deleteThisAndFutureEvents(
    TaskEntity entity,
    Jiffy? occurrenceAt,
  ) async {
    final originalTask = entity.task;
    final originalOccurrenceAt =
        occurrenceAt ??
        entity.occurrence?.occurrenceAt ??
        entity.task.dueAt ??
        entity.task.startAt;
    if (originalOccurrenceAt == null) {
      throw ArgumentError('无法确定重复任务的发生时间');
    }

    final newEndAt = originalOccurrenceAt.subtract(days: 1).endOf(Unit.day);
    final updatedRecurrenceRule = originalTask.recurrenceRule!.copyWith(
      recurrenceEnd: () => RecurrenceEnd.fromEndAt(newEndAt),
    );
    final updatedTask = originalTask.copyWith(
      recurrenceRule: Value(updatedRecurrenceRule),
      updatedAt: Value(Jiffy.now()),
    );

    await update(task: updatedTask);
    return updatedTask;
  }
}
