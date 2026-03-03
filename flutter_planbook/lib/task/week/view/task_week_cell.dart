import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_to_day.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:flutter_planbook/task/week/view/task_week_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

class TaskWeekCell extends StatelessWidget {
  const TaskWeekCell({
    required this.title,
    required this.colorScheme,
    this.subtitle,
    this.day,
    super.key,
  });

  final String title;
  final String? subtitle;

  final Jiffy? day;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isToday = day?.isSame(Jiffy.now(), unit: Unit.day) ?? false;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (day == null) return;
          context.tabsRouter.setActiveIndex(RootTaskTab.day.index);
          final isCompleted = context.read<RootTaskBloc>().isCompleted;
          context.read<TaskTodayBloc>().add(
            TaskTodayDateSelected(date: day!, isCompleted: isCompleted),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocSelector<TaskListBloc, TaskListState, int>(
              selector: (state) => state.tasks.length,
              builder: (context, count) => TaskWeekHeader(
                title: title,
                subtitle: subtitle,
                colorScheme: colorScheme,
                isToday: isToday,
                taskCount: count,
                onAddTask: () {
                  context.router.push(
                    TaskNewRoute(
                      dueAt: day,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: TaskDropArea(
                targetDay: day,
                child: _buildTaskList(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragFeedback(BuildContext context, TaskEntity task) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: colorScheme.surfaceContainerLowest,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            height: 28,
            child: TaskListTile.week(task: task),
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

  Widget _buildTaskList(BuildContext context) {
    return BlocSelector<TaskListBloc, TaskListState, List<TaskEntity>>(
      selector: (state) => state.tasks,
      builder: (context, tasks) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final nextTask = index < tasks.length - 1 ? tasks[index + 1] : null;
            final tile = TaskListTile.week(
              key: ValueKey(task),
              task: task,
              titleTextStyle: Theme.of(context).textTheme.bodySmall,
              isExpanded: nextTask?.parentId == task.id,
              onPressed: (t) => context.router.push(
                TaskDetailRoute(
                  taskId: t.id,
                  occurrenceAt: t.occurrence?.occurrenceAt,
                ),
              ),
              onCompleted: (t) => context.read<TaskListBloc>().add(
                TaskListCompleted(task: t),
              ),
              onDeleted: (t) => context.read<TaskListBloc>().add(
                TaskListDeleted(taskId: t.id),
              ),
              onEdited: (t) => context.router.push(
                TaskDetailRoute(
                  taskId: t.id,
                  occurrenceAt: t.occurrence?.occurrenceAt,
                ),
              ),
              onExpanded: (t) => context.read<TaskListBloc>().add(
                TaskListTaskExpanded(task: t),
              ),
            );
            if (day == null) return tile;
            return TaskDraggable(
              task: task,
              feedbackBuilder: _buildDragFeedback,
              child: tile,
            );
          },
        );
      },
    );
  }
}
