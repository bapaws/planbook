part of 'app_activity_bloc.dart';

final class AppActivityState extends Equatable {
  const AppActivityState({
    this.activities = const [],
    this.notices = const [],
    this.isReleasedVersion = false,
  });

  final List<ActivityMessageEntity> activities;
  final List<AppActivityNotice> notices;
  final bool isReleasedVersion;

  List<AppActivityNotice> get drawerNotices =>
      notices.where((notice) => notice.showInDrawer).toList();

  List<AppActivityNotice> get appBarNotices =>
      notices.where((notice) => notice.showInAppBar).toList();

  /// 任务页 AppBar 仅展示优先级最高的一条（新活动 / 审核通过）。
  AppActivityNotice? get appBarNotice {
    for (final notice in notices) {
      if (notice.showInAppBar) return notice;
    }
    return null;
  }

  /// 已收到兑换码（审核通过）时的通知。
  AppActivityNotice? get redeemApprovedNotice {
    for (final notice in notices) {
      if (notice.kind == AppActivityNoticeKind.redeemApproved) return notice;
    }
    return null;
  }

  AppActivityNotice? get alertNotice {
    for (final notice in notices) {
      if (notice.showAsAlert) return notice;
    }
    return null;
  }

  @override
  List<Object> get props => [activities, notices, isReleasedVersion];

  AppActivityState copyWith({
    List<ActivityMessageEntity>? activities,
    List<AppActivityNotice>? notices,
    bool? isReleasedVersion,
  }) {
    return AppActivityState(
      activities: activities ?? this.activities,
      notices: notices ?? this.notices,
      isReleasedVersion: isReleasedVersion ?? this.isReleasedVersion,
    );
  }
}
