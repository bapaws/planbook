import 'package:equatable/equatable.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/tag_entity.dart';

/// 右侧任务列的数据源类型
sealed class TaskSourcePanelType extends Equatable {
  const TaskSourcePanelType();

  @override
  List<Object?> get props => [];
}

/// 收集箱数据源
final class TaskSourcePanelInbox extends TaskSourcePanelType {
  const TaskSourcePanelInbox();
}

/// 指定标签数据源（可多选）
final class TaskSourcePanelTag extends TaskSourcePanelType {
  const TaskSourcePanelTag(this.tags);

  final List<TagEntity> tags;

  @override
  List<Object?> get props => [tags];
}

/// 指定日期任务的显示范围
enum TaskSourcePanelDateFilter {
  /// 当天全部任务
  all,

  /// 仅全天任务
  allDay,

  /// 仅非全天（有具体时间）任务
  notAllDay,
}

/// 指定日期数据源
final class TaskSourcePanelDate extends TaskSourcePanelType {
  const TaskSourcePanelDate(
    this.date, {
    this.filter = TaskSourcePanelDateFilter.all,
  });

  final Jiffy date;

  /// 日期下的任务过滤范围
  final TaskSourcePanelDateFilter filter;

  @override
  List<Object?> get props => [date, filter];
}

/// 用于切换控件的占位数据源，不携带具体标签/日期
enum TaskSourcePanelTab {
  inbox,
  tag,
  date,
  hide,
}
