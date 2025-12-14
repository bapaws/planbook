part of 'task_today_bloc.dart';

final class TaskTodayState extends Equatable {
  const TaskTodayState({
    required this.date,
    this.calendarFormat = CalendarFormat.week,
    this.taskCounts = const {},
  });

  final Jiffy date;
  final CalendarFormat calendarFormat;

  final Map<int, int> taskCounts;

  @override
  List<Object> get props => [date, calendarFormat, taskCounts];

  TaskTodayState copyWith({
    Jiffy? date,
    CalendarFormat? calendarFormat,
    Map<int, int>? taskCounts,
  }) {
    return TaskTodayState(
      date: date ?? this.date,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      taskCounts: taskCounts ?? this.taskCounts,
    );
  }
}
