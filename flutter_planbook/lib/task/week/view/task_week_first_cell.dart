import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/source/bloc/task_source_bloc.dart';
import 'package:flutter_planbook/task/source/model/task_source_panel_type.dart';
import 'package:flutter_planbook/task/source/view/task_source_panel.dart';
import 'package:flutter_planbook/task/week/bloc/task_week_bloc.dart';
import 'package:flutter_planbook/task/week/model/task_week_view_mode.dart';
import 'package:flutter_planbook/task/week/view/task_week_focus_cell.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/note_type.dart';
import 'package:pull_down_button/pull_down_button.dart';

/// 周视图八宫格第一格：本周重点 / 本周总结 / 侧栏数据源互斥展示。
class TaskWeekFirstCell extends StatelessWidget {
  const TaskWeekFirstCell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskWeekBloc, TaskWeekState>(
      buildWhen: (previous, current) =>
          previous.focusNote != current.focusNote ||
          previous.summaryNote != current.summaryNote,
      builder: (context, weekState) {
        return BlocBuilder<RootTaskBloc, RootTaskState>(
          buildWhen: (previous, current) =>
              previous.weekGridCellKind != current.weekGridCellKind ||
              previous.tabFocusNoteTypes[RootTaskTab.week] !=
                  current.tabFocusNoteTypes[RootTaskTab.week],
          builder: (context, rootState) {
            final kind = rootState.weekGridCellKind;
            final noteType =
                rootState.tabFocusNoteTypes[RootTaskTab.week] ??
                NoteType.weeklyFocus;
            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TaskWeekFirstCellHeader(
                    kind: kind,
                    noteType: noteType,
                  ),
                  Expanded(
                    child: kind == TaskWeekGridCellKind.source
                        ? const TaskSourcePanel.embedded()
                        : _buildNoteBody(context, weekState, noteType),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoteBody(
    BuildContext context,
    TaskWeekState weekState,
    NoteType noteType,
  ) {
    final note = noteType.isFocus ? weekState.focusNote : weekState.summaryNote;
    return TaskWeekFocusCell(
      note: note,
      noteType: noteType,
      onTaskDropped: (task) {
        context.read<TaskWeekBloc>().add(
          TaskWeekNoteTaskAppended(
            task: task,
            noteType: noteType,
          ),
        );
      },
    );
  }
}

class _TaskWeekFirstCellHeader extends StatelessWidget {
  const _TaskWeekFirstCellHeader({
    required this.kind,
    required this.noteType,
  });

  final TaskWeekGridCellKind kind;
  final NoteType noteType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BlocBuilder<TaskSourcePanelBloc, TaskSourcePanelState>(
      builder: (context, sourceState) {
        final title = kind == TaskWeekGridCellKind.note
            ? noteType.getTitle(context.l10n)
            : TaskSourcePanel.titleOf(context, sourceState.sourceType);
        return PullDownButton(
          itemBuilder: (context) => _buildMenuItems(
            context,
            sourceState.sourceType,
          ),
          buttonBuilder: (context, showMenu) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: showMenu,
              child: Row(
                children: [
                  const SizedBox(width: 8, height: 28),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (kind == TaskWeekGridCellKind.source) ...[
                              Icon(
                                TaskSourcePanel.iconOf(
                                  sourceState.sourceType,
                                ),
                                size: 12,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              CupertinoIcons.chevron_down,
                              size: 10,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (kind == TaskWeekGridCellKind.source) ...[
                    Text(
                      '${sourceState.tasks.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      sizeStyle: CupertinoButtonSize.small,
                      minimumSize: const Size.square(28),
                      onPressed: () => _openMindMap(context, noteType),
                      child: FaIcon(
                        FontAwesomeIcons.snowflake,
                        size: 14,
                        color: noteType.getColorScheme(context).primary,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<PullDownMenuEntry> _buildMenuItems(
    BuildContext context,
    TaskSourcePanelType sourceType,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isNote = kind == TaskWeekGridCellKind.note;
    return [
      PullDownMenuItem.selectable(
        title: l10n.weeklyFocus,
        selected: isNote && noteType == NoteType.weeklyFocus,
        icon: FontAwesomeIcons.snowflake.data,
        iconColor: context.amberColorScheme.primary,
        onTap: () => context.read<RootTaskBloc>().add(
          const RootTaskWeekGridCellKindChanged(
            kind: TaskWeekGridCellKind.note,
            noteType: NoteType.weeklyFocus,
          ),
        ),
      ),
      PullDownMenuItem.selectable(
        title: l10n.weeklySummary,
        selected: isNote && noteType == NoteType.weeklySummary,
        icon: FontAwesomeIcons.snowflake.data,
        iconColor: context.amberColorScheme.primary,
        onTap: () => context.read<RootTaskBloc>().add(
          const RootTaskWeekGridCellKindChanged(
            kind: TaskWeekGridCellKind.note,
            noteType: NoteType.weeklySummary,
          ),
        ),
      ),
      const PullDownMenuDivider.large(),
      PullDownMenuItem.selectable(
        title: l10n.inbox,
        selected: !isNote && sourceType is TaskSourcePanelInbox,
        icon: CupertinoIcons.tray,
        iconColor: primary,
        onTap: () {
          context.read<TaskSourcePanelBloc>().add(
            const TaskSourcePanelSourceChanged(TaskSourcePanelInbox()),
          );
          context.read<RootTaskBloc>().add(
            const RootTaskWeekGridCellKindChanged(
              kind: TaskWeekGridCellKind.source,
            ),
          );
        },
      ),
      PullDownMenuItem(
        title: l10n.tag,
        icon: CupertinoIcons.tag,
        iconColor: primary,
        onTap: () => unawaited(
          _openProSourcePicker(
            context,
            initialSourceType: sourceType is TaskSourcePanelTag
                ? sourceType
                : const TaskSourcePanelTag([]),
          ),
        ),
      ),
      PullDownMenuItem(
        title: l10n.date,
        icon: CupertinoIcons.calendar,
        iconColor: primary,
        onTap: () => unawaited(
          _openProSourcePicker(
            context,
            initialSourceType: sourceType is TaskSourcePanelDate
                ? sourceType
                : TaskSourcePanelDate(Jiffy.now()),
          ),
        ),
      ),
    ];
  }

  Future<void> _openProSourcePicker(
    BuildContext context, {
    required TaskSourcePanelType initialSourceType,
  }) async {
    final isPremium = context.read<AppPurchasesBloc>().state.isPremium;
    if (!isPremium) {
      await context.router.push(const AppPurchasesRoute());
      return;
    }
    await TaskSourcePanel.openPicker(
      context,
      initialSourceType: initialSourceType,
      variant: TaskSourcePanelVariant.embedded,
      showSourceTypeSelector: false,
    );
  }

  void _openMindMap(BuildContext context, NoteType noteType) {
    final date = context.read<TaskWeekBloc>().state.date;
    context.read<RootDiscoverBloc>().add(
      noteType.isFocus
          ? RootDiscoverFocusDateChanged(
              date: date,
              type: noteType,
            )
          : RootDiscoverSummaryDateChanged(
              date: date,
              type: noteType,
            ),
    );
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
