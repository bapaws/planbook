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
  });

  final PageStatus status;

  final Jiffy? date;
  final List<TaskEntity> tasks;

  final int uncompletedTaskCount;

  final Set<String> expandedTaskIds;

  final TaskPriorityStyle priorityStyle;
  final NoteEntity? currentTaskNote;

  @override
  List<Object?> get props => [
    status,
    date,
    tasks,
    uncompletedTaskCount,
    currentTaskNote,
    priorityStyle,
    expandedTaskIds,
  ];

  TaskListState copyWith({
    PageStatus? status,
    Jiffy? date,
    List<TaskEntity>? tasks,
    int? uncompletedTaskCount,
    NoteEntity? currentTaskNote,
    TaskPriorityStyle? priorityStyle,
    Set<String>? expandedTaskIds,
  }) {
    return TaskListState(
      status: status ?? this.status,
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
      uncompletedTaskCount: uncompletedTaskCount ?? this.uncompletedTaskCount,
      currentTaskNote: currentTaskNote ?? this.currentTaskNote,
      priorityStyle: priorityStyle ?? this.priorityStyle,
      expandedTaskIds: expandedTaskIds ?? this.expandedTaskIds,
    );
  }
}
