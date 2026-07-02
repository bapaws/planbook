import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'settings_quadrant_state.dart';

class SettingsQuadrantCubit extends Cubit<SettingsQuadrantState> {
  SettingsQuadrantCubit({
    required SettingsRepository settingsRepository,
    required UsersRepository usersRepository,
  }) : _settingsRepository = settingsRepository,
       _usersRepository = usersRepository,
       super(const SettingsQuadrantState());

  final SettingsRepository _settingsRepository;
  final UsersRepository _usersRepository;

  Future<void> onRequested() async {
    final configs = await _settingsRepository.getQuadrantConfigs();
    emit(state.copyWith(configs: configs));
  }

  Future<void> onNameChanged(TaskPriority priority, String name) async {
    final trimmed = name.trim();
    await _update(
      priority,
      (config) => config.copyWith(name: () => trimmed.isEmpty ? null : trimmed),
    );
  }

  Future<void> onResetQuadrant(TaskPriority priority) async {
    await _update(
      priority,
      (config) => config.copyWith(name: () => null),
    );
  }

  Future<void> _update(
    TaskPriority priority,
    QuadrantConfigEntity Function(QuadrantConfigEntity) transform,
  ) async {
    final configs = [
      for (final config in state.configs)
        if (config.priority == priority) transform(config) else config,
    ];
    emit(state.copyWith(configs: configs));
    // 本地优先：先写本地（即时同步 UI 与原生小组件）
    await _settingsRepository.saveQuadrantConfigs(configs);
    // 登录时再镜像到云端
    if (_usersRepository.user != null) {
      await _usersRepository.updateQuadrantConfig(configs);
    }
  }
}
