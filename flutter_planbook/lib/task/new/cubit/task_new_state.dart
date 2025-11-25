part of 'task_new_cubit.dart';

enum TaskNewFocus {
  none,
  title,
  priority,
  date,
  time,
  tags,
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
  });

  /// 从 JSON 创建 state（用于恢复草稿）
  /// tags 会从 JSON 中恢复，不需要查询数据库
  factory TaskNewState.fromJson(Map<String, dynamic> json) {
    return TaskNewState(
      title: json['title'] as String? ?? '',
      priority:
          TaskPriority.fromValue(json['priority'] as int?) ?? TaskPriority.none,
      isAllDay: json['isAllDay'] as bool? ?? false,
      dueAt: json['dueAt'] != null
          ? Jiffy.parse(json['dueAt'] as String)
          : null,
      startAt: json['startAt'] != null
          ? Jiffy.parse(json['startAt'] as String)
          : null,
      endAt: json['endAt'] != null
          ? Jiffy.parse(json['endAt'] as String)
          : null,
      recurrenceRule: json['recurrenceRule'] != null
          ? RecurrenceRule.fromJson(
              json['recurrenceRule'] as Map<String, dynamic>,
            )
          : null,
      alarms: json['alarms'] != null
          ? (json['alarms'] as List<dynamic>)
                .map((e) => EventAlarm.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      tags: json['tags'] != null
          ? (json['tags'] as List<dynamic>)
                .map((e) => TagEntity.fromJson(e as Map<String, dynamic>))
                .toList()
          : const [],
    );
  }

  factory TaskNewState.fromData({TaskEntity? task}) {
    return TaskNewState(
      initialTask: task,
      title: task?.title ?? '',
      dueAt: task?.dueAt ?? Jiffy.now().startOf(Unit.day),
      startAt: task?.startAt,
      endAt: task?.endAt,
      isAllDay: task?.isAllDay ?? false,
      recurrenceRule: task?.recurrenceRule,
      priority: task?.priority ?? TaskPriority.none,
      alarms: task?.alarms,
      tags: task?.tags ?? const [],
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

  final List<TagEntity> tags;

  Jiffy? get date => dueAt ?? startAt ?? endAt;

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
  ];

  /// 将 state 转换为 JSON（用于保存草稿）
  /// tags 会被完整保存，以便恢复时不需要查询数据库
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'priority': priority.value,
      'isAllDay': isAllDay,
      if (dueAt != null) 'dueAt': dueAt!.format(),
      if (startAt != null) 'startAt': startAt!.format(),
      if (endAt != null) 'endAt': endAt!.format(),
      if (recurrenceRule != null) 'recurrenceRule': recurrenceRule!.toJson(),
      if (alarms != null && alarms!.isNotEmpty)
        'alarms': alarms!.map((e) => e.toJson()).toList(),
      if (tags.isNotEmpty) 'tags': tags.map((e) => e.toJson()).toList(),
    };
  }

  TaskNewState copyWith({
    TaskEntity? initialTask,
    PageStatus? status,
    TaskNewFocus? focus,
    String? title,
    ValueGetter<Jiffy?>? dueAt,
    ValueGetter<Jiffy?>? startAt,
    ValueGetter<Jiffy?>? endAt,
    bool? isAllDay,
    RecurrenceRule? recurrenceRule,
    TaskPriority? priority,
    List<EventAlarm>? alarms,
    List<TagEntity>? tags,
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
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      priority: priority ?? this.priority,
      alarms: alarms ?? this.alarms,
      tags: tags ?? this.tags,
    );
  }
}
