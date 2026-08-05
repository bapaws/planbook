import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:flutter_planbook/task/list/view/task_drag_to_day.dart';
import 'package:flutter_planbook/task/list/view/task_list_delete_dialog_listener.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:sliver_tools/sliver_tools.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({
    required this.tasks,
    this.onTaskPressed,
    this.onTaskCompleted,
    this.onTaskDeleted,
    this.onTaskEdited,
    this.header,
    this.onTaskDelayed,
    this.targetDay,
    this.onTaskDropped,
    this.onWillAcceptDropped,
    super.key,
  });

  final Widget? header;
  final List<TaskEntity> tasks;

  final ValueChanged<TaskEntity>? onTaskPressed;
  final ValueChanged<TaskEntity>? onTaskCompleted;
  final ValueChanged<TaskEntity>? onTaskDeleted;
  final ValueChanged<TaskEntity>? onTaskEdited;

  final ValueChanged<TaskEntity>? onTaskDelayed;

  /// 当前列表对应的日期；非 null 时支持将任务拖入/拖出以改期（天视图等）
  final Jiffy? targetDay;

  /// 当外部任务被拖放到该列表区域时回调；为 null 时不接收投放
  final ValueChanged<TaskEntity>? onTaskDropped;

  /// 列表 overlay 是否接受投放；用于拒绝「已在列表内且无实际变更」的原地松手。
  final DragTargetWillAcceptWithDetails<TaskEntity>? onWillAcceptDropped;

  @override
  Widget build(BuildContext context) {
    return TaskListDeleteDialogListener(
      child: TaskSliverList(
        tasks: tasks,
        header: header,
        onTaskPressed: onTaskPressed,
        onTaskCompleted: onTaskCompleted,
        onTaskDeleted: onTaskDeleted,
        onTaskEdited: onTaskEdited,
        onTaskDelayed: onTaskDelayed,
        targetDay: targetDay,
        onTaskDropped: onTaskDropped,
        onWillAcceptDropped: onWillAcceptDropped,
      ),
    );
  }
}

class TaskSliverList extends StatelessWidget {
  const TaskSliverList({
    required this.tasks,
    this.header,
    this.onTaskPressed,
    this.onTaskCompleted,
    this.onTaskDeleted,
    this.onTaskEdited,
    this.onTaskDelayed,
    this.targetDay,
    this.onTaskDropped,
    this.onWillAcceptDropped,
    super.key,
  });

  final Widget? header;
  final List<TaskEntity> tasks;

  final ValueChanged<TaskEntity>? onTaskPressed;
  final ValueChanged<TaskEntity>? onTaskCompleted;
  final ValueChanged<TaskEntity>? onTaskDeleted;
  final ValueChanged<TaskEntity>? onTaskEdited;
  final ValueChanged<TaskEntity>? onTaskDelayed;

  /// 当前列表对应的日期；非 null 时支持拖拽改期
  final Jiffy? targetDay;

  /// 当外部任务被拖放到该列表区域时回调；为 null 时不接收投放
  final ValueChanged<TaskEntity>? onTaskDropped;

  /// 列表 overlay 是否接受投放。
  final DragTargetWillAcceptWithDetails<TaskEntity>? onWillAcceptDropped;

  @override
  Widget build(BuildContext context) {
    final sliver = MultiSliver(
      pushPinnedChildren: true,
      children: [
        if (header != null && tasks.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(child: header),
          ),
        SliverList.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final nextTask = index < tasks.length - 1 ? tasks[index + 1] : null;
            final tile = TaskListTile(
              key: ValueKey(task),
              task: task,
              titleTextStyle: Theme.of(context).textTheme.titleMedium,
              isExpanded: nextTask?.parentId == task.id,
              onPressed: (task) {
                if (onTaskPressed != null) {
                  onTaskPressed!(task);
                } else {
                  context.router.push(
                    TaskDetailRoute(
                      taskId: task.parentId ?? task.id,
                      occurrenceAt: task.occurrence?.occurrenceAt,
                    ),
                  );
                }
              },
              onCompleted: (task) {
                if (onTaskCompleted != null) {
                  onTaskCompleted!(task);
                } else {
                  context.read<TaskListBloc>().add(
                    TaskListCompleted(task: task),
                  );
                }
              },
              onDeleted: (task) {
                if (onTaskDeleted != null) {
                  onTaskDeleted!(task);
                } else {
                  context.read<TaskListBloc>().add(
                    TaskListDeleteRequested(task: task),
                  );
                }
              },
              onEdited: (task) {
                context.router.push(TaskNewRoute(initialTask: task));
              },
              onDelayed: (task) {
                if (onTaskDelayed != null) {
                  onTaskDelayed!(task);
                } else {
                  context.read<TaskListBloc>().add(
                    TaskListTaskDelayed(task: task),
                  );
                }
              },
              onExpanded: (task) {
                context.read<TaskListBloc>().add(
                  TaskListTaskExpanded(task: task),
                );
              },
            );
            if (targetDay == null) return tile;
            return TaskDropArea(
              targetDay: targetDay,
              child: TaskDraggable(
                task: task,
                feedbackBuilder: taskListTileDragFeedbackBuilder,
                onDragCompleted: (task) => context.read<TaskListBloc>().add(
                  TaskListTaskDragCompleted(task: task),
                ),
                child: tile,
              ),
            );
          },
        ),
      ],
    );

    return SliverTaskDragTarget(
      onAccept: onTaskDropped,
      onWillAcceptWithDetails: onWillAcceptDropped,
      sliver: sliver,
    );
  }
}
