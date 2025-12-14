part of 'task_inbox_bloc.dart';

sealed class TaskInboxEvent extends Equatable {
  const TaskInboxEvent();

  @override
  List<Object?> get props => [];
}

final class TaskInboxRequested extends TaskInboxEvent {
  const TaskInboxRequested({this.isCompleted});

  final bool? isCompleted;

  @override
  List<Object?> get props => [isCompleted];
}
