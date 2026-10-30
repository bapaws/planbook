part of 'task_today_bloc.dart';

final class TaskTodayState extends Equatable {
  const TaskTodayState({
    required this.date,
    this.calendarFormat = CalendarFormat.week,
    this.taskCounts = const {},
    this.focusNote,
    this.summaryNote,
    this.isFocusNoteReady = false,
    this.isSummaryNoteReady = false,
  });

  final Jiffy date;
  final CalendarFormat calendarFormat;

  final Map<int, int> taskCounts;

  final Note? focusNote;
  final Note? summaryNote;
  final bool isFocusNoteReady;
  final bool isSummaryNoteReady;

  PeriodNoteSnapshot noteSnapshot(NoteType type) => PeriodNoteSnapshot(
    target: PeriodNoteTarget(date: date, type: type),
    note: type.isFocus ? focusNote : summaryNote,
    isReady: type.isFocus ? isFocusNoteReady : isSummaryNoteReady,
  );

  @override
  List<Object?> get props => [
    date,
    calendarFormat,
    taskCounts,
    focusNote,
    summaryNote,
    isFocusNoteReady,
    isSummaryNoteReady,
  ];

  TaskTodayState copyWith({
    Jiffy? date,
    CalendarFormat? calendarFormat,
    Map<int, int>? taskCounts,
    ValueGetter<Note?>? focusNote,
    ValueGetter<Note?>? summaryNote,
    bool? isFocusNoteReady,
    bool? isSummaryNoteReady,
  }) {
    return TaskTodayState(
      date: date ?? this.date,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      taskCounts: taskCounts ?? this.taskCounts,
      focusNote: focusNote != null ? focusNote() : this.focusNote,
      summaryNote: summaryNote != null ? summaryNote() : this.summaryNote,
      isFocusNoteReady: isFocusNoteReady ?? this.isFocusNoteReady,
      isSummaryNoteReady: isSummaryNoteReady ?? this.isSummaryNoteReady,
    );
  }
}
