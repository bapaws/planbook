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
    this.dueAt,
    this.startAt,
    this.endAt,
    this.isAllDay = false,
    this.recurrenceRule,
    this.priority = TaskPriority.none,
    this.alarms,
    this.tags = const [],
    this.children = const [],
    this.showEditModeSelection = false,
  });

  factory TaskNewState.fromData({TaskEntity? task, Jiffy? dueAt}) {
    return TaskNewState(
      initialTask: task,
      title: task?.title ?? '',
      dueAt: task?.dueAt ?? dueAt,
      startAt: task?.startAt,
      endAt: task?.endAt,
      isAllDay: task?.isAllDay ?? false,
      recurrenceRule: task?.recurrenceRule,
      priority: task?.priority ?? TaskPriority.none,
      alarms: task?.alarms,
      tags: task?.tags ?? const [],
      children: task?.children ?? const [],
    );
  }

  final TaskEntity? initialTask;
  final PageStatus status;
  final TaskNewFocus focus;

  final String title;
  final Jiffy? dueAt;
  final Jiffy? startAt;
  final Jiffy? endAt;
  final bool isAllDay;
  final RecurrenceRule? recurrenceRule;
  final TaskPriority priority;
  final List<EventAlarm>? alarms;

  final List<TaskEntity> children;

  final List<TagEntity> tags;

  final bool showEditModeSelection;

  Jiffy? get date => dueAt ?? startAt ?? endAt;
  bool get isInbox => dueAt == null && startAt == null && endAt == null;

  @override
  List<Object?> get props => [
    initialTask,
    status,
    focus,
    title,
    dueAt,
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
    ValueGetter<Jiffy?>? dueAt,
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
      dueAt: dueAt == null ? this.dueAt : dueAt(),
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
