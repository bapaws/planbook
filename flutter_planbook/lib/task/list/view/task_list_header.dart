import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_tag_icon.dart';
import 'package:planbook_api/planbook_api.dart';

class TaskListHeader extends StatelessWidget {
  const TaskListHeader({required this.tag, this.trailing, super.key});

  final TagEntity tag;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.brightness == Brightness.dark
        ? tag.dark
        : tag.light;
    return Row(
      children: [
        AppTagIcon.fromTagEntity(tag, size: 24),
        const SizedBox(width: 8),
        Text(
          tag.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme?.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class TaskListSliverHeader extends StatelessWidget {
  const TaskListSliverHeader({required this.tag, this.trailing, super.key});

  final TagEntity tag;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      sliver: SliverToBoxAdapter(
        child: TaskListHeader(tag: tag, trailing: trailing),
      ),
    );
  }
}
