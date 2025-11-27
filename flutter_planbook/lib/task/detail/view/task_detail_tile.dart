import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TaskDetailTile extends StatelessWidget {
  const TaskDetailTile({
    required this.title,
    required this.onPressed,
    this.leading,
    this.trailing,
    super.key,
  });

  final Widget? leading;
  final String title;
  final Widget? trailing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoButton(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      minimumSize: const Size.square(kMinInteractiveDimension),
      onPressed: onPressed,
      child: Row(
        children: [
          if (leading != null) leading!,
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            DefaultTextStyle(
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              child: trailing!,
            ),
          const CupertinoListTileChevron(),
        ],
      ),
    );
  }
}

class TaskDetailSliverTile extends StatelessWidget {
  const TaskDetailSliverTile({
    required this.title,
    required this.onPressed,
    this.leading,
    this.trailing,
    super.key,
  });

  final Widget? leading;
  final String title;
  final Widget? trailing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: TaskDetailTile(
        leading: leading,
        title: title,
        trailing: trailing,
        onPressed: onPressed,
      ),
    );
  }
}
