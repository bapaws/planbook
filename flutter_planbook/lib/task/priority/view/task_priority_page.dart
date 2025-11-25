import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_icon.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

class TaskPriorityPage extends StatelessWidget {
  const TaskPriorityPage({
    required this.mode,
    super.key,
    this.date,
    this.tag,
  });

  static const spacing = 8.0;

  final TaskListMode mode;
  final Jiffy? date;
  final TagEntity? tag;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildTaskPriorityPage(
                context,
                TaskPriority.high,
              ),

              _buildTaskPriorityPage(
                context,
                TaskPriority.medium,
              ),
            ],
          ),
        ),
        const SizedBox(height: spacing),
        Expanded(
          child: Row(
            children: [
              _buildTaskPriorityPage(
                context,
                TaskPriority.low,
              ),

              _buildTaskPriorityPage(
                context,
                TaskPriority.none,
              ),
            ],
          ),
        ),
        const SizedBox(
          height: kToolbarHeight + 22 + 8,
        ),
      ],
    );
  }

  Widget _buildTaskPriorityPage(BuildContext context, TaskPriority priority) {
    return Expanded(
      child: BlocProvider(
        create: (context) =>
            TaskListBloc(
              tasksRepository: context.read(),
              mode: mode,
            )..add(
              TaskListRequested(
                date: date,
                tagId: tag?.id,
                priority: priority,
              ),
            ),
        child: _TaskPriorityPage(
          priority: priority,
        ),
      ),
    );
  }
}

class _TaskPriorityPage extends StatelessWidget {
  const _TaskPriorityPage({
    required this.priority,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Container(
        //   margin: EdgeInsets.only(
        //     left: priority.isUrgent ? 8 : 4,
        //     right: priority.isUrgent ? 4 : 8,
        //   ),
        //   padding: const EdgeInsets.symmetric(
        //     horizontal: 8,
        //     vertical: 2,
        //   ),
        //   decoration: BoxDecoration(
        //     color: priority.color,
        //     borderRadius: BorderRadius.circular(8),
        //   ),
        //   child: SizedBox(
        //     width: double.infinity,
        //     child: Text(
        //       switch (priority) {
        //         TaskPriority.high => context.l10n.importantUrgent,
        //         TaskPriority.medium => context.l10n.importantNotUrgent,
        //         TaskPriority.low => context.l10n.urgentUnimportant,
        //         TaskPriority.none => context.l10n.notUrgentUnimportant,
        //       },
        //       style: theme.textTheme.labelSmall?.copyWith(
        //         color: Colors.white,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //   ),
        // ),
        Row(
          children: [
            SizedBox(width: priority.isUrgent ? 8 : 4),
            AppIcon(
              FontAwesomeIcons.solidFlag,
              backgroundColor: priority.color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                switch (priority) {
                  TaskPriority.high => context.l10n.importantUrgent,
                  TaskPriority.medium => context.l10n.importantNotUrgent,
                  TaskPriority.low => context.l10n.urgentUnimportant,
                  TaskPriority.none => context.l10n.notUrgentUnimportant,
                },
                style: theme.textTheme.labelSmall?.copyWith(
                  color: priority.color,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: BlocBuilder<TaskListBloc, TaskListState>(
            builder: (context, state) {
              return ListView.builder(
                padding: const EdgeInsets.only(
                  right: 8,
                ),
                itemCount: state.tasks.length,
                itemBuilder: (context, index) {
                  final task = state.tasks[index];
                  return TaskListTile(
                    key: ValueKey(task.id),
                    task: task,
                    onPressed: () {
                      if (onTaskPressed != null) {
                        onTaskPressed!(task);
                      } else {
                        // context.router.push(TaskRoute(taskId: task.id));
                        print('onTaskPressed: ${task.id}');
                      }
                    },
                    onCompleted: () {
                      if (onTaskCompleted != null) {
                        onTaskCompleted!(task);
                      } else {
                        context.read<TaskListBloc>().add(
                          TaskListCompleted(taskId: task.id),
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

class _QuadrantCard extends StatelessWidget {
  const _QuadrantCard({
    required this.quadrant,
    required this.tasks,
    required this.priority,
  });

  final Quadrant quadrant;
  final List<TaskEntity> tasks;
  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final color = priority.color;

    String title;
    switch (quadrant) {
      case Quadrant.importantUrgent:
        title = l10n.importantUrgent;
      case Quadrant.importantNotUrgent:
        title = l10n.importantNotUrgent;
      case Quadrant.urgentUnimportant:
        title = l10n.urgentUnimportant;
      case Quadrant.notUrgentUnimportant:
        title = l10n.notUrgentUnimportant;
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      l10n.noData,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskListTile(
                        key: ValueKey(task.id),
                        task: task,
                        onPressed: () {
                          print('onTaskPressed: ${task.id}');
                        },
                        onCompleted: () {
                          context.read<TaskListBloc>().add(
                            TaskListCompleted(taskId: task.id),
                          );
                        },
                        onDeleted: () {
                          context.read<TaskListBloc>().add(
                            TaskListDeleted(taskId: task.id),
                          );
                        },
                        onEdited: () {
                          context.router.push(
                            TaskNewRoute(initialTask: task),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
