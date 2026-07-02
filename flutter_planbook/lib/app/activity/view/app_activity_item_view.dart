import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/activity/model/app_activity_notice.dart';
import 'package:flutter_planbook/app/activity/view/app_activity_notice_banner.dart';

/// 兼容旧入口；请优先使用 [AppActivityNoticeBanner]。
@Deprecated('Use AppActivityNoticeBanner with AppActivityNotice instead.')
class AppActivityItemView extends StatelessWidget {
  const AppActivityItemView({
    required this.notice,
    super.key,
  });

  final AppActivityNotice notice;

  @override
  Widget build(BuildContext context) {
    return AppActivityNoticeBanner(notice: notice);
  }
}
