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
    );
  }
}
