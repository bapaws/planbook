import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
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
    if (targetPriority == null) return child;
    return DragTarget<TaskEntity>(
      onAcceptWithDetails: (details) {
        if (details.data.priority == targetPriority) return;
        context.read<TaskListBloc>().add(
          TaskListPriorityChanged(
            task: details.data,
            targetPriority: targetPriority!,
          ),
        );
      },
      builder: (context, candidateData, rejectedData) => child,
    );
  }
}
