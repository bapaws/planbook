part of 'task_week_bloc.dart';

sealed class TaskWeekEvent extends Equatable {
  const TaskWeekEvent();

  @override
  List<Object> get props => [];
}

final class TaskWeekDateSelected extends TaskWeekEvent {
  const TaskWeekDateSelected({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class TaskWeekFocusNoteRequested extends TaskWeekEvent {
  const TaskWeekFocusNoteRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class TaskWeekSummaryNoteRequested extends TaskWeekEvent {
  const TaskWeekSummaryNoteRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class TaskWeekCalendarToggled extends TaskWeekEvent {
  const TaskWeekCalendarToggled();
}
