import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/activity/bloc/app_activity_bloc.dart';
import 'package:flutter_planbook/app/activity/model/app_activity_notice.dart';
import 'package:flutter_planbook/app/activity/view/app_activity_notice_banner.dart';
import 'package:flutter_planbook/l10n/l10n.dart';

/// 侧滑栏中的活动通知列表。
class AppActivityNoticeDrawerSection extends StatelessWidget {
  const AppActivityNoticeDrawerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      AppActivityBloc,
      AppActivityState,
      List<AppActivityNotice>
    >(
      selector: (state) => state.drawerNotices,
      builder: (context, notices) {
        if (notices.isEmpty) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final notice in notices)
              AppActivityNoticeBanner(notice: notice),
          ],
        );
      },
    );
  }
}

/// 根据通知类型返回展示标题。
String appActivityNoticeTitle(
  AppActivityNotice notice,
  AppLocalizations l10n,
) {
  return switch (notice.kind) {
    AppActivityNoticeKind.newCampaign => notice.activity.title,
    AppActivityNoticeKind.redeemApproved => l10n.activityNoticeRedeemApproved,
    AppActivityNoticeKind.redeemPending => l10n.activityNoticeRedeemPending,
  };
}
