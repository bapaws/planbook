part of 'settings_task_cubit.dart';

final class SettingsTaskState extends Equatable {
  const SettingsTaskState({
    this.isPlayingCompletedSound = false,
    this.priorityStyle = TaskPriorityStyle.solidColorBackground,
    this.taskAutoNoteRules = const [],
  });

  final bool isPlayingCompletedSound;

  final TaskPriorityStyle priorityStyle;
  final List<TaskAutoNoteRule> taskAutoNoteRules;

  @override
  List<Object> get props => [
    isPlayingCompletedSound,
    priorityStyle,
    taskAutoNoteRules,
  ];

  SettingsTaskState copyWith({
    bool? isPlayingCompletedSound,
    TaskPriorityStyle? priorityStyle,
    List<TaskAutoNoteRule>? taskAutoNoteRules,
  }) {
    return SettingsTaskState(
      isPlayingCompletedSound:
          isPlayingCompletedSound ?? this.isPlayingCompletedSound,
      priorityStyle: priorityStyle ?? this.priorityStyle,
      taskAutoNoteRules: taskAutoNoteRules ?? this.taskAutoNoteRules,
    );
  }
}
