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
  Jiffy? get startAt => task.startAt;
  Jiffy? get endAt => task.endAt;
  int get order => task.order;
  bool get isAllDay => task.isAllDay;
  RecurrenceRule? get recurrenceRule => task.recurrenceRule;
  TaskPriority get priority => task.priority ?? TaskPriority.none;
  List<EventAlarm>? get alarms => task.alarms;
  Jiffy get createdAt => task.createdAt;
  Jiffy? get completedAt => activity?.completedAt;

  bool get isCompleted => activity?.completedAt != null;

  @override
  List<Object?> get props => [task, taskTags, tags, activity, children];

  TaskEntity copyWith({
    Task? task,
    List<TaskTag>? taskTags,
    List<TagEntity>? tags,
    TaskActivity? activity,
    List<TaskEntity>? children,
  }) {
    return TaskEntity(
      task: task ?? this.task,
      taskTags: taskTags ?? this.taskTags,
      tags: tags ?? this.tags,
      activity: activity ?? this.activity,
      children: children ?? this.children,
    );
  }
}
