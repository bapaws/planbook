import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_to_day.dart';
import 'package:flutter_planbook/task/list/view/task_drag_to_priority.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_color_header.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_flag_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

class TaskPriorityListView extends StatelessWidget {
  const TaskPriorityListView({
    required this.style,
    super.key,
    this.onTaskPressed,
    this.onTaskCompleted,
    this.onTaskDeleted,
    this.onTaskEdited,
    this.onTaskDelayed,
  });

  final TaskPriorityStyle style;

  final ValueChanged<TaskEntity>? onTaskPressed;
  final ValueChanged<TaskEntity>? onTaskCompleted;
  final ValueChanged<TaskEntity>? onTaskDeleted;
  final ValueChanged<TaskEntity>? onTaskEdited;
  final ValueChanged<TaskEntity>? onTaskDelayed;

  @override
  Widget build(BuildContext context) {
    final priority = context.read<TaskListBloc>().priority!;
    final colorScheme = priority.getColorScheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: Durations.medium1,
          child: switch (style) {
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
        Expanded(
          child: TaskPriorityDropArea(
            targetPriority: priority,
            child: BlocSelector<TaskListBloc, TaskListState, List<TaskEntity>>(
              selector: (state) => state.tasks,
              builder: (context, tasks) {
                return ListView.builder(
                  padding: const EdgeInsets.only(right: 8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final nextTask = index < tasks.length - 1
                        ? tasks[index + 1]
                        : null;
                    final tile = TaskListTile.priority(
                      key: ValueKey(task.occurrence?.id ?? task.id),
                      task: task,
                      titleTextStyle: Theme.of(context).textTheme.bodyMedium,
                      isExpanded: nextTask?.parentId == task.id,
                      onPressed: (t) {
                        if (onTaskPressed != null) {
                          onTaskPressed!(t);
                        } else {
                          context.router.push(
                            TaskDetailRoute(
                              taskId: t.id,
                              occurrenceAt: t.occurrence?.occurrenceAt,
                            ),
                          );
                        }
                      },
                      onCompleted: (t) {
                        if (onTaskCompleted != null) {
                          onTaskCompleted!(t);
                        } else {
                          context.read<TaskListBloc>().add(
                            TaskListCompleted(task: t),
                          );
                        }
                      },
                      onDeleted: (t) {
                        if (onTaskDeleted != null) {
                          onTaskDeleted!(t);
                        } else {
                          context.read<TaskListBloc>().add(
                            TaskListDeleted(taskId: t.id),
                          );
                        }
                      },
                      onEdited: (t) {
                        context.router.push(
                          TaskNewRoute(initialTask: t),
                        );
                      },
                      onDelayed: (t) {
                        if (onTaskDelayed != null) {
                          onTaskDelayed!(t);
                        } else {
                          context.read<TaskListBloc>().add(
                            TaskListTaskDelayed(task: t),
                          );
                        }
                      },
                      onExpanded: (t) {
                        context.read<TaskListBloc>().add(
                          TaskListTaskExpanded(task: t),
                        );
                      },
                    );
                    return TaskDraggable(
                      task: task,
                      feedbackBuilder: _buildDragFeedback,
                      child: tile,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDragFeedback(BuildContext context, TaskEntity task) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            height: 36,
            child: TaskListTile.priority(task: task),
          ),
          const Positioned(
            top: -8,
            right: -8,
            child: Icon(
              FontAwesomeIcons.circlePlus,
              size: 24,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
