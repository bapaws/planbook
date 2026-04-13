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
    this.selectedTagIds = const {},
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

  /// 当前选中的标签 ID 集合，用于筛选任务
  /// 为空时显示全部数据，非空时只显示包含选中标签的数据
  final Set<String> selectedTagIds;

  final Map<TaskListMode, int> taskCounts;

  final Map<int, int> dailyTaskCounts;

  final Map<RootTaskTab, NoteType?> tabFocusNoteTypes;

  bool? get isCompleted => showCompleted ? null : false;

  bool get hasTagFilter => selectedTagIds.isNotEmpty;

  @override
  List<Object?> get props => [
    status,
    viewType,
    showCompleted,
    selectedTagIds,
    taskCounts,
    dailyTaskCounts,
    priorityStyle,
    tabFocusNoteTypes,
  ];

  RootTaskState copyWith({
    PageStatus? status,
    RootTaskViewType? viewType,
    bool? showCompleted,
    Set<String>? selectedTagIds,
    Map<TaskListMode, int>? taskCounts,
    Map<int, int>? dailyTaskCounts,
    TaskPriorityStyle? priorityStyle,
    Map<RootTaskTab, NoteType?>? tabFocusNoteTypes,
  }) {
    return RootTaskState(
      status: status ?? this.status,
      viewType: viewType ?? this.viewType,
      showCompleted: showCompleted ?? this.showCompleted,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      taskCounts: taskCounts ?? this.taskCounts,
      dailyTaskCounts: dailyTaskCounts ?? this.dailyTaskCounts,
      priorityStyle: priorityStyle ?? this.priorityStyle,
      tabFocusNoteTypes: tabFocusNoteTypes ?? this.tabFocusNoteTypes,
    );
  }
}
