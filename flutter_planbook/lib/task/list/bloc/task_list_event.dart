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

/// 拖拽被接受后，源列表同步移除任务的事件。
final class TaskListTaskDragCompleted extends TaskListEvent {
  const TaskListTaskDragCompleted({required this.task});

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

final class TaskListCompleted extends TaskListEvent {
  const TaskListCompleted({required this.task});

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

final class TaskListDeleteRequested extends TaskListEvent {
  const TaskListDeleteRequested({required this.task});

  final TaskEntity task;

  @override
  List<Object?> get props => [task];
}

final class TaskListDeleteConfirmed extends TaskListEvent {
  const TaskListDeleteConfirmed({this.mode});

  final RecurringTaskDeleteMode? mode;

  @override
  List<Object?> get props => [mode];
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

final class TaskListTaskScheduled extends TaskListEvent {
  const TaskListTaskScheduled({
    required this.task,
    required this.targetPriority,
    required this.targetDate,
    this.tags,
  });

  final TaskEntity task;
  final TaskPriority targetPriority;
  final Jiffy targetDate;

  /// 指定更新后的标签列表；为 null 时保持原标签
  final List<TagEntity>? tags;

  @override
  List<Object?> get props => [task, targetPriority, targetDate, tags];
}

final class TaskListTaskTimeBlocked extends TaskListEvent {
  const TaskListTaskTimeBlocked({
    required this.task,
    required this.startAt,
    required this.endAt,
  });

  final TaskEntity task;
  final Jiffy startAt;
  final Jiffy endAt;

  @override
  List<Object?> get props => [task, startAt, endAt];
}

/// 将任务设为指定日期的全天任务（时间块全天区投放）
final class TaskListTaskAllDayScheduled extends TaskListEvent {
  const TaskListTaskAllDayScheduled({
    required this.task,
    required this.date,
  });

  final TaskEntity task;
  final Jiffy date;

  @override
  List<Object?> get props => [task, date];
}
