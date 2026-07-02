part of 'settings_quadrant_cubit.dart';

final class SettingsQuadrantState extends Equatable {
  const SettingsQuadrantState({
    this.configs = const [],
  });

  final List<QuadrantConfigEntity> configs;

  QuadrantConfigEntity configOf(TaskPriority priority) {
    return configs.firstWhere(
      (e) => e.priority == priority,
      orElse: () => QuadrantConfigEntity(priority: priority),
    );
  }

  @override
  List<Object?> get props => [configs];

  SettingsQuadrantState copyWith({
    List<QuadrantConfigEntity>? configs,
  }) {
    return SettingsQuadrantState(
      configs: configs ?? this.configs,
    );
  }
}
