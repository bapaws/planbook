part of 'task_month_bloc.dart';

sealed class TaskMonthEvent extends Equatable {
  const TaskMonthEvent();

  @override
  List<Object> get props => [];
}

final class TaskMonthDateSelected extends TaskMonthEvent {
  const TaskMonthDateSelected({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class TaskMonthFocusNoteRequested extends TaskMonthEvent {
  const TaskMonthFocusNoteRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class TaskMonthSummaryNoteRequested extends TaskMonthEvent {
  const TaskMonthSummaryNoteRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class TaskMonthCalendarToggled extends TaskMonthEvent {
  const TaskMonthCalendarToggled();
}
