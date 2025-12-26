import 'package:equatable/equatable.dart';
import 'package:planbook_api/planbook_api.dart';

enum TaskAutoNoteType {
  none,
  create,
  edit,
  createAndEdit;

  bool get isCreate =>
      this == TaskAutoNoteType.create || this == TaskAutoNoteType.createAndEdit;
  bool get isEdit =>
      this == TaskAutoNoteType.edit || this == TaskAutoNoteType.createAndEdit;
}

class TaskAutoNoteRule extends Equatable {
  const TaskAutoNoteRule({
    this.type = TaskAutoNoteType.createAndEdit,
    this.tag,
    this.priority,
    this.isSubtask = false,
  });

  factory TaskAutoNoteRule.fromJson(Map<String, dynamic> json) {
    return TaskAutoNoteRule(
      type: TaskAutoNoteType.values.byName(json['type'] as String),
      tag: json['tag'] != null
          ? TagEntity.fromJson(json['tag'] as Map<String, dynamic>)
          : null,
      priority: json['priority'] != null
          ? TaskPriority.fromValue(json['priority'] as int)
          : null,
      isSubtask: (json['is_subtask'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'tag': tag?.toJson(),
      'priority': priority?.value,
      'is_subtask': isSubtask,
    };
  }

  final TaskAutoNoteType type;
  final TagEntity? tag;
  final TaskPriority? priority;
  final bool isSubtask;

  TaskAutoNoteRule copyWith({
    TaskAutoNoteType? type,
    TagEntity? tag,
    TaskPriority? priority,
    bool? isSubtask,
  }) {
    return TaskAutoNoteRule(
      type: type ?? this.type,
      tag: tag ?? this.tag,
      priority: priority ?? this.priority,
      isSubtask: isSubtask ?? this.isSubtask,
    );
  }

  @override
  List<Object?> get props => [type, tag, priority, isSubtask];
}
