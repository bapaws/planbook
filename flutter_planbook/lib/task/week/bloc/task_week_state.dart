part of 'task_week_bloc.dart';

final class TaskWeekState extends Equatable {
  const TaskWeekState({
    required this.date,
    this.status = PageStatus.initial,
    this.focusNote,
    this.summaryNote,
    this.isCalendarExpanded = false,
  });

  final PageStatus status;
  final Jiffy date;

  final Note? focusNote;
  final Note? summaryNote;
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
    isCalendarExpanded,
  ];

  TaskWeekState copyWith({
    PageStatus? status,
    Jiffy? date,
    ValueGetter<Note?>? focusNote,
    ValueGetter<Note?>? summaryNote,
    bool? isCalendarExpanded,
  }) {
    return TaskWeekState(
      status: status ?? this.status,
      date: date ?? this.date,
      focusNote: focusNote != null ? focusNote() : this.focusNote,
      summaryNote: summaryNote != null ? summaryNote() : this.summaryNote,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
    );
  }
}
