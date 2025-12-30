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
    this.isCompleted,
  });

  final Jiffy? date;
  final String? tagId;
  final bool? isCompleted;

  @override
  List<Object?> get props => [date, tagId, isCompleted];
}

final class TaskListDayAllRequested extends TaskListEvent {
  const TaskListDayAllRequested({
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
  const TaskListNoteCreated({required this.activity});

  final TaskActivity activity;

  @override
  List<Object?> get props => [activity];
}

final class TaskListTaskDelayed extends TaskListEvent {
  const TaskListTaskDelayed({
    required this.task,
  });

  final TaskEntity task;

  @override
  List<Object?> get props => [
    task,
  ];
}

final class TaskListTaskExpanded extends TaskListEvent {
  const TaskListTaskExpanded({required this.task});

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}
