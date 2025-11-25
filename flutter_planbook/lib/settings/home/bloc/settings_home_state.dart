part of 'settings_home_bloc.dart';

class SettingsHomeState extends Equatable {
  const SettingsHomeState({
    this.isPremium = false,
    this.status = PageStatus.initial,
    this.darkMode,
    this.cloudSynchronizable = false,
  });
  final PageStatus status;

  final bool isPremium;

  final DarkMode? darkMode;
  final bool cloudSynchronizable;

  @override
  List<Object?> get props => [status, isPremium, darkMode, cloudSynchronizable];

  SettingsHomeState copyWith({
    PageStatus? status,
    bool? isPremium,
    DarkMode? darkMode,
    bool? cloudSynchronizable,
  }) {
    return SettingsHomeState(
      status: status ?? this.status,
      isPremium: isPremium ?? this.isPremium,
      darkMode: darkMode ?? this.darkMode,
      cloudSynchronizable: cloudSynchronizable ?? this.cloudSynchronizable,
    );
  }
}
