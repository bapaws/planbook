part of 'task_list_bloc.dart';

final class TaskListState extends Equatable {
  const TaskListState({
    this.date,
    this.status = PageStatus.initial,
    this.tasks = const [],
    this.tag,
  });

  final PageStatus status;

  final Jiffy? date;
  final TagEntity? tag;
  final List<TaskEntity> tasks;

  @override
  List<Object?> get props => [status, date, tag, tasks];

  TaskListState copyWith({
    PageStatus? status,
    Jiffy? date,
    TagEntity? tag,
    List<TaskEntity>? tasks,
  }) {
    return TaskListState(
      status: status ?? this.status,
      date: date ?? this.date,
      tag: tag ?? this.tag,
      tasks: tasks ?? this.tasks,
    );
  }
}
