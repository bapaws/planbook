import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_metrics.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/task_entity.dart';

/// 时间块上单个任务的预计算布局
final class TaskTimeBlockLayoutItem extends Equatable {
  const TaskTimeBlockLayoutItem({
    required this.task,
    required this.top,
    required this.height,
    required this.startAt,
    required this.endAt,
    required this.timeRangeLabel,
    this.columnCount = 1,
    this.columnIndex = 0,
    this.widthFactor = 1,
  });

  final TaskEntity task;
  final double top;
  final double height;

  /// 展示用起止时间（已裁剪到当天）
  final Jiffy startAt;
  final Jiffy endAt;

  /// 预格式化的时间范围文案，避免 build 时再算
  final String timeRangeLabel;

  final int columnCount;
  final int columnIndex;
  final double widthFactor;

  TaskTimeBlockLayoutItem copyWith({
    int? columnCount,
    int? columnIndex,
    double? widthFactor,
  }) {
    return TaskTimeBlockLayoutItem(
      task: task,
      top: top,
      height: height,
      startAt: startAt,
      endAt: endAt,
      timeRangeLabel: timeRangeLabel,
      columnCount: columnCount ?? this.columnCount,
      columnIndex: columnIndex ?? this.columnIndex,
      widthFactor: widthFactor ?? this.widthFactor,
    );
  }

  @override
  List<Object?> get props => [
    task,
    top,
    height,
    startAt,
    endAt,
    timeRangeLabel,
    columnCount,
    columnIndex,
    widthFactor,
  ];
}

/// 根据任务列表预计算时间块布局（纯函数，供 BLoC 调用）
List<TaskTimeBlockLayoutItem> buildTaskTimeBlockLayoutItems({
  required List<TaskEntity> tasks,
  required Jiffy dayStart,
  required Jiffy dayEnd,
}) {
  final items = <TaskTimeBlockLayoutItem>[];

  for (final task in tasks) {
    if (task.parentId != null) continue;
    if (task.isAllDay || task.startAt == null) continue;

    final start = task.startAt!;
    final end = task.endAt ?? start.add(hours: 1);
    final displayStart = start.isBefore(dayStart) ? dayStart : start;
    var displayEnd = end.isAfter(dayEnd) ? dayEnd : end;
    if (displayEnd.isBefore(displayStart)) {
      displayEnd = displayStart.add(minutes: 15);
    }

    final top =
        displayStart.diff(dayStart, unit: Unit.minute).toDouble() /
        60 *
        TaskTimeBlockMetrics.hourHeight;
    var height =
        displayEnd.diff(dayStart, unit: Unit.minute).toDouble() /
            60 *
            TaskTimeBlockMetrics.hourHeight -
        top;
    if (height < TaskTimeBlockMetrics.minBlockHeight) {
      height = TaskTimeBlockMetrics.minBlockHeight;
    }

    items.add(
      TaskTimeBlockLayoutItem(
        task: task,
        top: top,
        height: height,
        startAt: displayStart,
        endAt: displayEnd,
        timeRangeLabel:
            '${displayStart.toLocal().jm} - ${displayEnd.toLocal().jm}',
      ),
    );
  }

  items.sort((a, b) => a.top.compareTo(b.top));

  // 重叠分组与列分配
  final clusters = <List<TaskTimeBlockLayoutItem>>[];
  for (final item in items) {
    var added = false;
    for (final cluster in clusters) {
      final lastItem = cluster.last;
      if (item.top < lastItem.top + lastItem.height) {
        cluster.add(item);
        added = true;
        break;
      }
    }
    if (!added) {
      clusters.add([item]);
    }
  }

  final result = <TaskTimeBlockLayoutItem>[];
  for (final cluster in clusters) {
    final columns = <List<TaskTimeBlockLayoutItem>>[];
    for (final item in cluster) {
      var placed = false;
      for (final column in columns) {
        final last = column.last;
        if (item.top >= last.top + last.height - 0.001) {
          column.add(item);
          placed = true;
          break;
        }
      }
      if (!placed) {
        columns.add([item]);
      }
    }

    final columnCount = columns.length;
    final columnWidth = 1 / columnCount;
    for (var columnIndex = 0; columnIndex < columns.length; columnIndex++) {
      for (final item in columns[columnIndex]) {
        result.add(
          item.copyWith(
            columnCount: columnCount,
            columnIndex: columnIndex,
            widthFactor: columnWidth,
          ),
        );
      }
    }
  }

  // 保持按 top 排序，便于绘制稳定
  result.sort((a, b) => a.top.compareTo(b.top));
  return result;
}

/// 解析任务时长（分钟）；无效时回退默认时长
///
/// 全天任务（侧栏日期/全天来源）的 endAt 通常是当天结束，
/// 投放时间块时不应保留该跨度，改用默认 1 小时。
int resolveTaskDurationMinutes(TaskEntity task) {
  if (task.isAllDay) {
    return TaskTimeBlockMetrics.defaultDurationMinutes;
  }
  final start = task.startAt;
  final end = task.endAt;
  if (start != null && end != null) {
    final duration = end.diff(start, unit: Unit.minute).toInt();
    if (duration >= TaskTimeBlockMetrics.snapMinutes) return duration;
  }
  return TaskTimeBlockMetrics.defaultDurationMinutes;
}
