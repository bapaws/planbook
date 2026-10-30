part of 'task_new_cubit.dart';

enum TaskNewFocus {
  none,
  title,
  priority,
  date,
  time,
  tags,
  recurrence,
}

final class TaskNewState extends Equatable {
  const TaskNewState({
    this.initialTask,
    this.status = PageStatus.initial,
    this.focus = TaskNewFocus.title,
    this.title = '',
    this.startAt,
    this.endAt,
    this.isAllDay = true,
    this.recurrenceRule,
    this.priority = TaskPriority.none,
    this.alarms = const [],
    this.tags = const [],
    this.children = const [],
    this.showEditModeSelection = false,
  });

  factory TaskNewState.fromData({
    TaskEntity? task,
    Jiffy? dueAt,
    TaskPriority? priority,
    List<TagEntity> initialTags = const [],
    bool? isAllDay,
  }) {
    final resolvedIsAllDay = task?.isAllDay ?? isAllDay ?? true;
    final initialStartAt =
        task?.startAt ??
        (dueAt == null
            ? null
            : resolvedIsAllDay
            ? dueAt
            : dueAt.startOf(Unit.day).add(hours: 9));
    return TaskNewState(
      initialTask: task,
      title: task?.title ?? '',
      startAt: initialStartAt,
      endAt:
          task?.endAt ??
          (resolvedIsAllDay || initialStartAt == null
              ? null
              : initialStartAt.add(hours: 1)),
      isAllDay: resolvedIsAllDay,
      recurrenceRule: task?.recurrenceRule,
      priority: task?.priority ?? priority ?? TaskPriority.none,
      alarms: task?.alarms ?? const [],
      tags: task?.tags ?? initialTags,
      children: task?.children ?? const [],
    );
  }

  final TaskEntity? initialTask;
  final PageStatus status;
  final TaskNewFocus focus;

  final String title;

  final Jiffy? startAt;
  final Jiffy? endAt;
  final bool isAllDay;
  final RecurrenceRule? recurrenceRule;
  final TaskPriority priority;
  final List<EventAlarm> alarms;

  final List<TaskEntity> children;

  final List<TagEntity> tags;

  final bool showEditModeSelection;

  Jiffy? get date => startAt ?? endAt;
  bool get isInbox => startAt == null && endAt == null;

  @override
  List<Object?> get props => [
    initialTask,
    status,
    focus,
    title,
    startAt,
    endAt,
    isAllDay,
    recurrenceRule,
    priority,
    alarms,
    tags,
    children,
    showEditModeSelection,
  ];

  TaskNewState copyWith({
    TaskEntity? initialTask,
    PageStatus? status,
    TaskNewFocus? focus,
    String? title,
    ValueGetter<Jiffy?>? startAt,
    ValueGetter<Jiffy?>? endAt,
    bool? isAllDay,
    ValueGetter<RecurrenceRule?>? recurrenceRule,
    TaskPriority? priority,
    List<EventAlarm>? alarms,
    List<TagEntity>? tags,
    List<TaskEntity>? children,
    bool? showEditModeSelection,
  }) {
    return TaskNewState(
      initialTask: initialTask ?? this.initialTask,
      status: status ?? this.status,
      focus: focus ?? this.focus,
      title: title ?? this.title,
      startAt: startAt == null ? this.startAt : startAt(),
      endAt: endAt == null ? this.endAt : endAt(),
      isAllDay: isAllDay ?? this.isAllDay,
      recurrenceRule: recurrenceRule == null
          ? this.recurrenceRule
          : recurrenceRule(),
      priority: priority ?? this.priority,
      alarms: alarms ?? this.alarms,
      tags: tags ?? this.tags,
      children: children ?? this.children,
      showEditModeSelection:
          showEditModeSelection ?? this.showEditModeSelection,
    );
  }
}
