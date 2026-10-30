part of 'task_week_bloc.dart';

final class TaskWeekState extends Equatable {
  const TaskWeekState({
    required this.date,
    this.status = PageStatus.initial,
    this.focusNote,
    this.summaryNote,
    this.isFocusNoteReady = false,
    this.isSummaryNoteReady = false,
    this.isCalendarExpanded = false,
  });

  final PageStatus status;
  final Jiffy date;

  final Note? focusNote;
  final Note? summaryNote;
  final bool isFocusNoteReady;
  final bool isSummaryNoteReady;

  PeriodNoteSnapshot noteSnapshot(NoteType type) => PeriodNoteSnapshot(
    target: PeriodNoteTarget(date: date, type: type),
    note: type.isFocus ? focusNote : summaryNote,
    isReady: type.isFocus ? isFocusNoteReady : isSummaryNoteReady,
  );
  final bool isCalendarExpanded;

  /// 获取一周的日期列表（从周一到周日）
  List<Jiffy> get weekDays {
    final startOfWeek = date.startOf(Unit.week);
    return List.generate(7, (index) => startOfWeek.add(days: index));
  }

  @override
  List<Object?> get props => [
    status,
    date,
    focusNote,
    summaryNote,
    isFocusNoteReady,
    isSummaryNoteReady,
    isCalendarExpanded,
  ];

  TaskWeekState copyWith({
    PageStatus? status,
    Jiffy? date,
    ValueGetter<Note?>? focusNote,
    ValueGetter<Note?>? summaryNote,
    bool? isFocusNoteReady,
    bool? isSummaryNoteReady,
    bool? isCalendarExpanded,
  }) {
    return TaskWeekState(
      status: status ?? this.status,
      date: date ?? this.date,
      focusNote: focusNote != null ? focusNote() : this.focusNote,
      summaryNote: summaryNote != null ? summaryNote() : this.summaryNote,
      isFocusNoteReady: isFocusNoteReady ?? this.isFocusNoteReady,
      isSummaryNoteReady: isSummaryNoteReady ?? this.isSummaryNoteReady,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
    );
  }
}
