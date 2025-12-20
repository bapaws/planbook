part of 'task_week_bloc.dart';

final class TaskWeekState extends Equatable {
  const TaskWeekState({
    required this.date,
    this.status = PageStatus.initial,
    this.note,
    this.isCalendarExpanded = false,
  });

  final PageStatus status;
  final Jiffy date;

  final Note? note;
  final bool isCalendarExpanded;

  /// 获取一周的日期列表（从周一到周日）
  List<Jiffy> get weekDays {
    final startOfWeek = date.startOf(Unit.week);
    return List.generate(7, (index) => startOfWeek.add(days: index));
  }

  @override
  List<Object?> get props => [status, date, note, isCalendarExpanded];

  TaskWeekState copyWith({
    PageStatus? status,
    Jiffy? date,
    ValueGetter<Note?>? note,
    bool? isCalendarExpanded,
  }) {
    return TaskWeekState(
      status: status ?? this.status,
      date: date ?? this.date,
      note: note != null ? note() : this.note,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
    );
  }
}
