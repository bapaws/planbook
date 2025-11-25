part of 'task_today_cubit.dart';

final class TaskTodayState extends Equatable {
  const TaskTodayState({
    required this.date,
    this.calendarFormat = CalendarFormat.week,
  });

  final Jiffy date;
  final CalendarFormat calendarFormat;

  @override
  List<Object> get props => [date, calendarFormat];

  TaskTodayState copyWith({
    Jiffy? date,
    CalendarFormat? calendarFormat,
  }) {
    return TaskTodayState(
      date: date ?? this.date,
      calendarFormat: calendarFormat ?? this.calendarFormat,
    );
  }
}
