import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:uuid/uuid.dart';

/// 延迟任务的结果
class DelayTaskResult {
  const DelayTaskResult({
    required this.task,
    this.children,
    this.isNewTask = false,
    this.originalTaskId,
    this.originalOccurrenceAt,
  });

  /// 延迟后的任务
  final Task task;

  /// 延迟后的子任务列表
  final List<Task>? children;

  /// 是否是新创建的任务（分离实例）
  final bool isNewTask;

  /// 原始任务 ID（仅用于重复任务分离实例，需要将该日期的 occurrence 标记为 deleted）
  final String? originalTaskId;

  /// 原始发生日期（仅用于重复任务分离实例，需要将该日期的 occurrence 标记为 deleted）
  final Jiffy? originalOccurrenceAt;
}

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

  /// 将指定日期的 TaskOccurrence 标记为已删除
  ///
  /// 当创建分离实例后，需要调用此方法将原始任务在该日期的 occurrence 标记为 deleted，
  /// 避免原始任务和分离实例同时显示。
  Future<void> softDeleteOccurrence({
    required String taskId,
    required Jiffy occurrenceAt,
  }) async {
    final startOfDay = occurrenceAt.startOf(Unit.day).dateTime;
    final endOfDay = occurrenceAt.endOf(Unit.day).dateTime;

    await (db.update(db.taskOccurrences)..where(
          (to) =>
              to.taskId.equals(taskId) &
              to.occurrenceAt.isBiggerOrEqualValue(startOfDay) &
              to.occurrenceAt.isSmallerOrEqualValue(endOfDay) &
              to.deletedAt.isNull(),
        ))
        .write(
          TaskOccurrencesCompanion(
            deletedAt: Value(Jiffy.now()),
          ),
        );
  }

  /// 准备延迟任务的数据（不保存到数据库）
  ///
  /// 对于非重复任务：计算延迟后的时间
  /// 对于重复任务：创建分离实例数据
  ///
  /// [entity] 要延迟的任务实体
  /// [delayTo] 延迟到的目标时间
  /// [userId] 用户 ID
  ///
  /// 返回：延迟任务的结果（包含任务数据和子任务，但未保存到数据库）
  DelayTaskResult prepareDelayTask({
    required TaskEntity entity,
    required Jiffy delayTo,
    String? userId,
  }) {
    final task = entity.task;
    final isRecurring = task.recurrenceRule != null;

    if (!isRecurring) {
      // 非重复任务：直接修改时间
      final updatedTask = calculateDelayedTask(task, delayTo).copyWith(
        userId: Value(userId),
        updatedAt: Value(Jiffy.now()),
      );

      // 处理子任务：子任务也需要同步延迟
      final delayedChildren = _delayChildren(
        children: entity.children,
        parentTask: task,
        delayTo: delayTo,
        userId: userId,
      );

      return DelayTaskResult(
        task: updatedTask,
        children: delayedChildren,
      );
    }

    // 重复任务：创建分离实例（仅延迟这一个实例）
    final originalOccurrenceAt =
        entity.occurrence?.occurrenceAt ?? task.dueAt ?? task.startAt;

    if (originalOccurrenceAt == null) {
      throw ArgumentError('无法确定重复任务的发生时间');
    }

    final detachedTaskId = const Uuid().v4();

    // 重复任务的分离实例：为子任务生成新 ID 并关联到新的分离实例
    final detachedChildren = _copyChildrenForDetach(
      children: entity.children,
      newParentId: detachedTaskId,
      userId: userId,
    );

    final detachedTask = createDetachedInstance(
      taskId: detachedTaskId,
      originalTask: task,
      originalOccurrenceAt: originalOccurrenceAt,
      delayTo: delayTo,
      userId: userId,
      childCount: detachedChildren?.length ?? 0,
    );

    return DelayTaskResult(
      task: detachedTask,
      children: detachedChildren,
      isNewTask: true,
      originalTaskId: task.id,
      originalOccurrenceAt: originalOccurrenceAt,
    );
  }

  /// 延迟子任务（保持原 ID，更新时间）
  List<Task>? _delayChildren({
    required List<TaskEntity> children,
    required Task parentTask,
    required Jiffy delayTo,
    String? userId,
  }) {
    if (children.isEmpty) return null;

    return children.map((child) {
      final delayedChild = calculateDelayedTask(child.task, delayTo);
      return delayedChild.copyWith(
        userId: Value(userId),
        updatedAt: Value(Jiffy.now()),
      );
    }).toList();
  }

  /// 复制子任务用于分离实例（生成新 ID）
  List<Task>? _copyChildrenForDetach({
    required List<TaskEntity> children,
    required String newParentId,
    String? userId,
  }) {
    if (children.isEmpty) return null;

    final now = Jiffy.now();
    return children
        .map(
          (child) => Task(
            id: const Uuid().v4(),
            userId: userId,
            title: child.title,
            parentId: newParentId,
            layer: child.layer,
            childCount: child.childCount,
            order: child.order,
            startAt: child.startAt,
            endAt: child.endAt,
            isAllDay: child.isAllDay,
            dueAt: child.dueAt,
            alarms: child.alarms,
            priority: child.priority,
            location: child.task.location,
            notes: child.task.notes,
            timeZone: child.task.timeZone,
            createdAt: now,
          ),
        )
        .toList();
  }

  /// 计算延迟后的任务时间
  ///
  /// 根据延迟目标时间计算新的 startAt、endAt、dueAt，
  /// 保持时间部分不变，只调整日期。
  Task calculateDelayedTask(Task task, Jiffy delayTo) {
    // 计算时间偏移量（天数）
    final referenceTime = task.dueAt ?? task.startAt ?? Jiffy.now();
    final daysDiff = delayTo
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
      newStartAt = task.startAt;
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
  /// [taskId] 分离实例的 ID
  /// [originalTask] 原始重复任务
  /// [originalOccurrenceAt] 原始发生日期
  /// [delayTo] 延迟到的目标时间
  /// [userId] 用户 ID
  /// [childCount] 子任务数量
  Task createDetachedInstance({
    required String taskId,
    required Task originalTask,
    required Jiffy originalOccurrenceAt,
    required Jiffy delayTo,
    String? userId,
    int childCount = 0,
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
      id: taskId,
      userId: userId,
      title: originalTask.title,
      parentId: originalTask.parentId,
      layer: originalTask.layer,
      childCount: childCount,
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
