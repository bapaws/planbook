import 'dart:io';

import 'package:flutter_planbook/app/activity/notice/app_activity_notice_resolver.dart';
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart';
import 'package:flutter_planbook/core/redeem/redeem_service.dart';
import 'package:redeem_client/redeem_client.dart';

/// 拉取当前设备的兑换审核状态。
class AppActivityRedeemStatusLoader {
  const AppActivityRedeemStatusLoader._();

  static Future<AppActivityRedeemSnapshot> load(
    AppActivityRepository repository,
  ) async {
    if (!Platform.isIOS) {
      return const AppActivityRedeemSnapshot();
    }

    final redeemActivity = await repository.findInAppRedeemActivity();
    if (redeemActivity == null) {
      return const AppActivityRedeemSnapshot();
    }

    final available = await RedeemService.instance.isAvailable;
    if (!available) {
      return AppActivityRedeemSnapshot(redeemActivity: redeemActivity);
    }

    await RedeemService.instance.loadSavedSubmissionId();
    final submissionId = RedeemService.instance.savedSubmissionId;
    if (submissionId == null) {
      return AppActivityRedeemSnapshot(redeemActivity: redeemActivity);
    }

    try {
      final status = await RedeemService.instance.getSubmissionStatus(
        submissionId,
      );
      if (status is SubmissionApproved || status is SubmissionPending) {
        return AppActivityRedeemSnapshot(
          redeemActivity: redeemActivity,
          status: status,
        );
      }
      return AppActivityRedeemSnapshot(redeemActivity: redeemActivity);
    } on Object {
      return AppActivityRedeemSnapshot(redeemActivity: redeemActivity);
    }
  }
}
