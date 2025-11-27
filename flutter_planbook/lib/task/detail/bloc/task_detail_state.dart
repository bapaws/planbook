part of 'task_detail_bloc.dart';

final class TaskDetailState extends Equatable {
  const TaskDetailState({
    this.status = PageStatus.initial,
    this.task,
    this.notes = const [],
  });

  final PageStatus status;
  final TaskEntity? task;
  final List<NoteEntity> notes;

  @override
  List<Object?> get props => [status, task, notes];

  TaskDetailState copyWith({
    PageStatus? status,
    TaskEntity? task,
    List<NoteEntity>? notes,
  }) {
    return TaskDetailState(
      status: status ?? this.status,
      task: task ?? this.task,
      notes: notes ?? this.notes,
    );
  }
}
