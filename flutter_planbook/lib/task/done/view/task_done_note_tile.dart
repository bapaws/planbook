import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/task/model/task_auto_note_rule.dart';
import 'package:flutter_planbook/task/done/cubit/task_done_cubit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/settings/task_auto_note_rule.dart';
import 'package:pull_down_button/pull_down_button.dart';

class TaskDoneNoteTile extends StatelessWidget {
  const TaskDoneNoteTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return PullDownButton(
      buttonAnchor: PullDownMenuAnchor.end,
      itemBuilder: (context) => [
        for (final type in TaskAutoNoteType.values)
          PullDownMenuItem.selectable(
            title: type.getTitle(context),
            selected:
                context.read<TaskDoneCubit>().state.taskAutoNoteType == type,
            onTap: () {
              context.read<TaskDoneCubit>().onTaskAutoNoteTypeChanged(
                type,
              );
            },
          ),
      ],
      buttonBuilder: (context, showMenu) => CupertinoListTile(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: const Icon(
          FontAwesomeIcons.featherPointed,
          size: 16,
          color: Colors.green,
        ),
        leadingSize: 16,
        leadingToTitle: 8,
        backgroundColor: Colors.transparent,
        backgroundColorActivated: theme.colorScheme.surfaceContainerHighest,
        title: Text(
          context.l10n.taskNote,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        additionalInfo:
            BlocSelector<TaskDoneCubit, TaskDoneState, TaskAutoNoteType>(
              selector: (state) => state.taskAutoNoteType,
              builder: (context, type) => Text(
                type.getTitle(context),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        trailing: const CupertinoListTileChevron(),
        onTap: showMenu,
      ),
    );
  }
}
