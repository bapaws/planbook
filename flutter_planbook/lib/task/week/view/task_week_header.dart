import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TaskWeekHeader extends StatelessWidget {
  const TaskWeekHeader({
    required this.title,
    required this.colorScheme,
    this.subtitle,
    this.isToday = false,
    this.taskCount,
    this.onAddTask,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool isToday;
  final ColorScheme colorScheme;
  final int? taskCount;

  final VoidCallback? onAddTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const SizedBox(width: 8, height: 28),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: isToday ? colorScheme.primary : colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
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
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const Spacer(),
        if (taskCount != null)
          Text(
            '$taskCount',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (onAddTask != null)
          CupertinoButton(
            onPressed: onAddTask,
            sizeStyle: CupertinoButtonSize.small,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size.square(28),
            child: Icon(
              FontAwesomeIcons.plus,
              size: 14,
              color: colorScheme.primary,
            ),
          )
        else
          const SizedBox(width: 8, height: 28),
      ],
    );
  }
}
