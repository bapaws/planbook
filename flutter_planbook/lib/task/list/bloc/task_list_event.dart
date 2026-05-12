part of 'task_list_bloc.dart';

sealed class TaskListEvent extends Equatable {
  const TaskListEvent();

  @override
  List<Object?> get props => [];
}

final class TaskListRequested extends TaskListEvent {
  const TaskListRequested({
    this.date,
    this.tagId,
    this.isCompleted,
    this.selectedTagIds = const {},
  });

  final Jiffy? date;
  final String? tagId;
  final bool? isCompleted;
  final Set<String> selectedTagIds;

  @override
  List<Object?> get props => [date, tagId, isCompleted, selectedTagIds];

  TaskListRequested copyWith({
    Jiffy? date,
    String? tagId,
    bool? isCompleted,
    Set<String>? selectedTagIds,
  }) {
    return TaskListRequested(
      date: date ?? this.date,
      tagId: tagId ?? this.tagId,
      isCompleted: isCompleted ?? this.isCompleted,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
    );
  }
}

final class TaskListDayAllRequested extends TaskListRequested {
  const TaskListDayAllRequested({
    super.date,
    super.tagId,
    super.isCompleted,
    super.selectedTagIds = const {},
  });

  @override
  List<Object?> get props => [date, tagId, isCompleted, selectedTagIds];

  @override
  TaskListDayAllRequested copyWith({
    Jiffy? date,
    String? tagId,
    bool? isCompleted,
    Set<String>? selectedTagIds,
  }) {
    return TaskListDayAllRequested(
      date: date ?? this.date,
      tagId: tagId ?? this.tagId,
      isCompleted: isCompleted ?? this.isCompleted,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
    );
  }
}

final class TaskListCompleted extends TaskListEvent {
  const TaskListCompleted({required this.task});

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

final class TaskListDeleted extends TaskListEvent {
  const TaskListDeleted({required this.taskId});

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

final class TaskListNoteCreated extends TaskListEvent {
  const TaskListNoteCreated({required this.activity});

  final TaskActivity activity;

  @override
  List<Object?> get props => [activity];
}

final class TaskListTaskDelayed extends TaskListEvent {
  const TaskListTaskDelayed({
    required this.task,
    this.delayTo,
  });

  final TaskEntity task;

  /// 指定延迟到的日期；为 null 时由 bloc 按“今天/明天”规则计算
  final Jiffy? delayTo;

  @override
  List<Object?> get props => [task, delayTo];
}

final class TaskListTaskExpanded extends TaskListEvent {
  const TaskListTaskExpanded({required this.task});

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

final class TaskListPriorityChanged extends TaskListEvent {
  const TaskListPriorityChanged({
    required this.task,
    required this.targetPriority,
  });

  final TaskEntity task;
  final TaskPriority targetPriority;

  @override
  List<Object?> get props => [task, targetPriority];
}
