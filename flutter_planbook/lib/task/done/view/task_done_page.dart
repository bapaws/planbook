import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_tag_view.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/done/cubit/task_done_cubit.dart';
import 'package:flutter_planbook/task/done/view/task_done_complete_at_view.dart';
import 'package:flutter_planbook/task/done/view/task_duration_tag_view.dart';
import 'package:flutter_planbook/task/done/view/task_recurrence_rule_tag_view.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:planbook_repository/settings/settings_repository.dart';

@RoutePage()
class TaskDonePage extends StatelessWidget {
  const TaskDonePage({
    required this.task,
    super.key,
  });

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskDoneCubit(
        tasksRepository: context.read(),
        settingsRepository: context.read(),
        notesRepository: context.read(),
        task: task,
      )..onRequested(),
      child: MultiBlocListener(
        listeners: [
          BlocListener<TaskDoneCubit, TaskDoneState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == PageStatus.loading) {
                EasyLoading.show(maskType: EasyLoadingMaskType.clear);
              } else if (EasyLoading.isShow) {
                EasyLoading.dismiss();
              }
            },
          ),
          BlocListener<TaskDoneCubit, TaskDoneState>(
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
        child: const _TaskDonePage(),
      ),
    );
  }
}

class _TaskDonePage extends StatelessWidget {
  const _TaskDonePage();

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: BlocBuilder<TaskDoneCubit, TaskDoneState>(
          builder: (context, state) {
            final incompleteChildrenCount = context
                .read<TaskDoneCubit>()
                .incompleteChildrenCount;
            final theme = Theme.of(context);
            final colorScheme = state.task.priority.getColorScheme(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBar(
                  forceMaterialTransparency: true,
                  leading: const NavigationBarCloseButton(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    state.task.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (state.task.occurrence?.occurrenceAt != null &&
                          state.task.dueAt != null)
                        Container(
                          height: 22,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FontAwesomeIcons.solidCalendar,
                                size: 12,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                state.task.occurrence?.occurrenceAt.yMMMEd ??
                                    state.task.dueAt?.yMMMEd ??
                                    '',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        height: 22,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FontAwesomeIcons.solidFlag,
                              size: 12,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              state.task.priority.getTitle(context.l10n),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final tag in state.task.tags) ...[
                        AppTagView(tag: tag),
                      ],
                      if (state.task.startAt != null &&
                          state.task.endAt != null)
                        TaskDurationTagView(
                          startAt: state.task.startAt,
                          endAt: state.task.endAt,
                          isAllDay: state.task.isAllDay,
                          colorScheme: colorScheme,
                        ),
                      if (state.task.recurrenceRule != null)
                        TaskRecurrenceRuleTagView(
                          recurrenceRule: state.task.recurrenceRule!,
                          colorScheme: colorScheme,
                        ),
                    ],
                  ),
                ),
                for (final child in state.task.children) ...[
                  TaskListTile.priority(
                    key: ValueKey(child),
                    task: child,
                    titleTextStyle: theme.textTheme.bodyMedium,
                    onCompleted: (task) {
                      context.read<TaskDoneCubit>().onCompleted(task: task);
                    },
                  ),
                ],
                if (!state.task.isCompleted) ...[
                  Divider(
                    indent: 16,
                    endIndent: 16,
                    height: 32,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  CupertinoListTile(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: const Icon(
                      FontAwesomeIcons.solidCalendarCheck,
                      size: 16,
                      color: Colors.blue,
                    ),
                    leadingSize: 16,
                    leadingToTitle: 8,
                    title: Text(
                      context.l10n.completedAt,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: const TaskDoneCompleteAtView(),
                  ),
                  const SizedBox(height: 24),
                ] else
                  const SizedBox(height: 32),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () {
                    context.read<TaskDoneCubit>().onCompleted();
                    _playCompletedSound(context);
                  },
                  child: Container(
                    width: double.infinity,
                    height: kToolbarHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(kToolbarHeight),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.surfaceContainerHighest,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.task.isCompleted
                              ? context.l10n.uncompleteTask
                              : context.l10n.completeTask,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (!state.task.isCompleted &&
                            state.task.children.isNotEmpty)
                          Text(
                            context.l10n.incompleteSubtasksCount(
                              incompleteChildrenCount,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _playCompletedSound(BuildContext context) async {
    unawaited(HapticFeedback.lightImpact());

    final sound = await context
        .read<SettingsRepository>()
        .getTaskCompletedSound();
    if (sound != null && sound.isNotEmpty) {
      final player = AudioPlayer();
      await player.play(AssetSource(sound));
    }
  }
}
