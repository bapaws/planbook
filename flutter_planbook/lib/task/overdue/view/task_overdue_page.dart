import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_empty_task_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_page.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

@RoutePage()
class TaskOverduePage extends StatelessWidget {
  const TaskOverduePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RootTaskBloc, RootTaskState>(
      buildWhen: (previous, current) =>
          previous.viewType != current.viewType ||
          previous.taskCounts != current.taskCounts ||
          previous.priorityStyle != current.priorityStyle,
      builder: (context, state) => AnimatedSwitcher(
        duration: Durations.medium1,
        child: switch (state.viewType) {
          RootTaskViewType.list =>
            state.taskCounts[TaskListMode.overdue] == 0
                ? const AppEmptyTaskView()
                : const _TaskOverdueListPage(),
          RootTaskViewType.priority => TaskPriorityPage(
            style: state.priorityStyle,
            mode: TaskListMode.overdue,
            isCompleted: state.showCompleted ? null : false,
          ),
        },
      ),
    );
  }
}

class _TaskOverdueListPage extends StatelessWidget {
  const _TaskOverdueListPage();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskListBloc(
        settingsRepository: context.read(),
        tasksRepository: context.read(),
        notesRepository: context.read(),
        mode: TaskListMode.overdue,
      )..add(const TaskListDayAllRequested()),
      child: BlocListener<RootTaskBloc, RootTaskState>(
        listenWhen: (previous, current) =>
            previous.showCompleted != current.showCompleted,
        listener: (context, state) {
          context.read<TaskListBloc>().add(const TaskListDayAllRequested());
        },
        child: BlocBuilder<TaskListBloc, TaskListState>(
          builder: (context, state) => CustomScrollView(
            slivers: [
              if (state.tasks.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildDateHeader(context, state.tasks[0].occurrenceAt),
                ),
              SliverList.separated(
                itemCount: state.tasks.length,
                separatorBuilder: (context, index) {
                  if (index == state.tasks.length - 1) {
                    return const SizedBox.shrink();
                  }

                  final task = state.tasks[index];
                  final occurrenceAt = task.occurrenceAt;
                  if (occurrenceAt == null) {
                    return const SizedBox.shrink();
                  }

                  final nextTask = index < state.tasks.length - 1
                      ? state.tasks[index + 1]
                      : null;
                  if (nextTask == null || nextTask.parentId != null) {
                    return const SizedBox.shrink();
                  }
                  final nextOccurrenceAt = nextTask.occurrenceAt;
                  if (nextOccurrenceAt == null) {
                    return const SizedBox.shrink();
                  }
                  return occurrenceAt.isSame(nextOccurrenceAt, unit: Unit.day)
                      ? const SizedBox.shrink()
                      : _buildDateHeader(context, nextOccurrenceAt);
                },
                itemBuilder: (context, index) {
                  final task = state.tasks[index];
                  final nextTask = index < state.tasks.length - 1
                      ? state.tasks[index + 1]
                      : null;
                  return TaskListTile(
                    key: ValueKey(task),
                    task: task,
                    titleTextStyle: Theme.of(context).textTheme.titleMedium,
                    isExpanded: nextTask?.parentId == task.id,
                    onPressed: (task) {
                      context.router.push(
                        TaskDetailRoute(
                          taskId: task.id,
                          occurrenceAt: task.occurrence?.occurrenceAt,
                        ),
                      );
                    },
                    onCompleted: (task) {
                      context.read<TaskListBloc>().add(
                        TaskListCompleted(task: task),
                      );
                    },
                    onDeleted: (task) {
                      context.read<TaskListBloc>().add(
                        TaskListDeleted(taskId: task.id),
                      );
                    },
                    onEdited: (task) {
                      context.router.push(TaskNewRoute(initialTask: task));
                    },
                    onDelayed: (task) {
                      context.read<TaskListBloc>().add(
                        TaskListTaskDelayed(task: task),
                      );
                    },
                    onExpanded: (task) {
                      context.read<TaskListBloc>().add(
                        TaskListTaskExpanded(task: task),
                      );
                    },
                  );
                },
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      16 +
                      kRootBottomBarHeight +
                      MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, Jiffy? date) {
    if (date == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final now = Jiffy.now();
    final overdueDays = now.diff(date, unit: Unit.day).toInt();
    final overdueDaysText = context.l10n.overdueDays(overdueDays);
    final parts = overdueDaysText.split(overdueDays.toString());
    final textSpan = TextSpan(
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.outline,
      ),
      children: [
        TextSpan(text: parts[0]),
        TextSpan(
          text: overdueDays.toString(),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(text: parts[1]),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              date.MMMd,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          const Spacer(),
          if (overdueDays > 0) RichText(text: textSpan),
        ],
      ),
    );
  }
}
