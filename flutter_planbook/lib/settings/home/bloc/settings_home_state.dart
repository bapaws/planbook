part of 'settings_home_bloc.dart';

class SettingsHomeState extends Equatable {
  const SettingsHomeState({
    this.status = PageStatus.initial,
    this.darkMode,
    this.taskAutoNoteRules = const [],
  });

  final PageStatus status;
  final DarkMode? darkMode;
  final List<TaskAutoNoteRule> taskAutoNoteRules;

  @override
  List<Object?> get props => [status, darkMode, taskAutoNoteRules];

  SettingsHomeState copyWith({
    PageStatus? status,
    DarkMode? darkMode,
    List<TaskAutoNoteRule>? taskAutoNoteRules,
  }) {
    return SettingsHomeState(
      status: status ?? this.status,
      darkMode: darkMode ?? this.darkMode,
      taskAutoNoteRules: taskAutoNoteRules ?? this.taskAutoNoteRules,
    );
  }
}
