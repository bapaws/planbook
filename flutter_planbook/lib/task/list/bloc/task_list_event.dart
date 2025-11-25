part of 'task_list_bloc.dart';

sealed class TaskListEvent extends Equatable {
  const TaskListEvent();

  @override
  List<Object?> get props => [];
}

final class TaskListRequested extends TaskListEvent {
  const TaskListRequested({this.date, this.tagId, this.priority});

  final Jiffy? date;
  final String? tagId;
  final TaskPriority? priority;

  @override
  List<Object?> get props => [date, tagId, priority];
}

final class TaskListCompleted extends TaskListEvent {
  const TaskListCompleted({required this.taskId});

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

final class TaskListDeleted extends TaskListEvent {
  const TaskListDeleted({required this.taskId});

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}
