part of 'settings_icon_cubit.dart';

class SettingsIconState extends Equatable {
  const SettingsIconState({
    this.status = PageStatus.initial,
    this.icon,
  });

  final PageStatus status;
  final AppIcons? icon;

  @override
  List<Object?> get props => [
        status,
        icon,
      ];

  SettingsIconState copyWith({
    PageStatus? status,
    AppIcons? icon,
  }) {
    return SettingsIconState(
      status: status ?? this.status,
      icon: icon ?? this.icon,
    );
  }
}
