part of 'task_time_block_bloc.dart';

final class TaskTimeBlockState extends Equatable {
  const TaskTimeBlockState({
    required this.date,
    required this.dayStart,
    required this.dayEnd,
    this.status = PageStatus.loading,
    this.items = const [],
    this.hoverMinutes,
    this.hoverLabel,
    this.currentTimeMinutes,
    this.currentTimeLabel,
    this.currentTimeTop,
  });

  factory TaskTimeBlockState.initial({required Jiffy date}) {
    final dayStart = date.startOf(Unit.day);
    final now = Jiffy.now();
    final isToday = now.isSame(dayStart, unit: Unit.day);
    final currentMinutes = isToday
        ? now.diff(dayStart, unit: Unit.minute).toInt()
        : null;
    return TaskTimeBlockState(
      date: date,
      dayStart: dayStart,
      dayEnd: date.endOf(Unit.day),
      currentTimeMinutes: currentMinutes,
      currentTimeLabel: currentMinutes == null
          ? null
          : TaskTimeBlockMetrics.formatMinutes(
              now.hour * 60 + now.minute,
            ),
      currentTimeTop: currentMinutes == null
          ? null
          : TaskTimeBlockMetrics.topFromMinutes(currentMinutes),
    );
  }

  final Jiffy date;
  final Jiffy dayStart;
  final Jiffy dayEnd;
  final PageStatus status;

  /// 预计算好的任务块布局
  final List<TaskTimeBlockLayoutItem> items;

  /// 拖拽预览分钟数；null 表示无预览
  final int? hoverMinutes;
  final String? hoverLabel;

  /// 当前时间（仅当天有值）
  final int? currentTimeMinutes;
  final String? currentTimeLabel;
  final double? currentTimeTop;

  @override
  List<Object?> get props => [
    date,
    dayStart,
    dayEnd,
    status,
    items,
    hoverMinutes,
    hoverLabel,
    currentTimeMinutes,
    currentTimeLabel,
    currentTimeTop,
  ];

  TaskTimeBlockState copyWith({
    Jiffy? date,
    Jiffy? dayStart,
    Jiffy? dayEnd,
    PageStatus? status,
    List<TaskTimeBlockLayoutItem>? items,
    ValueGetter<int?>? hoverMinutes,
    ValueGetter<String?>? hoverLabel,
    ValueGetter<int?>? currentTimeMinutes,
    ValueGetter<String?>? currentTimeLabel,
    ValueGetter<double?>? currentTimeTop,
  }) {
    return TaskTimeBlockState(
      date: date ?? this.date,
      dayStart: dayStart ?? this.dayStart,
      dayEnd: dayEnd ?? this.dayEnd,
      status: status ?? this.status,
      items: items ?? this.items,
      hoverMinutes: hoverMinutes != null ? hoverMinutes() : this.hoverMinutes,
      hoverLabel: hoverLabel != null ? hoverLabel() : this.hoverLabel,
      currentTimeMinutes: currentTimeMinutes != null
          ? currentTimeMinutes()
          : this.currentTimeMinutes,
      currentTimeLabel: currentTimeLabel != null
          ? currentTimeLabel()
          : this.currentTimeLabel,
      currentTimeTop: currentTimeTop != null
          ? currentTimeTop()
          : this.currentTimeTop,
    );
  }
}
