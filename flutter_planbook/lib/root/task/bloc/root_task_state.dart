part of 'root_task_bloc.dart';

enum RootTaskViewType {
  list,
  priority,
}

final class RootTaskState extends Equatable {
  const RootTaskState({
    this.status = PageStatus.initial,
    this.viewType = RootTaskViewType.list,
    this.showCompleted = false,
    this.tag,
    this.taskCounts = const {},
    this.dailyTaskCounts = const {},
    this.priorityStyle = TaskPriorityStyle.solidColorBackground,
    this.tabFocusNoteTypes = const {
      RootTaskTab.day: NoteType.dailyFocus,
      RootTaskTab.week: NoteType.weeklyFocus,
      RootTaskTab.month: NoteType.monthlyFocus,
    },
  });

  final PageStatus status;

  final RootTaskViewType viewType;
  final bool showCompleted;

  final TaskPriorityStyle priorityStyle;

  final TagEntity? tag;

  final Map<TaskListMode, int> taskCounts;

  final Map<int, int> dailyTaskCounts;

  final Map<RootTaskTab, NoteType?> tabFocusNoteTypes;

  bool? get isCompleted => showCompleted ? null : false;

  @override
  List<Object?> get props => [
    status,
    viewType,
    showCompleted,
    tag,
    taskCounts,
    dailyTaskCounts,
    priorityStyle,
    tabFocusNoteTypes,
  ];

  RootTaskState copyWith({
    PageStatus? status,
    RootTaskViewType? viewType,
    bool? showCompleted,
    TagEntity? tag,
    Map<TaskListMode, int>? taskCounts,
    Map<int, int>? dailyTaskCounts,
    TaskPriorityStyle? priorityStyle,
    Map<RootTaskTab, NoteType?>? tabFocusNoteTypes,
  }) {
    return RootTaskState(
      status: status ?? this.status,
      viewType: viewType ?? this.viewType,
      showCompleted: showCompleted ?? this.showCompleted,
      tag: tag ?? this.tag,
      taskCounts: taskCounts ?? this.taskCounts,
      dailyTaskCounts: dailyTaskCounts ?? this.dailyTaskCounts,
      priorityStyle: priorityStyle ?? this.priorityStyle,
      tabFocusNoteTypes: tabFocusNoteTypes ?? this.tabFocusNoteTypes,
    );
  }
}
