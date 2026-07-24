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

/// 指定日期数据源
final class TaskSourcePanelDate extends TaskSourcePanelType {
  const TaskSourcePanelDate(this.date);

  final Jiffy date;

  @override
  List<Object?> get props => [date];
}

/// 指定日期的全天任务数据源（由时间块「全部」入口切换）
final class TaskSourcePanelAllDay extends TaskSourcePanelType {
  const TaskSourcePanelAllDay(this.date);

  final Jiffy date;

  @override
  List<Object?> get props => [date];
}

/// 用于切换控件的占位数据源，不携带具体标签/日期
enum TaskSourcePanelTab {
  inbox,
  tag,
  date,
  hide,
}
