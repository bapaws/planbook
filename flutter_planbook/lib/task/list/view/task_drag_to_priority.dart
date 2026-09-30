import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:flutter_planbook/task/list/view/task_drag_to_day.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

/// 可接收拖拽任务的“优先级格子”区域，用于四象限视图
///
/// 已在目标日期且优先级相同的投放在 willAccept 阶段拒绝，
/// 避免原地松手被当成 move 而乐观移除。
/// 「今日」四象限仍接受优先级相同、但还不在当天的任务
/// （例如从侧栏收集箱拖入），以便排到该日。
class TaskPriorityDropArea extends StatelessWidget {
  const TaskPriorityDropArea({
    required this.child,
    this.targetPriority,
    super.key,
  });

  final Widget child;

  /// 此区域对应的优先级；为 null 时不作为投放目标
  final TaskPriority? targetPriority;

  /// 是否应接受投放到 [targetPriority] 象限。
  ///
  /// 收集箱 / 逾期只在优先级变化时接受。
  /// 今日视图在优先级变化，或任务还不在 [targetDate] 上时接受。
  static bool wouldAcceptDrop({
    required TaskEntity task,
    required TaskPriority targetPriority,
    required TaskListMode mode,
    required Jiffy? targetDate,
  }) {
    final priorityChanges = task.priority != targetPriority;
    if (mode == TaskListMode.today && targetDate != null) {
      return priorityChanges || TaskDropArea.wouldMoveToDay(task, targetDate);
    }
    return priorityChanges;
  }

  @override
  Widget build(BuildContext context) {
    final priority = targetPriority;
    return TaskDragTarget(
      onWillAcceptWithDetails: priority == null
          ? null
          : (details) {
              final bloc = context.read<TaskListBloc>();
              return wouldAcceptDrop(
                task: details.data,
                targetPriority: priority,
                mode: bloc.mode,
                targetDate: bloc.state.date,
              );
            },
      onAccept: priority == null
          ? null
          : (task) {
              final bloc = context.read<TaskListBloc>();
              final targetDate = bloc.state.date;
              // 仅「今日」四象限：改优先级时可落到该日（例如从侧栏拖入）。
              // 收集箱/逾期只改优先级，避免无日期任务被写成当天任务。
              if (targetDate != null && bloc.mode == TaskListMode.today) {
                if (!wouldAcceptDrop(
                  task: task,
                  targetPriority: priority,
                  mode: bloc.mode,
                  targetDate: targetDate,
                )) {
                  return;
                }
                bloc.add(
                  TaskListTaskScheduled(
                    task: task,
                    targetPriority: priority,
                    targetDate: targetDate,
                  ),
                );
              } else if (task.priority != priority) {
                bloc.add(
                  TaskListPriorityChanged(
                    task: task,
                    targetPriority: priority,
                  ),
                );
              }
            },
      child: child,
    );
  }
}
