import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_list_view.dart';
import 'package:planbook_repository/planbook_repository.dart';

class TaskPriorityPage extends StatelessWidget {
  const TaskPriorityPage({
    required this.mode,
    required this.style,
    super.key,
    this.date,
    this.tag,
    this.isCompleted,
  });

  final TaskPriorityStyle style;

  final TaskListMode mode;
  final Jiffy? date;
  final TagEntity? tag;
  final bool? isCompleted;

  static const spacing = 12.0;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return AnimatedSwitcher(
      duration: Durations.medium1,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
      child: isLandscape
          ? Row(
              children: [
                _buildTaskPriorityPage(
                  context,
                  TaskPriority.high,
                ),
                _buildTaskPriorityPage(
                  context,
                  TaskPriority.medium,
                ),
                _buildTaskPriorityPage(
                  context,
                  TaskPriority.low,
                ),
                _buildTaskPriorityPage(
                  context,
                  TaskPriority.none,
                ),
              ],
            )
          : Column(
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
            ),
    );
  }

  Widget _buildTaskPriorityPage(BuildContext context, TaskPriority priority) {
    return BlocProvider(
      key: ValueKey(date.toString() + priority.name + isCompleted.toString()),
      create: (context) =>
          TaskListBloc(
            settingsRepository: context.read(),
            tasksRepository: context.read(),
            notesRepository: context.read(),
            mode: mode,
            priority: priority,
          )..add(
            TaskListDayAllRequested(
              date: date,
              tagId: tag?.id,
              isCompleted: isCompleted,
            ),
          ),
      child: BlocListener<TaskListBloc, TaskListState>(
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
          child: TaskPriorityListView(
            style: style,
          ),
        ),
      ),
    );
  }
}
