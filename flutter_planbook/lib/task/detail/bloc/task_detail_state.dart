part of 'task_detail_bloc.dart';

final class TaskDetailState extends Equatable {
  const TaskDetailState({
    this.status = PageStatus.initial,
    this.task,
    this.notes = const [],
    this.currentTaskNote,
  });

  final PageStatus status;
  final TaskEntity? task;
  final List<NoteEntity> notes;

  final NoteEntity? currentTaskNote;

  bool get isCompleted => task?.isCompleted ?? false;

  @override
  List<Object?> get props => [status, task, notes, currentTaskNote];

  TaskDetailState copyWith({
    PageStatus? status,
    TaskEntity? task,
    List<NoteEntity>? notes,
    NoteEntity? currentTaskNote,
  }) {
    return TaskDetailState(
      status: status ?? this.status,
      task: task ?? this.task,
      notes: notes ?? this.notes,
      currentTaskNote: currentTaskNote ?? this.currentTaskNote,
    );
  }
}
