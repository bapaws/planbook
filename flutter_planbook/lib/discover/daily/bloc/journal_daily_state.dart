part of 'journal_daily_bloc.dart';

final class JournalDailyTaskPriorityCount extends Equatable {
  const JournalDailyTaskPriorityCount({
    required this.priority,
    required this.totalCount,
    required this.completedCount,
  });

  final TaskPriority priority;
  final int totalCount;
  final int completedCount;

  @override
  List<Object?> get props => [priority, totalCount, completedCount];
}

final class JournalDailyState extends Equatable {
  const JournalDailyState({
    this.focusNote,
    this.summaryNote,
    this.tasks = const [],
    this.writtenNotes = const [],
    this.morningTasks = const [],
    this.afternoonTasks = const [],
    this.eveningTasks = const [],
    this.morningTaskNotes = const [],
    this.afternoonTaskNotes = const [],
    this.eveningTaskNotes = const [],
    this.taskPriorityCounts = const [],
    this.plannedTasksCount = 0,
    this.completedTasksCount = 0,
    this.uncompletedTasksCount = 0,
    this.completedInboxTasksCount = 0,
    this.completedTaskPriorityCounts = const {},
  });

  final Note? focusNote;
  final Note? summaryNote;

  final int plannedTasksCount;
  final int uncompletedTasksCount;
  final int completedTasksCount;
  final int completedInboxTasksCount;
  final Map<TaskPriority, int> completedTaskPriorityCounts;

  final List<TaskEntity> tasks;
  final List<NoteEntity> writtenNotes;

  final List<NoteEntity> morningTaskNotes;
  final List<NoteEntity> afternoonTaskNotes;
  final List<NoteEntity> eveningTaskNotes;

  final List<TaskEntity> morningTasks;
  final List<TaskEntity> afternoonTasks;
  final List<TaskEntity> eveningTasks;

  final List<JournalDailyTaskPriorityCount> taskPriorityCounts;

  @override
  List<Object?> get props => [
    focusNote,
    summaryNote,
    plannedTasksCount,
    completedTasksCount,
    uncompletedTasksCount,
    completedInboxTasksCount,
    completedTaskPriorityCounts,
    tasks,
    writtenNotes,
    morningTasks,
    afternoonTasks,
    eveningTasks,
    morningTaskNotes,
    afternoonTaskNotes,
    eveningTaskNotes,
    taskPriorityCounts,
  ];

  JournalDailyState copyWith({
    Note? focusNote,
    Note? summaryNote,
    int? plannedTasksCount,
    int? completedTasksCount,
    int? uncompletedTasksCount,
    int? completedInboxTasksCount,
    Map<TaskPriority, int>? completedTaskPriorityCounts,
    List<TaskEntity>? tasks,
    List<NoteEntity>? writtenNotes,
    List<TaskEntity>? morningTasks,
    List<TaskEntity>? afternoonTasks,
    List<TaskEntity>? eveningTasks,
    List<NoteEntity>? morningTaskNotes,
    List<NoteEntity>? afternoonTaskNotes,
    List<NoteEntity>? eveningTaskNotes,
    List<JournalDailyTaskPriorityCount>? taskPriorityCounts,
  }) {
    return JournalDailyState(
      focusNote: focusNote ?? this.focusNote,
      summaryNote: summaryNote ?? this.summaryNote,
      plannedTasksCount: plannedTasksCount ?? this.plannedTasksCount,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      uncompletedTasksCount:
          uncompletedTasksCount ?? this.uncompletedTasksCount,
      completedInboxTasksCount:
          completedInboxTasksCount ?? this.completedInboxTasksCount,
      completedTaskPriorityCounts:
          completedTaskPriorityCounts ?? this.completedTaskPriorityCounts,
      tasks: tasks ?? this.tasks,
      writtenNotes: writtenNotes ?? this.writtenNotes,
      morningTasks: morningTasks ?? this.morningTasks,
      afternoonTasks: afternoonTasks ?? this.afternoonTasks,
      eveningTasks: eveningTasks ?? this.eveningTasks,
      morningTaskNotes: morningTaskNotes ?? this.morningTaskNotes,
      afternoonTaskNotes: afternoonTaskNotes ?? this.afternoonTaskNotes,
      eveningTaskNotes: eveningTaskNotes ?? this.eveningTaskNotes,
      taskPriorityCounts: taskPriorityCounts ?? this.taskPriorityCounts,
    );
  }
}
