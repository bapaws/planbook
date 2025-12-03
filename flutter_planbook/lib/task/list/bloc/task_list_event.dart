part of 'task_list_bloc.dart';

sealed class TaskListEvent extends Equatable {
  const TaskListEvent();

  @override
  List<Object?> get props => [];
}

final class TaskListRequested extends TaskListEvent {
  const TaskListRequested({
    this.date,
    this.tagId,
    this.priority,
    this.isCompleted,
  });

  final Jiffy? date;
  final String? tagId;
  final TaskPriority? priority;
  final bool? isCompleted;

  @override
  List<Object?> get props => [date, tagId, priority, isCompleted];
}

final class TaskListCompleted extends TaskListEvent {
  const TaskListCompleted({required this.task});

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

final class TaskListDeleted extends TaskListEvent {
  const TaskListDeleted({required this.taskId});

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

final class TaskListNoteCreated extends TaskListEvent {
  const TaskListNoteCreated({required this.task});

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}
