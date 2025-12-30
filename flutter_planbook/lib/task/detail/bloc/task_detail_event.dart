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

final class TaskDetailRecurrenceRuleChanged extends TaskDetailEvent {
  const TaskDetailRecurrenceRuleChanged({this.recurrenceRule});

  final RecurrenceRule? recurrenceRule;

  @override
  List<Object?> get props => [recurrenceRule];
}

final class TaskDetailDurationChanged extends TaskDetailEvent {
  const TaskDetailDurationChanged({this.entity});

  final TaskDurationEntity? entity;

  @override
  List<Object?> get props => [entity];
}

final class TaskDetailCompleted extends TaskDetailEvent {
  const TaskDetailCompleted({this.task});

  final TaskEntity? task;

  @override
  List<Object?> get props => [task];
}

final class TaskDetailNoteCreated extends TaskDetailEvent {
  const TaskDetailNoteCreated({required this.activity});

  final TaskActivity activity;

  @override
  List<Object?> get props => [activity];
}

final class TaskDetailNoteDeleted extends TaskDetailEvent {
  const TaskDetailNoteDeleted({required this.noteId});

  final String noteId;

  @override
  List<Object?> get props => [noteId];
}

final class TaskDetailChildrenChanged extends TaskDetailEvent {
  const TaskDetailChildrenChanged({required this.children});

  final List<TaskEntity> children;

  @override
  List<Object?> get props => [children];
}

final class TaskDetailEditModeSelected extends TaskDetailEvent {
  const TaskDetailEditModeSelected({this.mode});

  final RecurringTaskEditMode? mode;

  @override
  List<Object?> get props => [mode];
}

final class TaskDetailUpdated extends TaskDetailEvent {
  const TaskDetailUpdated({this.task, this.tags, this.children});

  final Task? task;
  final List<TagEntity>? tags;
  final List<TaskEntity>? children;

  @override
  List<Object?> get props => [task, tags, children];
}
