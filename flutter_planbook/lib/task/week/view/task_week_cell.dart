import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:flutter_planbook/task/week/view/task_week_header.dart';
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
            ),
          ),
          BlocListener<TaskListBloc, TaskListState>(
            listenWhen: (previous, current) =>
                previous.currentTaskNote != current.currentTaskNote &&
                current.currentTaskNote != null,
            listener: (context, state) {
              context.router.push(
                NoteNewRoute(
                  initialNote: state.currentTaskNote,
                ),
              );
            },
            child: Expanded(
              child: _buildTaskList(context),
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
            return TaskListTile.week(
              key: ValueKey(task),
              task: task,
              titleTextStyle: Theme.of(context).textTheme.bodySmall,
              isExpanded: nextTask?.parentId == task.id,
              onPressed: (task) => context.router.push(
                TaskDetailRoute(
                  taskId: task.id,
                  occurrenceAt: task.occurrence?.occurrenceAt,
                ),
              ),
              onCompleted: (task) => context.read<TaskListBloc>().add(
                TaskListCompleted(task: task),
              ),
              onDeleted: (task) => context.read<TaskListBloc>().add(
                TaskListDeleted(taskId: task.id),
              ),
              onEdited: (task) => context.router.push(
                TaskDetailRoute(
                  taskId: task.id,
                  occurrenceAt: task.occurrence?.occurrenceAt,
                ),
              ),
              onExpanded: (task) => context.read<TaskListBloc>().add(
                TaskListTaskExpanded(task: task),
              ),
            );
          },
        );
      },
    );
  }
}
