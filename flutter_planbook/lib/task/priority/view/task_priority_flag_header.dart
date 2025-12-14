import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
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
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '${priority.value}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            switch (priority) {
              TaskPriority.high => context.l10n.importantUrgent,
              TaskPriority.medium => context.l10n.importantNotUrgent,
              TaskPriority.low => context.l10n.urgentUnimportant,
              TaskPriority.none => context.l10n.notUrgentUnimportant,
            },
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
