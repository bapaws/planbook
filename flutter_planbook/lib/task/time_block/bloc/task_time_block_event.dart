part of 'task_time_block_bloc.dart';

sealed class TaskTimeBlockEvent extends Equatable {
  const TaskTimeBlockEvent();

  @override
  List<Object?> get props => [];
}

/// 启动分钟时钟（emit.forEach）
final class TaskTimeBlockStarted extends TaskTimeBlockEvent {
  const TaskTimeBlockStarted();
}

/// 由页面 BlocListener 转发 TaskList 任务并重算布局
final class TaskTimeBlockTasksUpdated extends TaskTimeBlockEvent {
  const TaskTimeBlockTasksUpdated(this.tasks);

  final List<TaskEntity> tasks;

  @override
  List<Object?> get props => [tasks];
}

/// 拖拽 / 调时长过程中的落点预览
final class TaskTimeBlockHoverUpdated extends TaskTimeBlockEvent {
  const TaskTimeBlockHoverUpdated(this.minutes);

  final int minutes;

  @override
  List<Object?> get props => [minutes];
}

final class TaskTimeBlockHoverCleared extends TaskTimeBlockEvent {
  const TaskTimeBlockHoverCleared();
}
