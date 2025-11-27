import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_icon.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/database/task_priority.dart';

class TaskPriorityFlagHeader extends StatelessWidget {
  const TaskPriorityFlagHeader({
    required this.priority,
    required this.colorScheme,
    super.key,
  });

  final TaskPriority priority;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const SizedBox(width: 8),
        AppIcon(
          FontAwesomeIcons.solidFlag,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.primary,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            switch (priority) {
              TaskPriority.high => context.l10n.importantUrgent,
              TaskPriority.medium => context.l10n.importantNotUrgent,
              TaskPriority.low => context.l10n.urgentUnimportant,
              TaskPriority.none => context.l10n.notUrgentUnimportant,
            },
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
