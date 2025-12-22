part of 'task_today_bloc.dart';

final class TaskTodayState extends Equatable {
  const TaskTodayState({
    required this.date,
    this.calendarFormat = CalendarFormat.week,
    this.taskCounts = const {},
    this.focusNote,
  });

  final Jiffy date;
  final CalendarFormat calendarFormat;

  final Map<int, int> taskCounts;

  final Note? focusNote;

  @override
  List<Object?> get props => [date, calendarFormat, taskCounts, focusNote];

  TaskTodayState copyWith({
    Jiffy? date,
    CalendarFormat? calendarFormat,
    Map<int, int>? taskCounts,
    ValueGetter<Note?>? focusNote,
  }) {
    return TaskTodayState(
      date: date ?? this.date,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      taskCounts: taskCounts ?? this.taskCounts,
      focusNote: focusNote != null ? focusNote() : this.focusNote,
    );
  }
}
