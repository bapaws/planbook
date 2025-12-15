part of 'task_list_bloc.dart';

final class TaskListState extends Equatable {
  const TaskListState({
    this.date,
    this.status = PageStatus.initial,
    this.tasks = const [],
    this.tag,
    this.currentTaskNote,
    this.priorityStyle = TaskPriorityStyle.solidColorBackground,
  });

  final PageStatus status;

  final Jiffy? date;
  final TagEntity? tag;
  final List<TaskEntity> tasks;

  final TaskPriorityStyle priorityStyle;
  final NoteEntity? currentTaskNote;

  @override
  List<Object?> get props => [
    status,
    date,
    tag,
    tasks,
    currentTaskNote,
    priorityStyle,
  ];

  TaskListState copyWith({
    PageStatus? status,
    Jiffy? date,
    TagEntity? tag,
    List<TaskEntity>? tasks,
    NoteEntity? currentTaskNote,
    TaskPriorityStyle? priorityStyle,
  }) {
    return TaskListState(
      status: status ?? this.status,
      date: date ?? this.date,
      tag: tag ?? this.tag,
      tasks: tasks ?? this.tasks,
      currentTaskNote: currentTaskNote ?? this.currentTaskNote,
      priorityStyle: priorityStyle ?? this.priorityStyle,
    );
  }
}
