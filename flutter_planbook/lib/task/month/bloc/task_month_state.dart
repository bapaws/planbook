part of 'task_month_bloc.dart';

final class TaskMonthState extends Equatable {
  const TaskMonthState({
    required this.date,
    this.status = PageStatus.initial,
    this.note,
    this.isCalendarExpanded = false,
    this.weeks = const [],
  });

  final PageStatus status;
  final Jiffy date;

  final List<List<Jiffy?>> weeks;

  final Note? note;
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
  List<Object?> get props => [status, date, note, isCalendarExpanded];

  TaskMonthState copyWith({
    PageStatus? status,
    Jiffy? date,
    List<List<Jiffy?>>? weeks,
    ValueGetter<Note?>? note,
    bool? isCalendarExpanded,
  }) {
    return TaskMonthState(
      status: status ?? this.status,
      date: date ?? this.date,
      weeks: weeks ?? this.weeks,
      note: note != null ? note() : this.note,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
    );
  }
}
