import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/task/priority/bloc/task_priority_bloc.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_flag_header.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_list_tile.dart';
import 'package:planbook_repository/planbook_repository.dart' hide ColorScheme;

class TaskPriorityListView extends StatelessWidget {
  const TaskPriorityListView({
    required this.priority,
    super.key,
    this.onTaskPressed,
    this.onTaskCompleted,
    this.onTaskDeleted,
    this.onTaskEdited,
  });

  final TaskPriority priority;

  final ValueChanged<TaskEntity>? onTaskPressed;
  final ValueChanged<TaskEntity>? onTaskCompleted;
  final ValueChanged<TaskEntity>? onTaskDeleted;
  final ValueChanged<TaskEntity>? onTaskEdited;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: priority.color,
      brightness: theme.brightness,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TaskPriorityColorHeader(priority: priority, colorScheme: colorScheme),
        TaskPriorityFlagHeader(priority: priority, colorScheme: colorScheme),
        Expanded(
          child:
              BlocSelector<
                TaskPriorityBloc,
                TaskPriorityState,
                List<TaskEntity>
              >(
                selector: (state) => state.tasks[priority] ?? [],
                builder: (context, tasks) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskPriorityListTile(
                        key: ValueKey(task.id),
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
                            context.read<TaskPriorityBloc>().add(
                              TaskPriorityCompleted(task: task),
                            );
                          }
                        },
                        onDeleted: () {
                          if (onTaskDeleted != null) {
                            onTaskDeleted!(task);
                          } else {
                            context.read<TaskPriorityBloc>().add(
                              TaskPriorityDeleted(taskId: task.id),
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
