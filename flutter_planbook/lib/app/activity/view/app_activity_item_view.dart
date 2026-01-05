import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart';
import 'package:flutter_planbook/app/app_router.dart';

class AppActivityItemView extends StatelessWidget {
  const AppActivityItemView({
    required this.activity,
    this.onPressed,
    super.key,
  });

  final ActivityMessageEntity activity;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = Theme.of(context).textTheme;
    return CupertinoButton(
      onPressed: () {
        context.router.push(AppActivityRoute(activity: activity));
        onPressed?.call();
      },
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 12, 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          spacing: 8,
          children: [
            Text(activity.emoji, style: textTheme.titleLarge),
            Expanded(
              child: Text(
                activity.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ),
            const CupertinoListTileChevron(),
          ],
        ),
      ),
    );
  }
}
