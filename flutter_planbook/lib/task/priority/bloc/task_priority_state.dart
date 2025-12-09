part of 'task_priority_bloc.dart';

final class TaskPriorityState extends Equatable {
  const TaskPriorityState({
    this.date,
    this.status = PageStatus.initial,
    this.tasks = const [],
    this.tag,
    this.currentTaskNote,
  });

  final PageStatus status;

  final Jiffy? date;
  final TagEntity? tag;
  final List<TaskEntity> tasks;

  final NoteEntity? currentTaskNote;

  @override
  List<Object?> get props => [status, date, tag, tasks, currentTaskNote];

  TaskPriorityState copyWith({
    PageStatus? status,
    Jiffy? date,
    TagEntity? tag,
    List<TaskEntity>? tasks,
    NoteEntity? currentTaskNote,
  }) {
    return TaskPriorityState(
      status: status ?? this.status,
      date: date ?? this.date,
      tag: tag ?? this.tag,
      tasks: tasks ?? this.tasks,
      currentTaskNote: currentTaskNote ?? this.currentTaskNote,
    );
  }
}
