import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_empty_task_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_to_day.dart';
import 'package:flutter_planbook/task/list/view/task_list_bloc_provider.dart';
import 'package:flutter_planbook/task/list/view/task_list_delete_dialog_listener.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_page.dart';
import 'package:flutter_planbook/task/source/bloc/task_source_bloc.dart';
import 'package:flutter_planbook/task/source/view/task_source_panel.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

@RoutePage()
class TaskOverduePage extends StatelessWidget {
  const TaskOverduePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TaskSourcePanelBloc(
            tasksRepository: context.read(),
            tagsRepository: context.read(),
            taskActionService: context.read(),
          )..add(
            TaskSourcePanelLoaded(
              isCompleted: context.read<RootTaskBloc>().isCompleted,
              selectedTagIds: context.read<RootTaskBloc>().state.selectedTagIds,
            ),
          ),
      child: BlocBuilder<RootTaskBloc, RootTaskState>(
        buildWhen: (previous, current) =>
            previous.dayViewType != current.dayViewType ||
            previous.taskCounts != current.taskCounts ||
            previous.priorityStyle != current.priorityStyle ||
            previous.showSourcePanel != current.showSourcePanel,
        builder: (context, state) {
          final isEmpty = state.taskCounts[TaskListMode.overdue] == 0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: Durations.medium1,
                  child: switch (state.dayViewType) {
                    RootTaskViewType.list || RootTaskViewType.timeBlock =>
                      isEmpty
                          ? AppEmptyTaskView(
                              key: const ValueKey('overdue-empty'),
                              title: context.l10n.taskEmptyOverdue,
                            )
                          : const _TaskOverdueListPage(
                              key: ValueKey('overdue-list'),
                            ),
                    RootTaskViewType.priority => TaskPriorityPage(
                      key: const ValueKey('overdue-priority'),
                      style: state.priorityStyle,
                      mode: TaskListMode.overdue,
                    ),
                  },
                ),
              ),
              AnimatedSwitcher(
                duration: Durations.medium1,
                transitionBuilder: (child, animation) => SizeTransition(
                  axis: Axis.horizontal,
                  sizeFactor: animation,
                  child: child,
                ),
                child: state.showSourcePanel
                    ? const TaskSourcePanel(
                        key: ValueKey('overdue-source-panel'),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('overdue-source-panel-hidden'),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskOverdueListPage extends StatelessWidget {
  const _TaskOverdueListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TaskListBlocProvider(
      mode: TaskListMode.overdue,
      requestEvent: () => TaskListDayAllRequested(date: Jiffy.now()),
      child: BlocBuilder<TaskListBloc, TaskListState>(
        builder: (context, state) => TaskListDeleteDialogListener(
          child: CustomScrollView(
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
                  final tile = TaskListTile(
                    key: ValueKey(task),
                    task: task,
                    titleTextStyle: Theme.of(context).textTheme.titleMedium,
                    isExpanded: nextTask?.parentId == task.id,
                    onPressed: (task) {
                      context.router.push(
                        TaskDetailRoute(
                          taskId: task.parentId ?? task.id,
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
                        TaskListDeleteRequested(task: task),
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
                  // 支持拖到侧栏改期 / 加标签 / 回收集箱
                  return TaskDraggable(
                    task: task,
                    feedbackBuilder: taskListTileDragFeedbackBuilder,
                    onDragCompleted: (task) {
                      context.read<TaskListBloc>().add(
                        TaskListTaskDragCompleted(task: task),
                      );
                    },
                    child: tile,
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
