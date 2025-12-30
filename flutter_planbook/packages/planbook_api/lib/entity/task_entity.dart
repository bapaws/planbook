import 'package:equatable/equatable.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

enum TaskListMode { today, inbox, overdue, tag }

class TaskEntity extends Equatable {
  const TaskEntity({
    required this.task,
    this.taskTags = const [],
    this.tags = const [],
    this.occurrence,
    this.activity,
    this.children = const [],
  });

  factory TaskEntity.fromJson(Map<String, dynamic> json) {
    return TaskEntity(
      task: Task.fromJson(json['task'] as Map<String, dynamic>),
      taskTags: json['taskTags'] as List<TaskTag>,
      tags: json['tags'] as List<TagEntity>,
      occurrence: json['occurrence'] as TaskOccurrence?,
      activity: json['activity'] as TaskActivity?,
      children: json['children'] as List<TaskEntity>,
    );
  }

  final Task task;
  final List<TaskTag> taskTags;
  final List<TagEntity> tags;
  final TaskOccurrence? occurrence;
  final TaskActivity? activity;
  final List<TaskEntity> children;

  String get id => task.id;
  String get title => task.title;
  String? get parentId => task.parentId;
  Jiffy? get dueAt => task.dueAt;
  Jiffy? get startAt =>
      occurrence?.startAt ?? occurrence?.dueAt ?? task.startAt ?? task.dueAt;
  Jiffy? get endAt => occurrence?.endAt ?? task.endAt;
  int get order => task.order;
  // 兼容老数据，如果 dueAt 不为空且 startAt 为空，则认为是全天任务
  bool get isAllDay =>
      task.isAllDay || (task.dueAt != null && task.startAt == null);
  RecurrenceRule? get recurrenceRule => task.recurrenceRule;
  String? get detachedFromTaskId => task.detachedFromTaskId;
  TaskPriority get priority => task.priority ?? TaskPriority.none;
  List<EventAlarm> get alarms => task.alarms;
  int get childCount => task.childCount;
  int get layer => task.layer;
  Jiffy get createdAt => task.createdAt;
  Jiffy? get completedAt => activity?.completedAt;

  bool get isCompleted =>
      activity?.deletedAt == null && activity?.completedAt != null;

  Jiffy? get occurrenceAt => occurrence != null
      ? occurrence?.occurrenceAt ??
            occurrence?.startAt ??
            occurrence?.endAt ??
            occurrence?.dueAt
      : startAt ?? endAt ?? dueAt;

  @override
  List<Object?> get props => [
    task,
    taskTags,
    tags,
    occurrence,
    activity,
    children,
  ];

  TaskEntity copyWith({
    Task? task,
    List<TaskTag>? taskTags,
    List<TagEntity>? tags,
    TaskOccurrence? occurrence,
    TaskActivity? activity,
    List<TaskEntity>? children,
  }) {
    return TaskEntity(
      task: task ?? this.task,
      taskTags: taskTags ?? this.taskTags,
      tags: tags ?? this.tags,
      occurrence: occurrence ?? this.occurrence,
      activity: activity ?? this.activity,
      children: children ?? this.children,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task': task.toJson(),
      'taskTags': taskTags.map((e) => e.toJson()).toList(),
      'tags': tags.map((e) => e.toJson()).toList(),
      'occurrence': occurrence?.toJson(),
      'activity': activity?.toJson(),
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
}
