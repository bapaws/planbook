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

final class TaskWeekNoteRequested extends TaskWeekEvent {
  const TaskWeekNoteRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class TaskWeekCalendarToggled extends TaskWeekEvent {
  const TaskWeekCalendarToggled();
}
