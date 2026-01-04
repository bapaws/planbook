import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/database/note_type.dart';

class TaskFocusHeaderView extends StatelessWidget {
  const TaskFocusHeaderView({
    required this.noteType,
    required this.tab,
    super.key,
  });

  final NoteType noteType;
  final RootTaskTab tab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        const SizedBox(width: 8),
        CupertinoButton(
          onPressed: () {
            context.read<RootTaskBloc>().add(
              RootTaskTabFocusNoteTypeChanged(
                tab: tab,
                noteType: noteType.sameRangeNoteType,
              ),
            );
          },
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
          ),
          minimumSize: const Size.square(21),
          color: noteType.isFocus
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          child: Text(
            getFocusTitle(context.l10n),
            style: noteType.isFocus
                ? theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  )
                : theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        CupertinoButton(
          onPressed: () {
            context.read<RootTaskBloc>().add(
              RootTaskTabFocusNoteTypeChanged(
                tab: tab,
                noteType: noteType.sameRangeNoteType,
              ),
            );
          },
          key: ValueKey(noteType),
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
          ),
          minimumSize: const Size.square(21),
          color: noteType.isSummary
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          child: Text(
            getSummaryTitle(context.l10n),
            style: noteType.isSummary
                ? theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  )
                : theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
          ),
        ),
        if (tab != RootTaskTab.week) ...[
          const Spacer(),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sizeStyle: CupertinoButtonSize.small,
            minimumSize: const Size.square(21),
            onPressed: () {
              context.read<RootTaskBloc>().add(
                RootTaskTabFocusNoteTypeChanged(
                  tab: tab,
                ),
              );
            },
            child: Icon(
              FontAwesomeIcons.xmark,
              size: 14,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ],
    );
  }

  String getFocusTitle(AppLocalizations l10n) {
    if (tab == RootTaskTab.day) {
      return '${l10n.dailyFocus} 🎯';
    }
    if (tab == RootTaskTab.week) {
      return '${l10n.weeklyFocus} 🎯';
    }
    if (tab == RootTaskTab.month) {
      return '${l10n.monthlyFocus} 🎯';
    }
    throw UnimplementedError();
  }

  String getSummaryTitle(AppLocalizations l10n) {
    if (tab == RootTaskTab.day) {
      return '${l10n.dailySummary} 🎯';
    }
    if (tab == RootTaskTab.week) {
      return '${l10n.weeklySummary} 🎯';
    }
    if (tab == RootTaskTab.month) {
      return '${l10n.monthlySummary} 🎯';
    }
    throw UnimplementedError();
  }
}
