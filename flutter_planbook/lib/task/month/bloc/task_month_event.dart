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

final class TaskMonthNoteRequested extends TaskMonthEvent {
  const TaskMonthNoteRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class TaskMonthCalendarToggled extends TaskMonthEvent {
  const TaskMonthCalendarToggled();
}
