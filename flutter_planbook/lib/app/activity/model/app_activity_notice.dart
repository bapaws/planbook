import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart';

/// 扩展 AppActivity 用户通知时：
/// 1. 在 [AppActivityNoticeKind] 增加类型并设定 priority
/// 2. 在 NoticeResolver（app_activity_notice_resolver.dart）增加解析分支
/// 3. 按需调整 [AppActivityNoticeKind.showInDrawer] 等展示标志
enum AppActivityNoticeKind {
  redeemApproved(0),
  newCampaign(10),
  redeemPending(20);

  const AppActivityNoticeKind(this.priority);

  final int priority;

  bool get showInDrawer =>
      this == AppActivityNoticeKind.redeemApproved ||
      this == AppActivityNoticeKind.newCampaign;

  bool get showInAppBar =>
      this == AppActivityNoticeKind.redeemApproved ||
      this == AppActivityNoticeKind.newCampaign;

  bool get showAsAlert => this == AppActivityNoticeKind.newCampaign;
}

enum AppActivityNoticeStyle {
  campaign,
  success,
  pending,
}

/// 点击通知后的导航目标。
sealed class AppActivityNoticeDestination extends Equatable {
  const AppActivityNoticeDestination();

  const factory AppActivityNoticeDestination.detail(
    ActivityMessageEntity activity,
  ) = AppActivityNoticeDestinationDetail;

  const factory AppActivityNoticeDestination.redeem(
    ActivityMessageEntity activity,
  ) = AppActivityNoticeDestinationRedeem;
}

final class AppActivityNoticeDestinationDetail
    extends AppActivityNoticeDestination {
  const AppActivityNoticeDestinationDetail(this.activity);

  final ActivityMessageEntity activity;

  @override
  List<Object?> get props => [activity];
}

final class AppActivityNoticeDestinationRedeem
    extends AppActivityNoticeDestination {
  const AppActivityNoticeDestinationRedeem(this.activity);

  final ActivityMessageEntity activity;

  @override
  List<Object?> get props => [activity];
}

/// 统一的用户活动通知。
class AppActivityNotice extends Equatable {
  const AppActivityNotice({
    required this.id,
    required this.activity,
    required this.kind,
    required this.style,
    required this.destination,
  });

  final String id;
  final ActivityMessageEntity activity;
  final AppActivityNoticeKind kind;
  final AppActivityNoticeStyle style;
  final AppActivityNoticeDestination destination;

  int get priority => kind.priority;

  bool get showInDrawer => kind.showInDrawer;

  bool get showInAppBar => kind.showInAppBar;

  bool get showAsAlert => kind.showAsAlert;

  @override
  List<Object?> get props => [id, activity, kind, style, destination];
}
