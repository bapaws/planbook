import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/activity/model/app_activity_notice.dart';
import 'package:flutter_planbook/app/activity/view/app_activity_notice_drawer_section.dart';
import 'package:flutter_planbook/app/activity/view/app_activity_notice_navigation.dart';
import 'package:flutter_planbook/l10n/l10n.dart';

/// 活动通知横幅（侧滑栏等位置复用）。
class AppActivityNoticeBanner extends StatelessWidget {
  const AppActivityNoticeBanner({
    required this.notice,
    this.onPressed,
    super.key,
  });

  final AppActivityNotice notice;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final backgroundColor = switch (notice.style) {
      AppActivityNoticeStyle.campaign => theme.colorScheme.errorContainer,
      AppActivityNoticeStyle.success => theme.colorScheme.tertiaryContainer,
      AppActivityNoticeStyle.pending => theme.colorScheme.primaryContainer,
    };
    final foregroundColor = switch (notice.style) {
      AppActivityNoticeStyle.campaign => theme.colorScheme.onErrorContainer,
      AppActivityNoticeStyle.success => theme.colorScheme.onTertiaryContainer,
      AppActivityNoticeStyle.pending => theme.colorScheme.onPrimaryContainer,
    };

    return CupertinoButton(
      onPressed: () async {
        await openAppActivityNotice(context, notice);
        onPressed?.call();
      },
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 6, 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          spacing: 8,
          children: [
            Text(notice.activity.emoji, style: textTheme.titleLarge),
            Expanded(
              child: Text(
                appActivityNoticeTitle(notice, l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: foregroundColor,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 18,
              color: foregroundColor,
            ),
          ],
        ),
      ),
    );
  }
}
