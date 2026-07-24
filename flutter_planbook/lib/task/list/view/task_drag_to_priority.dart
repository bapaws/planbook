import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:planbook_api/planbook_api.dart';

/// 可接收拖拽任务的“优先级格子”区域，用于四象限视图
class TaskPriorityDropArea extends StatelessWidget {
  const TaskPriorityDropArea({
    required this.child,
    this.targetPriority,
    super.key,
  });

  final Widget child;

  /// 此区域对应的优先级；为 null 时不作为投放目标
  final TaskPriority? targetPriority;

  @override
  Widget build(BuildContext context) {
    return TaskDragTarget(
      onAccept: targetPriority == null
          ? null
          : (task) {
              if (task.priority == targetPriority) return;
              final bloc = context.read<TaskListBloc>();
              final targetDate = bloc.state.date;
              if (targetDate != null) {
                bloc.add(
                  TaskListTaskScheduled(
                    task: task,
                    targetPriority: targetPriority!,
                    targetDate: targetDate,
                  ),
                );
              } else {
                bloc.add(
                  TaskListPriorityChanged(
                    task: task,
                    targetPriority: targetPriority!,
                  ),
                );
              }
            },
      child: child,
    );
  }
}
