import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:uuid/uuid.dart';

/// 任务延迟 API（Apple Calendar 风格）
///
/// 负责处理任务延迟的数据库操作：
/// - 非重复任务：直接修改 dueAt/startAt/endAt 时间
/// - 重复任务：创建分离实例（仅延迟这一个实例）
///
/// 注意：延迟任务只处理单个实例。如果需要修改整个重复序列，
/// 应该使用"编辑任务"功能，并让用户选择修改模式。
class DatabaseTaskDelayApi {
  DatabaseTaskDelayApi({
    required this.db,
    required this.tagApi,
  });

  final AppDatabase db;
  final DatabaseTagApi tagApi;

  /// 准备延迟任务的数据（不保存到数据库）
  ///
  /// 对于非重复任务：计算延迟后的时间
  /// 对于重复任务：创建分离实例数据
  ///
  /// [entity] 要延迟的任务实体
  /// [delayTo] 延迟到的目标时间
  /// [userId] 用户 ID
  ///
  /// 返回：延迟任务的结果（包含任务数据和标签，但未保存到数据库）
  Task prepareDelayTask({
    required TaskEntity entity,
    required Jiffy delayTo,
    String? userId,
  }) {
    final task = entity.task;
    final isRecurring = task.recurrenceRule != null;

    if (!isRecurring) {
      // 非重复任务：直接修改时间
      final updatedTask = calculateDelayedTask(task, delayTo);
      return updatedTask.copyWith(
        userId: Value(userId),
        updatedAt: Value(Jiffy.now()),
      );
    }

    // 重复任务：创建分离实例（仅延迟这一个实例）
    final originalOccurrenceAt =
        entity.occurrence?.occurrenceAt ?? task.dueAt ?? task.startAt;

    if (originalOccurrenceAt == null) {
      throw ArgumentError('无法确定重复任务的发生时间');
    }

    return createDetachedInstance(
      originalTask: task,
      originalOccurrenceAt: originalOccurrenceAt,
      delayTo: delayTo,
      userId: userId,
    );
  }

  /// 计算延迟后的任务时间
  ///
  /// 根据延迟目标时间计算新的 startAt、endAt、dueAt，
  /// 保持时间部分不变，只调整日期。
  Task calculateDelayedTask(Task task, Jiffy delayTo) {
    // 计算时间偏移量（天数）
    final referenceTime = task.dueAt ?? task.startAt ?? Jiffy.now().toUtc();
    final daysDiff = delayTo
        .toUtc()
        .startOf(Unit.day)
        .diff(
          referenceTime.startOf(Unit.day),
          unit: Unit.day,
        )
        .toInt();

    Jiffy? newStartAt;
    Jiffy? newEndAt;
    Jiffy? newDueAt;

    if (task.startAt != null) {
      newStartAt = task.startAt!.clone();
    }
    if (task.endAt != null) {
      newEndAt = task.endAt!.add(days: daysDiff);
    }
    if (task.dueAt != null) {
      newDueAt = task.dueAt!.add(days: daysDiff);
    }

    return task.copyWith(
      startAt: Value(newStartAt),
      endAt: Value(newEndAt),
      dueAt: Value(newDueAt),
    );
  }

  /// 创建分离实例（Apple Calendar 风格）
  ///
  /// 当用户延迟重复任务的某个实例时，创建一个独立的分离实例。
  /// 分离实例会替代原始重复任务在该日期的显示。
  ///
  /// [originalTask] 原始重复任务
  /// [originalOccurrenceAt] 原始发生日期
  /// [delayTo] 延迟到的目标时间
  /// [userId] 用户 ID
  Task createDetachedInstance({
    required Task originalTask,
    required Jiffy originalOccurrenceAt,
    required Jiffy delayTo,
    String? userId,
  }) {
    // 计算时间偏移量（从原始发生日期到延迟目标日期）
    final daysDiff = delayTo
        .startOf(Unit.day)
        .diff(
          originalOccurrenceAt.startOf(Unit.day),
          unit: Unit.day,
        )
        .toInt();

    Jiffy? newStartAt;
    Jiffy? newEndAt;
    Jiffy? newDueAt;

    if (originalTask.startAt != null) {
      // 先计算原始实例的 startAt（相对于任务创建时间的偏移）
      final originalTaskStart = originalTask.startAt!;
      final originalDaysDiff = originalOccurrenceAt
          .startOf(Unit.day)
          .diff(
            originalTaskStart.startOf(Unit.day),
            unit: Unit.day,
          )
          .toInt();
      final instanceStartAt = originalTaskStart.add(days: originalDaysDiff);
      newStartAt = instanceStartAt.add(days: daysDiff);
    }

    if (originalTask.endAt != null) {
      final originalTaskEnd = originalTask.endAt!;
      final referenceTime =
          originalTask.startAt ?? originalTask.dueAt ?? originalTaskEnd;
      final originalDaysDiff = originalOccurrenceAt
          .startOf(Unit.day)
          .diff(
            referenceTime.startOf(Unit.day),
            unit: Unit.day,
          )
          .toInt();
      final instanceEndAt = originalTaskEnd.add(days: originalDaysDiff);
      newEndAt = instanceEndAt.add(days: daysDiff);
    }

    if (originalTask.dueAt != null) {
      final originalTaskDue = originalTask.dueAt!;
      final originalDaysDiff = originalOccurrenceAt
          .startOf(Unit.day)
          .diff(
            originalTaskDue.startOf(Unit.day),
            unit: Unit.day,
          )
          .toInt();
      final instanceDueAt = originalTaskDue.add(days: originalDaysDiff);
      newDueAt = instanceDueAt.add(days: daysDiff);
    }

    return Task(
      id: const Uuid().v4(),
      userId: userId,
      title: originalTask.title,
      parentId: originalTask.parentId,
      layer: originalTask.layer,
      childCount: 0, // 分离实例不继承子任务
      order: originalTask.order,
      startAt: newStartAt,
      endAt: newEndAt,
      isAllDay: originalTask.isAllDay,
      dueAt: newDueAt,
      // 分离实例不重复
      detachedFromTaskId: originalTask.id,
      detachedRecurrenceAt: originalOccurrenceAt.startOf(Unit.day),
      detachedReason: DetachedReason.modified,
      alarms: originalTask.alarms,
      priority: originalTask.priority,
      location: originalTask.location,
      notes: originalTask.notes,
      timeZone: originalTask.timeZone,
      createdAt: Jiffy.now(),
    );
  }
}
