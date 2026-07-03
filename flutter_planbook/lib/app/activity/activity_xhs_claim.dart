import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

/// 小红书活动领取：复制用户 ID 并跳转开发者账号。
Future<void> claimActivityViaXhs({
  required AppLocalizations l10n,
  required String userId,
  ActivityMessageEntity? activity,
  String? xhsUrl,
}) async {
  if (userId.isEmpty) {
    unawaited(
      Fluttertoast.showToast(
        msg: l10n.activityClaimSignInRequired,
        gravity: ToastGravity.CENTER,
      ),
    );
    return;
  }

  await Clipboard.setData(ClipboardData(text: userId));

  unawaited(
    Fluttertoast.showToast(
      msg: l10n.userIdCopied,
      gravity: ToastGravity.CENTER,
    ),
  );

  final url =
      xhsUrl ??
      activity?.xhsClaimURL ??
      ActivityMessageEntity.kDefaultXhsClaimURL;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri);
}

/// Markdown 内 xhsdiscover 链接：用户页复制 ID 后跳转，其余直接打开。
Future<void> openXhsDiscoverLink({
  required AppLocalizations l10n,
  required String userId,
  required String href,
}) async {
  final uri = Uri.tryParse(href);
  if (uri == null) return;

  if (uri.scheme == 'xhsdiscover' && uri.host == 'user') {
    await claimActivityViaXhs(
      l10n: l10n,
      userId: userId,
      xhsUrl: href,
    );
    return;
  }

  await launchUrl(uri);
}
