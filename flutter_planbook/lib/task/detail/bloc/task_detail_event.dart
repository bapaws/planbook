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

final class TaskDetailRecurrenceRuleChanged extends TaskDetailEvent {
  const TaskDetailRecurrenceRuleChanged({this.recurrenceRule});

  final RecurrenceRule? recurrenceRule;

  @override
  List<Object?> get props => [recurrenceRule];
}

final class TaskDetailIsAllDayChanged extends TaskDetailEvent {
  const TaskDetailIsAllDayChanged({required this.isAllDay});

  final bool isAllDay;

  @override
  List<Object?> get props => [isAllDay];
}

final class TaskDetailStartAtChanged extends TaskDetailEvent {
  const TaskDetailStartAtChanged({required this.startAt});

  final Jiffy? startAt;

  @override
  List<Object?> get props => [startAt];
}

final class TaskDetailEndAtChanged extends TaskDetailEvent {
  const TaskDetailEndAtChanged({required this.endAt});

  final Jiffy? endAt;

  @override
  List<Object?> get props => [endAt];
}

final class TaskDetailCompleted extends TaskDetailEvent {
  const TaskDetailCompleted();
}

final class TaskDetailNoteCreated extends TaskDetailEvent {
  const TaskDetailNoteCreated({required this.task, required this.activity});

  final TaskEntity task;
  final TaskActivity activity;

  @override
  List<Object?> get props => [task, activity];
}
