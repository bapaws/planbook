part of 'task_detail_bloc.dart';

sealed class TaskDetailEvent extends Equatable {
  const TaskDetailEvent();

  @override
  List<Object?> get props => [];
}

final class TaskDetailRequested extends TaskDetailEvent {
  const TaskDetailRequested();
}

final class TaskDetailNotesRequested extends TaskDetailEvent {
  const TaskDetailNotesRequested();
}

final class TaskDetailDeleted extends TaskDetailEvent {
  const TaskDetailDeleted();
}

final class TaskDetailTitleChanged extends TaskDetailEvent {
  const TaskDetailTitleChanged({required this.title});

  final String title;

  @override
  List<Object?> get props => [title];
}

final class TaskDetailDueAtChanged extends TaskDetailEvent {
  const TaskDetailDueAtChanged({required this.dueAt});

  final Jiffy? dueAt;

  @override
  List<Object?> get props => [dueAt];
}

final class TaskDetailPriorityChanged extends TaskDetailEvent {
  const TaskDetailPriorityChanged({required this.priority});

  final TaskPriority priority;

  @override
  List<Object?> get props => [priority];
}

final class TaskDetailTagsChanged extends TaskDetailEvent {
  const TaskDetailTagsChanged({required this.tags});

  final List<TagEntity> tags;

  @override
  List<Object?> get props => [tags];
}
