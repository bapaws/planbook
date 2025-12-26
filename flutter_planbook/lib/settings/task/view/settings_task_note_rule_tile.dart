import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/home/view/settings_row.dart';
import 'package:flutter_planbook/settings/task/model/task_auto_note_rule.dart';
import 'package:planbook_api/settings/task_auto_note_rule.dart';
import 'package:pull_down_button/pull_down_button.dart';

class SettingsTaskNoteRuleTile extends StatelessWidget {
  const SettingsTaskNoteRuleTile({
    required this.leading,
    required this.title,
    required this.type,
    required this.onChanged,
    super.key,
  });

  final Widget leading;
  final Widget title;

  final TaskAutoNoteType type;

  final ValueChanged<TaskAutoNoteType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return PullDownButton(
      buttonAnchor: PullDownMenuAnchor.end,
      itemBuilder: (context) {
        return [
          PullDownMenuTitle(title: Text(context.l10n.noteRuleDescription)),
          for (final value in TaskAutoNoteType.values)
            PullDownMenuItem.selectable(
              title: value.getTitle(context),
              subtitle: value.getDescription(context),
              selected: type == value,
              onTap: () {
                onChanged(value);
              },
            ),
        ];
      },
      buttonBuilder: (context, showMenu) => SettingsRow(
        onPressed: showMenu,
        leading: leading,
        title: title,
        additionalInfo: Text(
          type.getTitle(context),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
