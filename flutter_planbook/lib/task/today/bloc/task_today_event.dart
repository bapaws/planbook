part of 'task_today_bloc.dart';

sealed class TaskTodayEvent extends Equatable {
  const TaskTodayEvent();

  @override
  List<Object?> get props => [];
}

final class TaskTodayDateSelected extends TaskTodayEvent {
  const TaskTodayDateSelected({required this.date, this.isCompleted});

  final Jiffy date;
  final bool? isCompleted;

  @override
  List<Object?> get props => [date, isCompleted];
}

final class TaskTodayCalendarFormatChanged extends TaskTodayEvent {
  const TaskTodayCalendarFormatChanged({required this.calendarFormat});

  final CalendarFormat calendarFormat;

  @override
  List<Object?> get props => [calendarFormat];
}
