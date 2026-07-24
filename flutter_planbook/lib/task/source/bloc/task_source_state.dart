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
  });

  final TaskSourcePanelType sourceType;
  final String? selectedTagId;
  final Jiffy? sourceDate;
  final Set<String> selectedTagIdsFilter;
  final bool? isCompleted;
  final bool isVisible;
  final PageStatus status;
  final List<TaskEntity> tasks;

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
    );
  }
}
