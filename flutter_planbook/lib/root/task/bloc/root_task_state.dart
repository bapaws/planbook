part of 'root_task_bloc.dart';

enum RootTaskViewType {
  list,
  priority,
}

final class RootTaskState extends Equatable {
  const RootTaskState({
    this.status = PageStatus.initial,
    this.tab = TaskListMode.today,
    this.viewType = RootTaskViewType.list,
    this.showCompleted = false,
    this.tag,
    this.taskCounts = const {},
    this.priorityStyle = TaskPriorityStyle.solidColorBackground,
  });

  final PageStatus status;

  final TaskListMode tab;
  final RootTaskViewType viewType;
  final bool showCompleted;

  final TaskPriorityStyle priorityStyle;

  final TagEntity? tag;

  final Map<TaskListMode, int> taskCounts;

  bool? get isCompleted => showCompleted ? null : false;

  @override
  List<Object?> get props => [
    status,
    tab,
    viewType,
    showCompleted,
    tag,
    taskCounts,
    priorityStyle,
  ];

  RootTaskState copyWith({
    PageStatus? status,
    TaskListMode? tab,
    RootTaskViewType? viewType,
    bool? showCompleted,
    TagEntity? tag,
    Map<TaskListMode, int>? taskCounts,
    TaskPriorityStyle? priorityStyle,
  }) {
    return RootTaskState(
      status: status ?? this.status,
      tab: tab ?? this.tab,
      viewType: viewType ?? this.viewType,
      showCompleted: showCompleted ?? this.showCompleted,
      tag: tag ?? this.tag,
      taskCounts: taskCounts ?? this.taskCounts,
      priorityStyle: priorityStyle ?? this.priorityStyle,
    );
  }
}
