part of 'task_source_bloc.dart';

sealed class TaskSourcePanelEvent extends Equatable {
  const TaskSourcePanelEvent();

  @override
  List<Object?> get props => [];
}

/// 加载右侧任务列
final class TaskSourcePanelLoaded extends TaskSourcePanelEvent {
  const TaskSourcePanelLoaded({
    this.isCompleted,
    this.selectedTagIds = const {},
  });

  final bool? isCompleted;
  final Set<String> selectedTagIds;

  @override
  List<Object?> get props => [isCompleted, selectedTagIds];
}

/// 切换数据源类型
final class TaskSourcePanelSourceChanged extends TaskSourcePanelEvent {
  const TaskSourcePanelSourceChanged(this.sourceType);

  final TaskSourcePanelType sourceType;

  @override
  List<Object?> get props => [sourceType];
}

/// 显示或隐藏右侧任务列
final class TaskSourcePanelVisibilityChanged extends TaskSourcePanelEvent {
  const TaskSourcePanelVisibilityChanged({required this.isVisible});

  final bool isVisible;

  @override
  List<Object?> get props => [isVisible];
}

/// 切换标签
final class TaskSourcePanelTagChanged extends TaskSourcePanelEvent {
  const TaskSourcePanelTagChanged(this.tagId);

  final String tagId;

  @override
  List<Object?> get props => [tagId];
}

/// 切换日期
final class TaskSourcePanelDateChanged extends TaskSourcePanelEvent {
  const TaskSourcePanelDateChanged(this.date);

  final Jiffy date;

  @override
  List<Object?> get props => [date];
}

/// 全局筛选变化
final class TaskSourcePanelFilterChanged extends TaskSourcePanelEvent {
  const TaskSourcePanelFilterChanged({
    this.isCompleted,
    this.selectedTagIds = const {},
  });

  final bool? isCompleted;
  final Set<String> selectedTagIds;

  @override
  List<Object?> get props => [isCompleted, selectedTagIds];
}

/// 按当前 sourceType / 筛选条件重新订阅任务流（唯一 emit.forEach 入口）
final class TaskSourcePanelTasksSubscriptionRequested
    extends TaskSourcePanelEvent {
  const TaskSourcePanelTasksSubscriptionRequested();
}

/// 从主视图拖入任务
final class TaskSourcePanelTaskDropped extends TaskSourcePanelEvent {
  const TaskSourcePanelTaskDropped(this.task);

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

/// 拖拽被接受后，Source Panel 同步移除任务。
final class TaskSourcePanelTaskDragCompleted extends TaskSourcePanelEvent {
  const TaskSourcePanelTaskDragCompleted(this.task);

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}
