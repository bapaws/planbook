part of 'journal_timeline_bloc.dart';

final class JournalTimelineState extends Equatable {
  const JournalTimelineState({
    this.morningTasks = const [],
    this.afternoonTasks = const [],
    this.eveningTasks = const [],
    this.taskCount = 0,
  });

  final List<TaskEntity> morningTasks;
  final List<TaskEntity> afternoonTasks;
  final List<TaskEntity> eveningTasks;

  final int taskCount;
  int get completedTaskCount =>
      morningTasks.length + afternoonTasks.length + eveningTasks.length;

  @override
  List<Object> get props => [
    morningTasks,
    afternoonTasks,
    eveningTasks,
    taskCount,
  ];

  JournalTimelineState copyWith({
    List<TaskEntity>? morningTasks,
    List<TaskEntity>? afternoonTasks,
    List<TaskEntity>? eveningTasks,
    int? taskCount,
  }) {
    return JournalTimelineState(
      morningTasks: morningTasks ?? this.morningTasks,
      afternoonTasks: afternoonTasks ?? this.afternoonTasks,
      eveningTasks: eveningTasks ?? this.eveningTasks,
      taskCount: taskCount ?? this.taskCount,
    );
  }
}
