part of 'root_task_bloc.dart';

enum RootTaskViewType {
  list,
  priority,
  timeBlock,
}

final class RootTaskState extends Equatable {
  const RootTaskState({
    this.status = PageStatus.initial,
    this.dayViewType = RootTaskViewType.list,
    this.weekViewMode = TaskWeekViewMode.grid,
    this.showCompleted = true,
    this.showSourcePanel = true,
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

  /// 天/收集箱/过期：列表 / 四象限 / 时间块
  final RootTaskViewType dayViewType;

  /// 周：八宫格 / 列表
  final TaskWeekViewMode weekViewMode;
  final bool showCompleted;
  final bool showSourcePanel;

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
    dayViewType,
    weekViewMode,
    showCompleted,
    showSourcePanel,
    selectedTagIds,
    taskCounts,
    dailyTaskCounts,
    priorityStyle,
    tabFocusNoteTypes,
  ];

  RootTaskState copyWith({
    PageStatus? status,
    RootTaskViewType? dayViewType,
    TaskWeekViewMode? weekViewMode,
    bool? showCompleted,
    bool? showSourcePanel,
    Set<String>? selectedTagIds,
    Map<TaskListMode, int>? taskCounts,
    Map<int, int>? dailyTaskCounts,
    TaskPriorityStyle? priorityStyle,
    Map<RootTaskTab, NoteType?>? tabFocusNoteTypes,
  }) {
    return RootTaskState(
      status: status ?? this.status,
      dayViewType: dayViewType ?? this.dayViewType,
      weekViewMode: weekViewMode ?? this.weekViewMode,
      showCompleted: showCompleted ?? this.showCompleted,
      showSourcePanel: showSourcePanel ?? this.showSourcePanel,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      taskCounts: taskCounts ?? this.taskCounts,
      dailyTaskCounts: dailyTaskCounts ?? this.dailyTaskCounts,
      priorityStyle: priorityStyle ?? this.priorityStyle,
      tabFocusNoteTypes: tabFocusNoteTypes ?? this.tabFocusNoteTypes,
    );
  }
}
