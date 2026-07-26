import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:flutter_planbook/task/list/view/task_drag_to_day.dart';
import 'package:flutter_planbook/task/list/view/task_list_bloc_provider.dart';
import 'package:flutter_planbook/task/list/view/task_list_delete_dialog_listener.dart';
import 'package:flutter_planbook/task/week/model/task_week_day_color.dart';
import 'package:flutter_planbook/task/week/view/task_week_list_day_header.dart';
import 'package:flutter_planbook/task/week/view/task_week_list_day_tasks.dart';
import 'package:jiffy/jiffy.dart';

/// 周列表中单日分组：左侧日期头 + 右侧任务网格，整组可接收拖放。
class TaskWeekListDayGroup extends StatelessWidget {
  const TaskWeekListDayGroup({
    required this.day,
    required this.crossAxisCount,
    super.key,
  });

  /// 左侧日期列宽度，与 [SliverConstrainedCrossAxis] 一致。
  static const dayHeaderExtent = 64.0;

  final Jiffy day;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorSchemeForWeekDay(day);
    return TaskListBlocProvider(
      requestEvent: () => TaskListDayAllRequested(
        date: day,
        isCompleted: context.read<RootTaskBloc>().isCompleted,
        selectedTagIds: context.read<RootTaskBloc>().state.selectedTagIds,
      ),
      // 子 widget 的 context 在 Provider 之下，供 onAccept 读取 TaskListBloc。
      child: _TaskWeekListDayGroupBody(
        day: day,
        colorScheme: colorScheme,
        crossAxisCount: crossAxisCount,
      ),
    );
  }
}

/// [TaskListBlocProvider] 之下的单日内容，确保拖放回调能读到 TaskListBloc。
class _TaskWeekListDayGroupBody extends StatelessWidget {
  const _TaskWeekListDayGroupBody({
    required this.day,
    required this.colorScheme,
    required this.crossAxisCount,
  });

  final Jiffy day;
  final ColorScheme colorScheme;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return TaskListDeleteDialogListener(
      child: SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        // 投放区包住整日 CrossAxisGroup：任务少时右侧比日期头矮，
        // 仅包任务 sliver 会漏掉日期头旁的视觉空白。
        sliver: SliverTaskDragTarget(
          onAccept: (task) => TaskDropArea.moveTaskToDay(context, task, day),
          sliver: SliverCrossAxisGroup(
            slivers: [
              SliverConstrainedCrossAxis(
                maxExtent: TaskWeekListDayGroup.dayHeaderExtent,
                sliver: SliverToBoxAdapter(
                  child: TaskWeekListDayHeader(
                    day: day,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
              TaskWeekListDayTasksSliver(
                colorScheme: colorScheme,
                crossAxisCount: crossAxisCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
