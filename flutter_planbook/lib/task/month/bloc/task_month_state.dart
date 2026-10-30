part of 'task_month_bloc.dart';

final class TaskMonthState extends Equatable {
  const TaskMonthState({
    required this.date,
    this.noteType = NoteType.monthlyFocus,
    this.status = PageStatus.initial,
    this.focusNote,
    this.summaryNote,
    this.isFocusNoteReady = false,
    this.isSummaryNoteReady = false,
    this.isCalendarExpanded = false,
    this.weeks = const [],
  });

  final PageStatus status;
  final Jiffy date;

  final List<List<Jiffy?>> weeks;

  final NoteType noteType;
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

  /// 获取当月的所有日期列表
  List<Jiffy> get monthDays {
    final startOfMonth = date.startOf(Unit.month);
    final daysInMonth = date.daysInMonth;
    return List.generate(daysInMonth, (index) => startOfMonth.add(days: index));
  }

  /// 获取当月的周数
  int get weeksInMonth {
    final firstDay = date.startOf(Unit.month);
    final lastDay = date.endOf(Unit.month);
    final firstWeekNumber = firstDay.weekOfYear;
    final lastWeekNumber = lastDay.weekOfYear;

    // 处理跨年情况
    if (lastWeekNumber < firstWeekNumber) {
      // 12月末可能是下一年的第1周
      return (52 - firstWeekNumber + 1) + lastWeekNumber;
    }
    return lastWeekNumber - firstWeekNumber + 1;
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
    noteType,
  ];

  TaskMonthState copyWith({
    PageStatus? status,
    Jiffy? date,
    List<List<Jiffy?>>? weeks,
    ValueGetter<Note?>? focusNote,
    ValueGetter<Note?>? summaryNote,
    bool? isFocusNoteReady,
    bool? isSummaryNoteReady,
    bool? isCalendarExpanded,
    NoteType? noteType,
  }) {
    return TaskMonthState(
      status: status ?? this.status,
      date: date ?? this.date,
      weeks: weeks ?? this.weeks,
      focusNote: focusNote != null ? focusNote() : this.focusNote,
      summaryNote: summaryNote != null ? summaryNote() : this.summaryNote,
      isFocusNoteReady: isFocusNoteReady ?? this.isFocusNoteReady,
      isSummaryNoteReady: isSummaryNoteReady ?? this.isSummaryNoteReady,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
      noteType: noteType ?? this.noteType,
    );
  }
}
