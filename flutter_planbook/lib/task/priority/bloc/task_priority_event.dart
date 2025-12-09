part of 'task_priority_bloc.dart';

sealed class TaskPriorityEvent extends Equatable {
  const TaskPriorityEvent();

  @override
  List<Object?> get props => [];
}

final class TaskPriorityRequested extends TaskPriorityEvent {
  const TaskPriorityRequested({
    this.date,
    this.tagId,
    this.isCompleted,
  });

  final Jiffy? date;
  final String? tagId;

  final bool? isCompleted;

  @override
  List<Object?> get props => [date, tagId, isCompleted];
}

final class TaskPriorityCompleted extends TaskPriorityEvent {
  const TaskPriorityCompleted({required this.task, this.occurrenceAt});

  final TaskEntity task;
  final Jiffy? occurrenceAt;

  @override
  List<Object?> get props => [task, occurrenceAt];
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
