part of 'task_today_bloc.dart';

final class TaskTodayState extends Equatable {
  const TaskTodayState({
    required this.date,
    this.calendarFormat = CalendarFormat.week,
    this.taskCounts = const {},
    this.focusNote,
    this.summaryNote,
  });

  final Jiffy date;
  final CalendarFormat calendarFormat;

  final Map<int, int> taskCounts;

  final Note? focusNote;
  final Note? summaryNote;

  @override
  List<Object?> get props => [
    date,
    calendarFormat,
    taskCounts,
    focusNote,
    summaryNote,
  ];

  TaskTodayState copyWith({
    Jiffy? date,
    CalendarFormat? calendarFormat,
    Map<int, int>? taskCounts,
    ValueGetter<Note?>? focusNote,
    ValueGetter<Note?>? summaryNote,
  }) {
    return TaskTodayState(
      date: date ?? this.date,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      taskCounts: taskCounts ?? this.taskCounts,
      focusNote: focusNote != null ? focusNote() : this.focusNote,
      summaryNote: summaryNote != null ? summaryNote() : this.summaryNote,
    );
  }
}
