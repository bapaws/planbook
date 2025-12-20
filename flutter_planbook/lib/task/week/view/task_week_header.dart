import 'package:flutter/material.dart';

class TaskWeekHeader extends StatelessWidget {
  const TaskWeekHeader({
    required this.title,
    required this.colorScheme,
    this.subtitle,
    this.isToday = false,
    this.taskCount,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool isToday;
  final ColorScheme colorScheme;
  final int? taskCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        // textBaseline: TextBaseline.alphabetic,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: isToday
                  ? colorScheme.primary
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday
                    ? colorScheme.primary
                    : colorScheme.primaryContainer,
              ),
            ),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isToday
                    ? colorScheme.onPrimary
                    : colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isToday
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          if (taskCount != null)
            Text(
              '$taskCount',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isToday
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
