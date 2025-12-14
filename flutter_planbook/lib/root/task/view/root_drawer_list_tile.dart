import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_icon.dart';

class RootDrawerListTile extends StatelessWidget {
  const RootDrawerListTile({
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.onPressed,
    this.count,
    super.key,
  });

  final IconData icon;
  final Color iconBackgroundColor;
  final String title;
  final int? count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onPressed: onPressed,
        child: Row(
          spacing: 8,
          children: [
            AppIcon(icon, backgroundColor: iconBackgroundColor),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (count != null)
              Text(
                count!.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const CupertinoListTileChevron(),
          ],
        ),
      ),
    );
  }
}
