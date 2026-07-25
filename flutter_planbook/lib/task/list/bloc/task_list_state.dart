part of 'task_list_bloc.dart';

final class TaskListState extends Equatable {
  const TaskListState({
    this.date,
    this.status = PageStatus.initial,
    this.tasks = const [],
    this.uncompletedTaskCount = 0,
    this.currentTaskNote,
    this.priorityStyle = TaskPriorityStyle.solidColorBackground,
    this.expandedTaskIds = const {},
    this.showDeleteModeSelection = false,
    this.showDeleteConfirmation = false,
    this.pendingDeleteTask,
    this.isCompleted,
    this.optimisticRemovedTaskIds = const {},
    this.optimisticUpdatedTasks = const [],
  });

  final PageStatus status;

  final Jiffy? date;
  final List<TaskEntity> tasks;

  final int uncompletedTaskCount;

  final Set<String> expandedTaskIds;

  final TaskPriorityStyle priorityStyle;
  final NoteEntity? currentTaskNote;

  final bool showDeleteModeSelection;
  final bool showDeleteConfirmation;
  final TaskEntity? pendingDeleteTask;

  final bool? isCompleted;

  /// 乐观移除的任务 ID；用于在 stream 尚未反映变更前保持任务不可见。
  final Set<String> optimisticRemovedTaskIds;

  /// 乐观更新的任务；用于在 stream 尚未反映变更前覆盖旧数据。
  final List<TaskEntity> optimisticUpdatedTasks;

  @override
  List<Object?> get props => [
    status,
    date,
    tasks,
    uncompletedTaskCount,
    currentTaskNote,
    priorityStyle,
    expandedTaskIds,
    showDeleteModeSelection,
    showDeleteConfirmation,
    pendingDeleteTask,
    isCompleted,
    optimisticRemovedTaskIds,
    optimisticUpdatedTasks,
  ];

  TaskListState copyWith({
    PageStatus? status,
    Jiffy? date,
    List<TaskEntity>? tasks,
    int? uncompletedTaskCount,
    NoteEntity? currentTaskNote,
    TaskPriorityStyle? priorityStyle,
    Set<String>? expandedTaskIds,
    bool? showDeleteModeSelection,
    bool? showDeleteConfirmation,
    ValueGetter<TaskEntity?>? pendingDeleteTask,
    ValueGetter<bool?>? isCompleted,
    Set<String>? optimisticRemovedTaskIds,
    List<TaskEntity>? optimisticUpdatedTasks,
  }) {
    return TaskListState(
      status: status ?? this.status,
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
      uncompletedTaskCount: uncompletedTaskCount ?? this.uncompletedTaskCount,
      currentTaskNote: currentTaskNote ?? this.currentTaskNote,
      priorityStyle: priorityStyle ?? this.priorityStyle,
      expandedTaskIds: expandedTaskIds ?? this.expandedTaskIds,
      showDeleteModeSelection:
          showDeleteModeSelection ?? this.showDeleteModeSelection,
      showDeleteConfirmation:
          showDeleteConfirmation ?? this.showDeleteConfirmation,
      pendingDeleteTask: pendingDeleteTask == null
          ? this.pendingDeleteTask
          : pendingDeleteTask(),
      isCompleted: isCompleted == null ? this.isCompleted : isCompleted(),
      optimisticRemovedTaskIds:
          optimisticRemovedTaskIds ?? this.optimisticRemovedTaskIds,
      optimisticUpdatedTasks:
          optimisticUpdatedTasks ?? this.optimisticUpdatedTasks,
    );
  }
}
