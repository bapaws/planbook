part of 'task_source_bloc.dart';

final class TaskSourcePanelState extends Equatable {
  const TaskSourcePanelState({
    this.sourceType = const TaskSourcePanelInbox(),
    this.selectedTagId,
    this.sourceDate,
    this.selectedTagIdsFilter = const {},
    this.isCompleted,
    this.isVisible = true,
    this.status = PageStatus.initial,
    this.tasks = const [],
    this.optimisticRemovedTaskIds = const {},
    this.optimisticUpdatedTasks = const [],
  });

  final TaskSourcePanelType sourceType;
  final String? selectedTagId;
  final Jiffy? sourceDate;
  final Set<String> selectedTagIdsFilter;
  final bool? isCompleted;
  final bool isVisible;
  final PageStatus status;
  final List<TaskEntity> tasks;

  /// 乐观移除的任务 ID；用于在 stream 尚未反映变更前保持任务不可见。
  final Set<String> optimisticRemovedTaskIds;

  /// 乐观更新的任务；用于在 stream 尚未反映变更前覆盖旧数据。
  final List<TaskEntity> optimisticUpdatedTasks;

  @override
  List<Object?> get props => [
    sourceType,
    selectedTagId,
    sourceDate,
    selectedTagIdsFilter,
    isCompleted,
    isVisible,
    status,
    tasks,
    optimisticRemovedTaskIds,
    optimisticUpdatedTasks,
  ];

  TaskSourcePanelState copyWith({
    TaskSourcePanelType? sourceType,
    String? selectedTagId,
    ValueGetter<Jiffy?>? sourceDate,
    Set<String>? selectedTagIdsFilter,
    bool? isCompleted,
    bool? isVisible,
    PageStatus? status,
    List<TaskEntity>? tasks,
    Set<String>? optimisticRemovedTaskIds,
    List<TaskEntity>? optimisticUpdatedTasks,
  }) {
    return TaskSourcePanelState(
      sourceType: sourceType ?? this.sourceType,
      selectedTagId: selectedTagId ?? this.selectedTagId,
      sourceDate: sourceDate != null ? sourceDate() : this.sourceDate,
      selectedTagIdsFilter: selectedTagIdsFilter ?? this.selectedTagIdsFilter,
      isCompleted: isCompleted ?? this.isCompleted,
      isVisible: isVisible ?? this.isVisible,
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      optimisticRemovedTaskIds:
          optimisticRemovedTaskIds ?? this.optimisticRemovedTaskIds,
      optimisticUpdatedTasks:
          optimisticUpdatedTasks ?? this.optimisticUpdatedTasks,
    );
  }
}
