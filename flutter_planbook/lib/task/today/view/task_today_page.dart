import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/app/view/app_calendar_view.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_bloc_provider.dart';
import 'package:flutter_planbook/task/list/view/task_list_header.dart';
import 'package:flutter_planbook/task/list/view/task_list_view.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_page.dart';
import 'package:flutter_planbook/task/source/bloc/task_source_bloc.dart';
import 'package:flutter_planbook/task/source/model/task_source_panel_type.dart';
import 'package:flutter_planbook/task/source/view/task_source_panel.dart';
import 'package:flutter_planbook/task/time_block/view/task_time_block_page.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:flutter_planbook/task/today/view/task_focus_view.dart';
import 'package:planbook_api/planbook_api.dart';

@RoutePage()
class TaskTodayPage extends StatelessWidget {
  const TaskTodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskTodayBloc, TaskTodayState>(
      builder: (context, todayState) {
        return Column(
          children: [
            AppCalendarView<TaskEntity>(
              date: todayState.date,
              calendarFormat: todayState.calendarFormat,
              // eventLoader: (day) {
              //   final date = Jiffy.parseFromDateTime(day);
              //   final count = todayState.taskCounts[date.dateKey];
              //   if (count == null) {
              //     context.read<TaskTodayBloc>().add(
              //       TaskTodayTaskCountRequested(date),
              //     );
              //     return [];
              //   }
              //   return [];
              // },
              onDateSelected: (date) {
                context.read<TaskTodayBloc>().add(
                  TaskTodayDateSelected(
                    date: date,
                    isCompleted: context.read<RootTaskBloc>().isCompleted,
                  ),
                );
              },
            ),
            BlocSelector<RootTaskBloc, RootTaskState, NoteType>(
              selector: (state) =>
                  state.tabFocusNoteTypes[RootTaskTab.day] ??
                  NoteType.dailyFocus,
              builder: (context, noteType) {
                final bloc = context.read<TaskTodayBloc>();
                final note = noteType.isFocus
                    ? bloc.state.focusNote
                    : bloc.state.summaryNote;
                return TaskFocusView(
                  note: note,
                  noteType: noteType,
                  onTap: () {
                    final focusAt = context.read<TaskTodayBloc>().state.date;
                    context.router.push(
                      NoteNewTypeRoute(
                        initialNote: note,
                        type: noteType,
                        focusAt: focusAt,
                      ),
                    );
                  },
                  onMindMapTapped: () {
                    _addDiscoverEvent(context, noteType);
                    _navigateToRootDiscover(context, noteType);
                  },
                  onTaskDropped: (task) {
                    context.read<TaskTodayBloc>().add(
                      TaskTodayNoteTaskAppended(
                        task: task,
                        noteType: noteType,
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocProvider(
                create: (context) {
                  final bloc =
                      TaskSourcePanelBloc(
                        tasksRepository: context.read(),
                        tagsRepository: context.read(),
                      )..add(
                        TaskSourcePanelLoaded(
                          isCompleted: context.read<RootTaskBloc>().isCompleted,
                          selectedTagIds: context
                              .read<RootTaskBloc>()
                              .state
                              .selectedTagIds,
                        ),
                      );
                  if (context.read<RootTaskBloc>().state.viewType ==
                      RootTaskViewType.timeBlock) {
                    bloc.add(
                      TaskSourcePanelSourceChanged(
                        TaskSourcePanelAllDay(todayState.date),
                      ),
                    );
                  }
                  return bloc;
                },
                child: MultiBlocListener(
                  listeners: [
                    BlocListener<TaskTodayBloc, TaskTodayState>(
                      listenWhen: (previous, current) =>
                          previous.date != current.date,
                      listener: (context, state) {
                        final sourceType = context
                            .read<TaskSourcePanelBloc>()
                            .state
                            .sourceType;
                        if (sourceType is TaskSourcePanelAllDay) {
                          context.read<TaskSourcePanelBloc>().add(
                            TaskSourcePanelSourceChanged(
                              TaskSourcePanelAllDay(state.date),
                            ),
                          );
                        }
                      },
                    ),
                    BlocListener<RootTaskBloc, RootTaskState>(
                      listenWhen: (previous, current) =>
                          previous.viewType != current.viewType &&
                          current.viewType == RootTaskViewType.timeBlock &&
                          previous.showSourcePanel == false &&
                          current.showSourcePanel == true,
                      listener: (context, state) {
                        context.read<TaskSourcePanelBloc>().add(
                          TaskSourcePanelSourceChanged(
                            TaskSourcePanelAllDay(
                              context.read<TaskTodayBloc>().state.date,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  child: BlocBuilder<RootTaskBloc, RootTaskState>(
                    buildWhen: (previous, current) =>
                        previous.viewType != current.viewType ||
                        previous.priorityStyle != current.priorityStyle,
                    builder: (context, rootTaskState) => Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: Durations.medium1,
                            child: switch (rootTaskState.viewType) {
                              RootTaskViewType.list => const _TaskTodayListPage(
                                key: ValueKey('today-list'),
                              ),
                              RootTaskViewType.priority => TaskPriorityPage(
                                key: const ValueKey('today-priority'),
                                style: rootTaskState.priorityStyle,
                                mode: TaskListMode.today,
                                date: todayState.date,
                              ),
                              RootTaskViewType.timeBlock => TaskTimeBlockPage(
                                key: const ValueKey('today-time-block'),
                                date: todayState.date,
                              ),
                            },
                          ),
                        ),
                        BlocSelector<RootTaskBloc, RootTaskState, bool>(
                          selector: (state) => state.showSourcePanel,
                          builder: (context, showSourcePanel) =>
                              AnimatedCrossFade(
                                duration: Durations.medium1,
                                alignment: Alignment.centerRight,
                                firstChild: const TaskSourcePanel(
                                  key: ValueKey('source-panel'),
                                ),
                                secondChild: const _TaskSourcePanelHandle(
                                  key: ValueKey('source-panel-handle'),
                                ),
                                crossFadeState: showSourcePanel
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addDiscoverEvent(BuildContext context, NoteType noteType) {
    final date = context.read<TaskTodayBloc>().state.date;
    context.read<RootDiscoverBloc>().add(
      noteType.isFocus
          ? RootDiscoverFocusDateChanged(date: date, type: noteType)
          : RootDiscoverSummaryDateChanged(date: date, type: noteType),
    );
  }

  void _navigateToRootDiscover(BuildContext context, NoteType noteType) {
    AutoRouter.of(context).navigate(
      RootHomeRoute(
        children: [
          RootDiscoverRoute(
            children: [
              if (noteType.isFocus)
                const DiscoverFocusRoute()
              else
                const DiscoverSummaryRoute(),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskSourcePanelHandle extends StatelessWidget {
  const _TaskSourcePanelHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () => context.read<RootTaskBloc>().add(
        const RootTaskSourcePanelVisibilityChanged(showSourcePanel: true),
      ),
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: context.blueColorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.blueColorScheme.surfaceContainerHighest,
          ),
        ),
        child: Icon(
          CupertinoIcons.chevron_left,
          size: 14,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _TaskTodayListPage extends StatelessWidget {
  const _TaskTodayListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RootTaskBloc, RootTaskState, Set<String>>(
      selector: (state) => state.selectedTagIds,
      builder: (context, selectedTagIds) {
        return BlocSelector<RootHomeBloc, RootHomeState, List<TagEntity>>(
          selector: (state) => state.topLevelTags,
          builder: (context, tags) {
            final filteredTags = selectedTagIds.isEmpty
                ? tags
                : tags.where((t) => selectedTagIds.contains(t.id)).toList();
            return CustomScrollView(
              slivers: [
                if (selectedTagIds.isEmpty) _buildTaskList(context),
                for (final tag in filteredTags)
                  _buildTaskList(context, tag: tag),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        16 +
                        kRootBottomBarHeight +
                        MediaQuery.of(context).padding.bottom,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTaskList(BuildContext context, {TagEntity? tag}) {
    return TaskListBlocProvider(
      key: tag != null ? ValueKey(tag.id) : const ValueKey('no-tag'),
      requestEvent: () => TaskListRequested(
        date: context.read<TaskTodayBloc>().state.date,
        tagId: tag?.id,
      ),
      child: BlocListener<TaskTodayBloc, TaskTodayState>(
        listenWhen: (previous, current) => previous.date != current.date,
        listener: (context, state) {
          context.read<TaskListBloc>().add(
            TaskListRequested(
              date: state.date,
              tagId: tag?.id,
            ),
          );
        },
        child: BlocBuilder<TaskListBloc, TaskListState>(
          builder: (context, state) => TaskListView(
            tasks: state.tasks,
            header: tag != null ? TaskListHeader(tag: tag) : null,
            targetDay: state.date,
            onTaskDropped: (task) {
              _scheduleTaskToList(context, task, tag: tag);
            },
          ),
        ),
      ),
    );
  }

  void _scheduleTaskToList(
    BuildContext context,
    TaskEntity task, {
    TagEntity? tag,
  }) {
    final bloc = context.read<TaskListBloc>();
    final targetDate = bloc.state.date;
    if (targetDate == null) return;

    var tags = task.tags;
    if (tag != null && !tags.any((t) => t.id == tag.id)) {
      tags = [...tags, tag];
    }

    bloc.add(
      TaskListTaskScheduled(
        task: task,
        targetPriority: task.priority,
        targetDate: targetDate,
        tags: tags,
      ),
    );
  }
}
