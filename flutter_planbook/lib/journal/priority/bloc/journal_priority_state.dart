part of 'journal_priority_bloc.dart';

final class JournalPriorityState extends Equatable {
  const JournalPriorityState({
    this.status = PageStatus.initial,
    this.tasks = const {},
  });

  final PageStatus status;
  final Map<TaskPriority, List<TaskEntity>> tasks;

  @override
  List<Object> get props => [status, tasks];

  JournalPriorityState copyWith({
    PageStatus? status,
    Map<TaskPriority, List<TaskEntity>>? tasks,
  }) {
    return JournalPriorityState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
    );
  }
}
