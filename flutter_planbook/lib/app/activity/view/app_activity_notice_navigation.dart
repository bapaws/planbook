import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/activity/bloc/app_activity_bloc.dart';
import 'package:flutter_planbook/app/activity/model/app_activity_notice.dart';
import 'package:flutter_planbook/app/app_router.dart';

/// 打开活动通知目标页，返回后刷新通知列表。
Future<void> openAppActivityNotice(
  BuildContext context,
  AppActivityNotice notice,
) async {
  switch (notice.destination) {
    case AppActivityNoticeDestinationDetail(:final activity):
      await context.router.push(AppActivityRoute(activity: activity));
    case AppActivityNoticeDestinationRedeem(:final activity):
      await context.router.push(AppActivityRedeemRoute(activity: activity));
  }

  if (context.mounted) {
    context.read<AppActivityBloc>().add(const AppActivityNoticesRefreshed());
  }
}
