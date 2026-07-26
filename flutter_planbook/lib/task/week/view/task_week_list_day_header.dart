import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:flutter_planbook/task/list/view/task_drag_to_day.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:jiffy/jiffy.dart';

/// 列表视图每天的左侧日期列；可接收拖拽任务并改到当天。
class TaskWeekListDayHeader extends StatelessWidget {
  const TaskWeekListDayHeader({
    required this.day,
    required this.colorScheme,
    super.key,
  });

  final Jiffy day;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = day.isSame(Jiffy.now(), unit: Unit.day);
    return TaskDragTarget(
      onAccept: (task) => TaskDropArea.moveTaskToDay(context, task, day),
      builder: (context, child, candidateData) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _navigateToDay(context),
          child: Center(
            child: AnimatedContainer(
              duration: Durations.short2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday
                      ? colorScheme.primary
                      : colorScheme.primaryContainer,
                ),
              ),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Text(
            day.E,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day.date.toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDay(BuildContext context) {
    context.tabsRouter.setActiveIndex(RootTaskTab.day.index);
    final isCompleted = context.read<RootTaskBloc>().isCompleted;
    context.read<TaskTodayBloc>().add(
      TaskTodayDateSelected(date: day, isCompleted: isCompleted),
    );
  }
}
