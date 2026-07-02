import 'dart:io';

import 'package:flutter_planbook/app/activity/model/app_activity_notice.dart';
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart';
import 'package:redeem_client/redeem_client.dart';

/// 兑换审核快照，供通知解析使用。
class AppActivityRedeemSnapshot {
  const AppActivityRedeemSnapshot({
    this.redeemActivity,
    this.status,
  });

  final ActivityMessageEntity? redeemActivity;
  final SubmissionStatus? status;
}

/// 将活动列表与兑换状态解析为统一通知列表。
class AppActivityNoticeResolver {
  const AppActivityNoticeResolver._();

  static List<AppActivityNotice> resolve({
    required List<ActivityMessageEntity> activities,
    required AppActivityRedeemSnapshot redeemSnapshot,
  }) {
    final notices = <AppActivityNotice>[];
    final coveredActivityIds = <int>{};

    final redeemActivity = redeemSnapshot.redeemActivity;
    final redeemStatus = redeemSnapshot.status;

    if (Platform.isIOS &&
        redeemActivity != null &&
        redeemActivity.enableInAppRedeem &&
        redeemStatus != null) {
      switch (redeemStatus) {
        case SubmissionApproved():
          notices.add(
            AppActivityNotice(
              id: 'redeem_approved:${redeemActivity.id}',
              activity: redeemActivity,
              kind: AppActivityNoticeKind.redeemApproved,
              style: AppActivityNoticeStyle.success,
              destination: AppActivityNoticeDestination.redeem(
                redeemActivity,
              ),
            ),
          );
          coveredActivityIds.add(redeemActivity.id);
        case SubmissionPending():
          notices.add(
            AppActivityNotice(
              id: 'redeem_pending:${redeemActivity.id}',
              activity: redeemActivity,
              kind: AppActivityNoticeKind.redeemPending,
              style: AppActivityNoticeStyle.pending,
              destination: AppActivityNoticeDestination.redeem(
                redeemActivity,
              ),
            ),
          );
          coveredActivityIds.add(redeemActivity.id);
        case SubmissionRejected():
          break;
      }
    }

    for (final activity in activities) {
      if (!activity.isNew) continue;
      if (coveredActivityIds.contains(activity.id)) continue;

      notices.add(
        AppActivityNotice(
          id: 'campaign:${activity.id}',
          activity: activity,
          kind: AppActivityNoticeKind.newCampaign,
          style: AppActivityNoticeStyle.campaign,
          destination: AppActivityNoticeDestination.detail(activity),
        ),
      );
      coveredActivityIds.add(activity.id);
    }

    notices.sort((a, b) => a.priority.compareTo(b.priority));
    return notices;
  }

  static AppActivityNotice? noticeForActivity(
    List<AppActivityNotice> notices,
    int activityId,
  ) {
    for (final notice in notices) {
      if (notice.activity.id == activityId) return notice;
    }
    return null;
  }

  static AppActivityNoticeKind? redeemKindForActivity(
    List<AppActivityNotice> notices,
    int activityId,
  ) {
    for (final notice in notices) {
      if (notice.activity.id != activityId) continue;
      if (notice.kind == AppActivityNoticeKind.redeemApproved ||
          notice.kind == AppActivityNoticeKind.redeemPending) {
        return notice.kind;
      }
    }
    return null;
  }
}
