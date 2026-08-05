import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_operation.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/task_entity.dart';

/// 可接收拖拽任务的“日期格子”区域，用于周/月/天视图
///
/// 当 [targetDay] 非 null 时，将 [child] 包在 [TaskDragTarget] 内，
/// 有任务拖入且目标日期与任务当前日期不同时调用 [moveTaskToDay]。
///
/// 同日投放在 willAccept 阶段拒绝，避免标记为 move
/// 后触发源列表乐观移除（长按未移动就释放时的消失问题）。
class TaskDropArea extends StatelessWidget {
  const TaskDropArea({
    required this.child,
    this.targetDay,
    super.key,
  });

  final Widget child;

  /// 此区域对应的日期；为 null 时不作为投放目标
  final Jiffy? targetDay;

  @override
  Widget build(BuildContext context) {
    final day = targetDay;
    return TaskDragTarget(
      onWillAcceptWithDetails: day == null
          ? null
          : (details) => TaskDropArea.wouldMoveToDay(details.data, day),
      onAccept: day == null
          ? null
          : (task) => TaskDropArea.moveTaskToDay(context, task, day),
      child: child,
    );
  }

  /// 任务拖到 [targetDay] 是否会产生实际改期。
  ///
  /// 同日返回 false，供 willAccept 拒绝无效投放。
  static bool wouldMoveToDay(TaskEntity task, Jiffy targetDay) {
    final taskDay = (task.occurrenceAt ?? task.startAt ?? task.dueAt)?.startOf(
      Unit.day,
    );
    final targetDayStart = targetDay.startOf(Unit.day);
    if (taskDay != null && taskDay.isSame(targetDayStart, unit: Unit.day)) {
      return false;
    }
    return true;
  }

  /// 派发事件将任务移动到指定日期（拖到其他天时调用）
  ///
  /// 若任务当前日期与 [targetDay] 相同则忽略；
  /// 否则向 TaskListBloc 派发 TaskListTaskDelayed（带 targetDay），由 bloc 调用仓库更新。
  static void moveTaskToDay(
    BuildContext context,
    TaskEntity task,
    Jiffy targetDay,
  ) {
    if (!wouldMoveToDay(task, targetDay)) {
      return;
    }
    context.read<TaskListBloc>().add(
      TaskListTaskDelayed(
        task: task,
        delayTo: targetDay.startOf(Unit.day),
      ),
    );
  }
}

/// 默认拖拽时的反馈样式（标题 + 图标）
Widget defaultDragFeedbackBuilder(
  BuildContext context,
  TaskEntity task,
  ColorScheme colorScheme,
) {
  return Material(
    elevation: 4,
    borderRadius: BorderRadius.circular(8),
    color: colorScheme.surface,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.square_list,
            size: 18,
            color: colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            task.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
}

/// 日/逾期列表拖拽反馈：半宽任务行 + 绿色加号
Widget taskListTileDragFeedbackBuilder(
  BuildContext context,
  TaskEntity task,
) {
  final theme = Theme.of(context);
  return Material(
    elevation: 4,
    borderRadius: BorderRadius.circular(8),
    color: theme.colorScheme.surfaceContainerLowest,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width / 2,
          height: kMinInteractiveDimension,
          child: TaskListTile(
            task: task,
            titleTextStyle: theme.textTheme.titleMedium,
          ),
        ),
        const Positioned(
          top: -8,
          right: -8,
          child: Icon(
            FontAwesomeIcons.circlePlus,
            size: 18,
            color: Colors.green,
          ),
        ),
      ],
    ),
  );
}

/// 可拖拽的任务项包装器，用于周/月/天视图中的每个任务
///
/// 将 [child] 包在 Draggable 内，data 为 [task]；
/// [feedbackBuilder] 为 null 时使用 defaultDragFeedbackBuilder。
///
/// 当拖拽被 [TaskDragTarget] 接受且目标操作类型为 [TaskDragOperation.move] 时，
/// 会调用 [onDragCompleted]，通常用于向源 BLoC 派发乐观移除事件。
class TaskDraggable extends StatelessWidget {
  const TaskDraggable({
    required this.task,
    required this.child,
    this.feedbackBuilder,
    this.onDragCompleted,
    this.childWhenDraggingOpacity = 0.5,
    super.key,
  });

  final TaskEntity task;
  final Widget child;

  /// 拖拽时显示的反馈组件；为 null 时用 [defaultDragFeedbackBuilder]
  final Widget Function(BuildContext context, TaskEntity task)? feedbackBuilder;

  /// 拖拽被接受（move 操作）后的回调，用于同步更新源列表。
  final ValueChanged<TaskEntity>? onDragCompleted;

  /// 拖拽过程中原位的透明度，默认 0.5
  final double childWhenDraggingOpacity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedback =
        feedbackBuilder?.call(context, task) ??
        defaultDragFeedbackBuilder(context, task, colorScheme);
    return LongPressDraggable<TaskEntity>(
      data: task,
      feedback: feedback,
      childWhenDragging: Opacity(
        opacity: childWhenDraggingOpacity,
        child: child,
      ),
      onDragCompleted: () {
        final operation = TaskDragOperationNotifier.instance.take();
        if (operation == TaskDragOperation.move) {
          onDragCompleted?.call(task);
        }
      },
      child: child,
    );
  }
}
