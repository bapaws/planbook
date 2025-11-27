import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_api/database/task_priority.dart';

class TaskPriorityColorHeader extends StatelessWidget {
  const TaskPriorityColorHeader({
    required this.priority,
    required this.colorScheme,
    super.key,
  });

  final TaskPriority priority;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(
        left: priority.isUrgent ? 8 : 6,
        right: priority.isUrgent ? 6 : 8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${priority.value}. ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
            // const SizedBox(width: 4),
            Text(
              switch (priority) {
                TaskPriority.high => context.l10n.importantUrgent,
                TaskPriority.medium => context.l10n.importantNotUrgent,
                TaskPriority.low => context.l10n.urgentUnimportant,
                TaskPriority.none => context.l10n.notUrgentUnimportant,
              },
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                // fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
