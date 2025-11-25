import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_icon.dart';

class TaskTagHeader extends StatelessWidget {
  const TaskTagHeader({
    required this.icon,
    required this.backgroundColor,
    required this.title,
    super.key,
  });

  final IconData icon;
  final Color backgroundColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        AppIcon(
          icon,
          backgroundColor: backgroundColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
