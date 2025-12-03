part of 'task_priority_bloc.dart';

sealed class TaskPriorityEvent extends Equatable {
  const TaskPriorityEvent();

  @override
  List<Object?> get props => [];
}

final class TaskPriorityRequested extends TaskPriorityEvent {
  const TaskPriorityRequested({
    required this.priority,
    this.date,
    this.tagId,
    this.isCompleted,
  });

  final Jiffy? date;
  final String? tagId;
  final TaskPriority priority;
  final bool? isCompleted;

  @override
  List<Object?> get props => [date, tagId, priority, isCompleted];
}

final class TaskPriorityCompleted extends TaskPriorityEvent {
  const TaskPriorityCompleted({required this.task});

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

final class TaskPriorityDeleted extends TaskPriorityEvent {
  const TaskPriorityDeleted({required this.taskId});

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

final class TaskPriorityNoteCreated extends TaskPriorityEvent {
  const TaskPriorityNoteCreated({required this.task});

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}
