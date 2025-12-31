part of 'root_task_bloc.dart';

enum RootTaskViewType {
  list,
  priority,
}

final class RootTaskState extends Equatable {
  const RootTaskState({
    this.status = PageStatus.initial,
    this.tab = RootTaskTab.day,
    this.viewType = RootTaskViewType.list,
    this.showCompleted = false,
    this.tag,
    this.taskCounts = const {},
    this.dailyTaskCounts = const {},
    this.priorityStyle = TaskPriorityStyle.solidColorBackground,
  });

  final PageStatus status;

  final RootTaskTab tab;
  final RootTaskViewType viewType;
  final bool showCompleted;

  final TaskPriorityStyle priorityStyle;

  final TagEntity? tag;

  final Map<TaskListMode, int> taskCounts;

  final Map<int, int> dailyTaskCounts;

  bool? get isCompleted => showCompleted ? null : false;

  @override
  List<Object?> get props => [
    status,
    tab,
    viewType,
    showCompleted,
    tag,
    taskCounts,
    dailyTaskCounts,
    priorityStyle,
  ];

  RootTaskState copyWith({
    PageStatus? status,
    RootTaskTab? tab,
    RootTaskViewType? viewType,
    bool? showCompleted,
    TagEntity? tag,
    Map<TaskListMode, int>? taskCounts,
    Map<int, int>? dailyTaskCounts,
    TaskPriorityStyle? priorityStyle,
  }) {
    return RootTaskState(
      status: status ?? this.status,
      tab: tab ?? this.tab,
      viewType: viewType ?? this.viewType,
      showCompleted: showCompleted ?? this.showCompleted,
      tag: tag ?? this.tag,
      taskCounts: taskCounts ?? this.taskCounts,
      dailyTaskCounts: dailyTaskCounts ?? this.dailyTaskCounts,
      priorityStyle: priorityStyle ?? this.priorityStyle,
    );
  }
}
