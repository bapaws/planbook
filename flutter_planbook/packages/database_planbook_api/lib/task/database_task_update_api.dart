import 'dart:async';

import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:database_planbook_api/task/recurring_task_edit_mode.dart';
import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:uuid/uuid.dart';

/// 更新任务的结果
class UpdateTaskResult {
  const UpdateTaskResult({
    required this.updatedTask,
    required this.taskTags,
    this.originalTaskUpdated,
    this.originalTaskTags,
    this.children,
    this.isNewTask = false,
  });

  /// 更新后的任务（可能是原任务、分离实例或新的重复任务）
  final Task updatedTask;

  /// 更新后任务的标签
  final List<TaskTag> taskTags;

  /// 原始任务是否被更新（仅用于 thisAndFutureEvents 模式）
  final Task? originalTaskUpdated;

  /// 原始任务的标签（仅用于 thisAndFutureEvents 模式）
  final List<TaskTag>? originalTaskTags;

  /// 子任务列表
  final List<Task>? children;

  /// 是否是新创建的任务
  final bool isNewTask;
}

/// 任务更新 API（Apple Calendar 风格）
///
/// 负责处理任务更新的数据库操作，支持重复任务的三种修改模式：
/// - 仅此事件：创建分离实例
/// - 此事件及将来事件：分裂重复序列
/// - 所有事件：修改整个重复序列
class DatabaseTaskUpdateApi extends DatabaseTaskApi {
  DatabaseTaskUpdateApi({
    required super.db,
    required super.tagApi,
  });

  /// 检查任务是否有分离实例
  ///
  /// 如果一个重复任务没有任何分离实例（从未被修改、完成或跳过），
  /// 则可以直接更新整个任务，无需考虑编辑模式。
  Future<bool> hasDetachedInstances(String taskId) async {
    final query = db.select(db.tasks)
      ..where(
        (t) => t.detachedFromTaskId.equals(taskId) & t.deletedAt.isNull(),
      )
      ..limit(1);
    final result = await query.get();
    return result.isNotEmpty;
  }

  /// 准备更新任务的数据（不保存到数据库）
  ///
  /// [entity] 原始任务实体
  /// [updatedTask] 更新后的任务数据
  /// [tags] 任务标签
  /// [children] 子任务列表
  /// [occurrenceAt] 重复任务的发生时间（用于标识是哪个实例被修改）
  /// [userId] 用户 ID
  /// [editMode] 重复任务的修改模式
  ///
  /// 返回：更新任务的结果（包含任务数据和标签，但未保存到数据库）
  UpdateTaskResult prepareUpdate({
    required TaskEntity entity,
    required Task updatedTask,
    required List<TagEntity>? tags,
    List<TaskEntity>? children,
    Jiffy? occurrenceAt,
    String? userId,
    RecurringTaskEditMode editMode = RecurringTaskEditMode.allEvents,
  }) {
    final isRecurring = entity.task.recurrenceRule != null;

    // 处理子任务：设置 userId 和 parentId
    final processedChildren = children
        ?.map(
          (e) => e.task.copyWith(
            userId: Value(userId),
            parentId: Value(updatedTask.id),
            layer: updatedTask.layer + 1,
          ),
        )
        .toList();

    // 非重复任务或"所有事件"模式：直接更新
    if (!isRecurring || editMode == RecurringTaskEditMode.allEvents) {
      final taskWithUser = updatedTask.copyWith(
        userId: Value(userId),
        updatedAt: Value(Jiffy.now()),
        childCount: children?.length ?? 0,
      );
      final taskTags = generateTaskTags(
        task: taskWithUser,
        tags: tags,
        userId: userId,
      );
      return UpdateTaskResult(
        updatedTask: taskWithUser,
        taskTags: taskTags,
        children: processedChildren,
      );
    }

    // 获取原始发生时间
    final originalOccurrenceAt =
        occurrenceAt ??
        entity.occurrence?.occurrenceAt ??
        entity.task.dueAt ??
        entity.task.startAt;

    if (originalOccurrenceAt == null) {
      throw ArgumentError('无法确定重复任务的发生时间');
    }

    // 对于分离模式，子任务需要生成新 ID（无论是用户传入的还是原始的）
    // 因为分离实例是全新的任务，子任务也应该是全新的
    final sourceChildren = children ?? entity.children;
    final childrenForDetach = _copyChildrenForDetach(sourceChildren, userId);

    switch (editMode) {
      case RecurringTaskEditMode.thisEventOnly:
        return _prepareThisEventOnly(
          entity: entity,
          updatedTask: updatedTask,
          tags: tags,
          children: childrenForDetach,
          originalOccurrenceAt: originalOccurrenceAt,
          userId: userId,
        );

      case RecurringTaskEditMode.thisAndFutureEvents:
        return _prepareThisAndFutureEvents(
          entity: entity,
          updatedTask: updatedTask,
          tags: tags,
          children: childrenForDetach,
          originalOccurrenceAt: originalOccurrenceAt,
          userId: userId,
        );

      case RecurringTaskEditMode.allEvents:
        // 已在上面处理，这里不会执行
        throw StateError('不应该执行到这里');
    }
  }

  /// 复制子任务用于分离实例（生成新 ID）
  List<Task>? _copyChildrenForDetach(
    List<TaskEntity> originalChildren,
    String? userId,
  ) {
    if (originalChildren.isEmpty) return null;

    final now = Jiffy.now();
    return originalChildren
        .map(
          (child) => Task(
            id: const Uuid().v4(),
            userId: userId,
            title: child.title,
            parentId: child.parentId, // 会在后续更新为新的 parentId
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

  /// 仅此事件：创建分离实例
  UpdateTaskResult _prepareThisEventOnly({
    required TaskEntity entity,
    required Task updatedTask,
    required List<TagEntity>? tags,
    required Jiffy originalOccurrenceAt,
    List<Task>? children,
    String? userId,
  }) {
    final detachedTaskId = const Uuid().v4();

    // 创建分离实例，使用更新后的数据
    final detachedTask = Task(
      id: detachedTaskId,
      userId: userId,
      title: updatedTask.title,
      parentId: updatedTask.parentId,
      layer: updatedTask.layer,
      childCount: children?.length ?? 0,
      order: updatedTask.order,
      startAt: updatedTask.startAt,
      endAt: updatedTask.endAt,
      isAllDay: updatedTask.isAllDay,
      dueAt: updatedTask.dueAt,
      // 分离实例不重复
      detachedFromTaskId: entity.task.id,
      detachedRecurrenceAt: originalOccurrenceAt.startOf(Unit.day),
      detachedReason: DetachedReason.modified,
      alarms: updatedTask.alarms,
      priority: updatedTask.priority,
      location: updatedTask.location,
      notes: updatedTask.notes,
      timeZone: updatedTask.timeZone,
      createdAt: Jiffy.now(),
    );

    // 更新 children 的 parentId 为新的分离实例 ID
    final updatedChildren = children
        ?.map(
          (e) => e.copyWith(
            parentId: Value(detachedTaskId),
            layer: updatedTask.layer + 1,
          ),
        )
        .toList();

    final taskTags = generateTaskTags(
      task: detachedTask,
      tags: tags,
      userId: userId,
    );

    return UpdateTaskResult(
      updatedTask: detachedTask,
      taskTags: taskTags,
      children: updatedChildren,
      isNewTask: true,
    );
  }

  /// 此事件及将来事件：分裂重复序列
  UpdateTaskResult _prepareThisAndFutureEvents({
    required TaskEntity entity,
    required Task updatedTask,
    required List<TagEntity>? tags,
    required Jiffy originalOccurrenceAt,
    List<Task>? children,
    String? userId,
  }) {
    final originalTask = entity.task;
    final recurrenceRule = originalTask.recurrenceRule!;
    final newTaskId = const Uuid().v4();

    // 1. 计算原始任务的新结束日期（分离日期的前一天）
    final newEndAt = originalOccurrenceAt.subtract(days: 1).endOf(Unit.day);

    // 更新原始任务的重复规则，设置结束日期
    final updatedRecurrenceRule = recurrenceRule.copyWith(
      recurrenceEnd: () => RecurrenceEnd.fromEndAt(newEndAt),
    );

    final updatedOriginalTask = originalTask.copyWith(
      recurrenceRule: Value(updatedRecurrenceRule),
      updatedAt: Value(Jiffy.now()),
    );

    final originalTaskTags = generateTaskTags(
      task: updatedOriginalTask,
      tags: entity.tags,
      userId: userId,
    );

    // 2. 创建新的重复任务，使用更新后的数据
    final newTask = Task(
      id: newTaskId,
      userId: userId,
      title: updatedTask.title,
      parentId: updatedTask.parentId,
      layer: updatedTask.layer,
      childCount: children?.length ?? 0,
      order: updatedTask.order,
      startAt: updatedTask.startAt,
      endAt: updatedTask.endAt,
      isAllDay: updatedTask.isAllDay,
      dueAt: updatedTask.dueAt,
      recurrenceRule: updatedTask.recurrenceRule, // 新任务继承更新后的重复规则
      // 不设置 detachedFromTaskId，因为这是新的重复序列
      alarms: updatedTask.alarms,
      priority: updatedTask.priority,
      location: updatedTask.location,
      notes: updatedTask.notes,
      timeZone: updatedTask.timeZone,
      createdAt: Jiffy.now(),
    );

    // 更新 children 的 parentId 为新任务 ID
    final updatedChildren = children
        ?.map(
          (e) => e.copyWith(
            parentId: Value(newTaskId),
            layer: updatedTask.layer + 1,
          ),
        )
        .toList();

    final newTaskTags = generateTaskTags(
      task: newTask,
      tags: tags,
      userId: userId,
    );

    return UpdateTaskResult(
      updatedTask: newTask,
      taskTags: newTaskTags,
      children: updatedChildren,
      originalTaskUpdated: updatedOriginalTask,
      originalTaskTags: originalTaskTags,
      isNewTask: true,
    );
  }

  /// 保存更新结果到本地数据库
  Future<void> saveUpdateResult(UpdateTaskResult result) async {
    // 如果原始任务被更新（thisAndFutureEvents 模式）
    if (result.originalTaskUpdated != null) {
      await update(
        task: result.originalTaskUpdated!,
        taskTags: result.originalTaskTags ?? [],
      );
    }

    if (result.isNewTask) {
      // 创建新任务（分离实例或新的重复序列）
      await create(
        task: result.updatedTask,
        taskTags: result.taskTags,
        children: result.children,
      );
    } else {
      // 更新现有任务
      await update(
        task: result.updatedTask,
        taskTags: result.taskTags,
        children: result.children,
      );
    }
  }

  /// 更新任务到数据库
  ///
  /// 如果任务的重复规则或时间发生变化，会重新生成 TaskOccurrences
  Future<void> update({
    required Task task,
    required List<TaskTag> taskTags,
    List<Task>? children,
  }) async {
    final existingTask = await getTaskById(task.id);

    await db.transaction(() async {
      await (db.update(
        db.tasks,
      )..where((t) => t.id.equals(task.id))).write(task.toCompanion(false));
      await (db.delete(
        db.taskTags,
      )..where((tt) => tt.taskId.equals(task.id))).go();
      for (final taskTag in taskTags) {
        await db.into(db.taskTags).insert(taskTag);
      }
      // 处理子任务
      if (children != null && children.isNotEmpty) {
        for (final child in children) {
          await db.into(db.tasks).insertOnConflictUpdate(child);
        }
      }
    });

    if (existingTask == null) return;
    final recurrenceChanged =
        existingTask.recurrenceRule != task.recurrenceRule ||
        existingTask.startAt != task.startAt ||
        existingTask.endAt != task.endAt ||
        existingTask.dueAt != task.dueAt;

    if (!recurrenceChanged) return;
    await (db.delete(db.taskOccurrences)..where(
          (to) => to.taskId.equals(task.id),
        ))
        .go();
    unawaited(
      preGenerateTaskOccurrences(
        fromDate: task.startAt ?? task.dueAt ?? Jiffy.now(),
      ),
    );
  }
}
