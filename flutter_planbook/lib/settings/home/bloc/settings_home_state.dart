part of 'settings_home_bloc.dart';

class SettingsHomeState extends Equatable {
  const SettingsHomeState({
    this.isPremium = false,
    this.status = PageStatus.initial,
    this.darkMode,
    this.taskAutoNoteRules = const [],
  });
  final PageStatus status;

  final bool isPremium;

  final DarkMode? darkMode;
  final List<TaskAutoNoteRule> taskAutoNoteRules;

  @override
  List<Object?> get props => [status, isPremium, darkMode, taskAutoNoteRules];

  SettingsHomeState copyWith({
    PageStatus? status,
    bool? isPremium,
    DarkMode? darkMode,
    List<TaskAutoNoteRule>? taskAutoNoteRules,
  }) {
    return SettingsHomeState(
      status: status ?? this.status,
      isPremium: isPremium ?? this.isPremium,
      darkMode: darkMode ?? this.darkMode,
      taskAutoNoteRules: taskAutoNoteRules ?? this.taskAutoNoteRules,
    );
  }
}
