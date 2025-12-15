import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_color_header.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_flag_header.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_list_tile.dart';
import 'package:planbook_repository/planbook_repository.dart';

class TaskPriorityListView extends StatelessWidget {
  const TaskPriorityListView({
    super.key,
    this.onTaskPressed,
    this.onTaskCompleted,
    this.onTaskDeleted,
    this.onTaskEdited,
  });

  final ValueChanged<TaskEntity>? onTaskPressed;
  final ValueChanged<TaskEntity>? onTaskCompleted;
  final ValueChanged<TaskEntity>? onTaskDeleted;
  final ValueChanged<TaskEntity>? onTaskEdited;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priority = context.read<TaskListBloc>().priority!;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: priority.color,
      brightness: theme.brightness,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocSelector<TaskListBloc, TaskListState, TaskPriorityStyle>(
          selector: (state) => state.priorityStyle,
          builder: (context, priorityStyle) => AnimatedSwitcher(
            duration: Durations.medium1,
            child: switch (priorityStyle) {
              TaskPriorityStyle.solidColorBackground => TaskPriorityColorHeader(
                priority: priority,
                colorScheme: colorScheme,
              ),
              TaskPriorityStyle.numberIcon => TaskPriorityFlagHeader(
                priority: priority,
                colorScheme: colorScheme,
              ),
            },
          ),
        ),
        Expanded(
          child: BlocSelector<TaskListBloc, TaskListState, List<TaskEntity>>(
            selector: (state) => state.tasks,
            builder: (context, tasks) {
              return ListView.builder(
                padding: const EdgeInsets.only(
                  right: 8,
                ),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return TaskPriorityListTile(
                    key: ValueKey(task.occurrence?.id ?? task.id),
                    task: task,
                    onPressed: () {
                      if (onTaskPressed != null) {
                        onTaskPressed!(task);
                      } else {
                        context.router.push(
                          TaskDetailRoute(taskId: task.id),
                        );
                      }
                    },
                    onCompleted: () {
                      if (onTaskCompleted != null) {
                        onTaskCompleted!(task);
                      } else {
                        context.read<TaskListBloc>().add(
                          TaskListCompleted(task: task),
                        );
                      }
                    },
                    onDeleted: () {
                      if (onTaskDeleted != null) {
                        onTaskDeleted!(task);
                      } else {
                        context.read<TaskListBloc>().add(
                          TaskListDeleted(taskId: task.id),
                        );
                      }
                    },
                    onEdited: () {
                      context.router.push(TaskNewRoute(initialTask: task));
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
