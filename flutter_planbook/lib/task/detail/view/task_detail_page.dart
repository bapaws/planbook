import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_icon.dart';
import 'package:flutter_planbook/app/view/app_tag_view.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/core/view/app_empty_note_view.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/list/view/note_list_tile.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/task/detail/bloc/task_detail_bloc.dart';
import 'package:flutter_planbook/task/detail/view/task_detail_bottom_bar.dart';
import 'package:flutter_planbook/task/detail/view/task_detail_date_view.dart';
import 'package:flutter_planbook/task/detail/view/task_detail_repeat_view.dart';
import 'package:flutter_planbook/task/detail/view/task_detail_tile.dart';
import 'package:flutter_planbook/task/duration/model/task_duration_entity.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:sliver_tools/sliver_tools.dart';

@RoutePage()
class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({required this.taskId, this.occurrenceAt, super.key});
  final String taskId;
  final Jiffy? occurrenceAt;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TaskDetailBloc(
              tasksRepository: context.read(),
              settingsRepository: context.read(),
              notesRepository: context.read(),
              taskId: taskId,
              occurrenceAt: occurrenceAt,
            )
            ..add(const TaskDetailRequested())
            ..add(const TaskDetailNotesRequested()),
      child: MultiBlocListener(
        listeners: [
          BlocListener<TaskDetailBloc, TaskDetailState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == PageStatus.loading) {
                EasyLoading.show(maskType: EasyLoadingMaskType.clear);
              } else if (EasyLoading.isShow) {
                EasyLoading.dismiss();
              }
              if (state.status == PageStatus.dispose) {
                context.router.pop();
              }
            },
          ),
          BlocListener<TaskDetailBloc, TaskDetailState>(
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
          ),
        ],
        child: const _TaskDetailPage(),
      ),
    );
  }
}

class _TaskDetailPage extends StatelessWidget {
  const _TaskDetailPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: const NavigationBarBackButton(),
        actions: [
          PullDownButton(
            itemBuilder: (context) => [
              PullDownMenuItem(
                icon: FontAwesomeIcons.trash,
                title: context.l10n.delete,
                isDestructive: true,
                onTap: () {
                  context.read<TaskDetailBloc>().add(
                    const TaskDetailDeleted(),
                  );
                },
              ),
            ],
            buttonBuilder: (context, showMenu) => CupertinoButton(
              onPressed: showMenu,
              child: const Icon(FontAwesomeIcons.ellipsis),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          BlocBuilder<TaskDetailBloc, TaskDetailState>(
            builder: (context, state) {
              final task = state.task;
              if (task == null) return const SizedBox.shrink();

              final colorScheme = task.priority.getColorScheme(context);
              final tagColorScheme = (theme.brightness == Brightness.dark
                  ? task.tags.firstOrNull?.dark
                  : task.tags.firstOrNull?.light);
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: TextField(
                      controller: TextEditingController(text: task.title),
                      style: theme.textTheme.headlineSmall,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: context.l10n.taskTitleHint,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 32,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        context.read<TaskDetailBloc>().add(
                          TaskDetailTitleChanged(title: value),
                        );
                      },
                    ),
                  ),
                  for (final child in task.children)
                    SliverToBoxAdapter(
                      child: TaskListTile(
                        task: child,
                        onPressed: (value) async {
                          final subTasks = await context.router
                              .push<List<TaskEntity>>(
                                TaskNewChildRoute(
                                  subTasks: task.children,
                                ),
                              );
                          if (subTasks is! List<TaskEntity> ||
                              !context.mounted) {
                            return;
                          }
                          context.read<TaskDetailBloc>().add(
                            TaskDetailChildrenChanged(children: subTasks),
                          );
                        },
                        onCompleted: (task) {
                          context.read<TaskDetailBloc>().add(
                            TaskDetailCompleted(task: task),
                          );
                        },
                      ),
                    ),
                  if (task.children.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 32),
                    ),

                  TaskDetailSliverTile(
                    onPressed: () {
                      _onDateTap(context, task);
                    },
                    leading: AppIcon(
                      FontAwesomeIcons.calendarDay,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.primary,
                    ),
                    title: context.l10n.allDay,
                    trailing: Text(
                      task.isAllDay ? context.l10n.yes : context.l10n.no,
                    ),
                  ),
                  if (task.startAt != null &&
                      task.endAt != null &&
                      (!task.isAllDay ||
                          !task.startAt!.isSame(
                            task.endAt!,
                            unit: Unit.day,
                          ))) ...[
                    if (task.startAt != null)
                      TaskDetailDateView(
                        title: task.isAllDay
                            ? context.l10n.startDate
                            : context.l10n.startTime,
                        formattedDate: task.isAllDay
                            ? task.startAt?.yMMMEd
                            : task.startAt?.yMMMEdjm,
                        onPressed: () {
                          _onDateTap(context, task);
                        },
                      ),
                    if (task.endAt != null)
                      TaskDetailDateView(
                        title: task.isAllDay
                            ? context.l10n.endDate
                            : context.l10n.endTime,
                        formattedDate: task.isAllDay
                            ? task.endAt?.yMMMEd
                            : task.endAt?.yMMMEdjm,
                        onPressed: () {
                          _onDateTap(context, task);
                        },
                      ),
                  ] else ...[
                    TaskDetailDateView(
                      title: context.l10n.date,
                      formattedDate:
                          task.occurrenceAt?.yMMMEd ?? context.l10n.inbox,
                      onPressed: () {
                        _onDateTap(context, task);
                      },
                    ),
                  ],
                  TaskDetailRepeatView(recurrenceRule: task.recurrenceRule),
                  TaskDetailSliverTile(
                    onPressed: () async {
                      final priority = await context.router.push(
                        TaskPriorityPickerRoute(
                          selectedPriority: task.priority,
                        ),
                      );
                      if (priority != null &&
                          priority is TaskPriority &&
                          context.mounted) {
                        context.read<TaskDetailBloc>().add(
                          TaskDetailPriorityChanged(priority: priority),
                        );
                      }
                    },
                    leading: AppIcon(
                      FontAwesomeIcons.solidFlag,
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.primary,
                    ),
                    title: context.l10n.priority,
                    trailing: Text(switch (task.priority) {
                      TaskPriority.high => context.l10n.importantUrgent,
                      TaskPriority.medium => context.l10n.importantNotUrgent,
                      TaskPriority.low => context.l10n.urgentUnimportant,
                      TaskPriority.none => context.l10n.notUrgentUnimportant,
                    }),
                  ),
                  TaskDetailSliverTile(
                    onPressed: () {
                      final tags = context
                          .read<TaskDetailBloc>()
                          .state
                          .task
                          ?.tags;
                      context.router.push(
                        TagPickerRoute(
                          selectedTags: tags ?? [],
                          onSelected: (value) {
                            context.read<TaskDetailBloc>().add(
                              TaskDetailTagsChanged(tags: value),
                            );
                          },
                        ),
                      );
                    },
                    leading: AppIcon(
                      FontAwesomeIcons.hashtag,
                      backgroundColor:
                          tagColorScheme?.primaryContainer ??
                          colorScheme.secondaryContainer,
                      foregroundColor:
                          tagColorScheme?.primary ?? colorScheme.secondary,
                    ),
                    title: context.l10n.tags,
                    trailing: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final tag in task.tags) ...[
                          AppTagView(tag: tag),
                        ],
                      ],
                    ),
                  ),
                  // SliverToBoxAdapter(
                  //   child: Divider(
                  //     indent: 16,
                  //     endIndent: 16,
                  //     height: 24,
                  //     color: theme.colorScheme.surfaceContainerHighest,
                  //   ),
                  // ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        context.l10n.notes,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver:
                        BlocSelector<
                          TaskDetailBloc,
                          TaskDetailState,
                          List<NoteEntity>
                        >(
                          selector: (state) => state.notes,
                          builder: (context, notes) {
                            return SliverAnimatedSwitcher(
                              duration: Durations.medium1,
                              child: notes.isEmpty
                                  ? const SliverPadding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 32,
                                      ),
                                      sliver: SliverToBoxAdapter(
                                        child: AppEmptyNoteView(
                                          showSlogan: false,
                                        ),
                                      ),
                                    )
                                  : SliverList.separated(
                                      itemCount: notes.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 16),
                                      itemBuilder: (context, index) =>
                                          NoteListTile(
                                            note: notes[index],
                                            showLinkButton: false,
                                            showDate: true,
                                            onDeleted: () {
                                              context
                                                  .read<TaskDetailBloc>()
                                                  .add(
                                                    TaskDetailNoteDeleted(
                                                      noteId: notes[index].id,
                                                    ),
                                                  );
                                            },
                                          ),
                                    ),
                            );
                          },
                        ),
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
              );
            },
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 22,
            child: TaskDetailBottomBar(),
          ),
        ],
      ),
    );
  }

  Future<void> _onDateTap(BuildContext context, TaskEntity task) async {
    if (task.occurrence?.occurrenceAt != null) {
      await Fluttertoast.showToast(
        msg: context.l10n.recurringTaskCannotChangeDate,
        gravity: ToastGravity.CENTER,
      );
      return;
    }
    final entity = await context.router.push(
      TaskDurationRoute(
        startAt: task.startAt,
        endAt: task.endAt,
        isAllDay: task.isAllDay,
      ),
    );
    if (entity == null || entity is! TaskDurationEntity || !context.mounted) {
      return;
    }
    context.read<TaskDetailBloc>().add(
      TaskDetailDurationChanged(entity: entity),
    );
  }
}
