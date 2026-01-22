import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/month/view/task_month_list_tile.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:planbook_repository/planbook_repository.dart';

class TaskMonthCell extends StatelessWidget {
  const TaskMonthCell({
    required this.day,

    super.key,
  });

  final Jiffy day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = day.isSame(Jiffy.now(), unit: Unit.day);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.tabsRouter.setActiveIndex(RootTaskTab.day.index);
        final isCompleted = context.read<RootTaskBloc>().isCompleted;
        context.read<TaskTodayBloc>().add(
          TaskTodayDateSelected(date: day, isCompleted: isCompleted),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isToday
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      day.date.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isToday
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                BlocSelector<TaskListBloc, TaskListState, int>(
                  selector: (state) => state.tasks.length,
                  builder: (context, count) => Text(
                    count.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 2),
            // 任务列表（简化显示）
            Expanded(
              child:
                  BlocSelector<TaskListBloc, TaskListState, List<TaskEntity>>(
                    selector: (state) => state.tasks,
                    builder: (context, tasks) {
                      final screenSize = MediaQuery.of(context).size;
                      final isLargeScreen =
                          math.min(screenSize.height, screenSize.width) > 600;
                      final height = isLargeScreen ? 16.0 : 14.0;
                      final fontSize = isLargeScreen ? 10.0 : 8.0;
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const ClampingScrollPhysics(),
                        itemExtent: height + 1,
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskMonthListTile(
                            key: ValueKey(task),
                            task: task,
                            height: height,
                            fontSize: fontSize,
                            colorScheme: task.priority.getColorScheme(context),
                          );
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
