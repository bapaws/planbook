import 'package:equatable/equatable.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

enum TaskListMode { today, inbox, overdue, tag }

class TaskEntity extends Equatable {
  const TaskEntity({
    required this.task,
    this.tags = const [],
    this.activity,
  });

  final Task task;
  final List<TagEntity> tags;
  final TaskActivity? activity;

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

  bool get isCompleted => activity?.completedAt != null;

  @override
  List<Object?> get props => [task, tags, activity];

  TaskEntity copyWith({
    Task? task,
    List<TagEntity>? tags,
    TaskActivity? activity,
  }) {
    return TaskEntity(
      task: task ?? this.task,
      tags: tags ?? this.tags,
      activity: activity ?? this.activity,
    );
  }
}
