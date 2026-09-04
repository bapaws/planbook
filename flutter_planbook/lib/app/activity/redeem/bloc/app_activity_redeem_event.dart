part of 'app_activity_redeem_bloc.dart';

sealed class AppActivityRedeemEvent extends Equatable {
  const AppActivityRedeemEvent();

  @override
  List<Object?> get props => [];
}

/// 进入页面，恢复已保存的 submission 状态。
final class AppActivityRedeemStarted extends AppActivityRedeemEvent {
  const AppActivityRedeemStarted();
}

/// 用户选择了截图。
final class AppActivityRedeemImagesPicked extends AppActivityRedeemEvent {
  const AppActivityRedeemImagesPicked(this.paths);

  final List<String> paths;

  @override
  List<Object?> get props => [paths];
}

/// 用户填写了提交链接。
final class AppActivityRedeemProofUrlChanged extends AppActivityRedeemEvent {
  const AppActivityRedeemProofUrlChanged(this.url);

  final String url;

  @override
  List<Object?> get props => [url];
}

/// 提交截图。
final class AppActivityRedeemSubmitted extends AppActivityRedeemEvent {
  const AppActivityRedeemSubmitted();
}

/// 刷新审核状态。
final class AppActivityRedeemStatusRefreshed extends AppActivityRedeemEvent {
  const AppActivityRedeemStatusRefreshed();
}

/// 用户点击兑换。
final class AppActivityRedeemRedeemTapped extends AppActivityRedeemEvent {
  const AppActivityRedeemRedeemTapped();
}

/// 清除已选图片，允许重新提交。
final class AppActivityRedeemResetTapped extends AppActivityRedeemEvent {
  const AppActivityRedeemResetTapped();
}
