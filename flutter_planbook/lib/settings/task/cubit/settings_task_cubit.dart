import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'settings_task_state.dart';

class SettingsTaskCubit extends Cubit<SettingsTaskState> {
  SettingsTaskCubit({
    required SettingsRepository settingsRepository,
  }) : _settingsRepository = settingsRepository,
       super(const SettingsTaskState());

  final SettingsRepository _settingsRepository;

  Future<void> onRequested() async {
    final rules = await _settingsRepository.getTaskAutoNoteRules();
    final style = await _settingsRepository.getTaskPriorityStyle();
    final sound = await _settingsRepository.getTaskCompletedSound();
    emit(
      state.copyWith(
        taskAutoNoteRules: rules,
        priorityStyle: style,
        isPlayingCompletedSound: sound != null && sound.isNotEmpty,
      ),
    );
  }

  Future<void> onSubtaskRuleTypeChanged(TaskAutoNoteType type) async {
    final rules = [...state.taskAutoNoteRules];
    final index = rules.indexWhere((r) => r.isSubtask);
    if (index == -1) {
      rules.add(TaskAutoNoteRule(isSubtask: true, type: type));
    } else {
      rules[index] = rules[index].copyWith(type: type);
    }
    await _settingsRepository.saveTaskAutoNoteRules(rules);
    emit(state.copyWith(taskAutoNoteRules: rules));
  }

  void onRuleChanged(List<TaskAutoNoteRule> rules) {
    emit(state.copyWith(taskAutoNoteRules: rules));
  }

  Future<void> onPriorityRuleTypeChanged(
    TaskPriority priority,
    TaskAutoNoteType type,
  ) async {
    final rules = [...state.taskAutoNoteRules];
    final index = rules.indexWhere((r) => r.priority == priority);
    if (index == -1) return;
    rules[index] = rules[index].copyWith(type: type);
    await _settingsRepository.saveTaskAutoNoteRules(rules);
    emit(state.copyWith(taskAutoNoteRules: rules));
  }

  Future<void> onPriorityStyleChanged(TaskPriorityStyle style) async {
    await _settingsRepository.saveTaskPriorityStyle(style);
    emit(state.copyWith(priorityStyle: style));
  }

  Future<void> onCompletedSoundChanged({required bool isPlaying}) async {
    // if isPlaying is false, set the sound to empty string
    await _settingsRepository.saveTaskCompletedSound(
      isPlaying ? null : '',
    );
    emit(state.copyWith(isPlayingCompletedSound: isPlaying));
  }
}
