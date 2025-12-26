part of 'task_done_cubit.dart';

final class TaskDoneState extends Equatable {
  const TaskDoneState({
    required this.task,
    this.status = PageStatus.initial,
    this.completedAt,
    this.currentTaskNote,
    this.taskAutoNoteType = TaskAutoNoteType.createAndEdit,
    this.subtaskAutoNoteType = TaskAutoNoteType.createAndEdit,
  });

  final PageStatus status;

  final TaskEntity task;

  final Jiffy? completedAt;
  final NoteEntity? currentTaskNote;
  final TaskAutoNoteType taskAutoNoteType;
  final TaskAutoNoteType subtaskAutoNoteType;

  int get incompleteChildrenCount =>
      task.children.where((child) => !child.isCompleted).length;

  @override
  List<Object?> get props => [
    status,
    task,
    completedAt,
    currentTaskNote,
    taskAutoNoteType,
    subtaskAutoNoteType,
  ];

  TaskDoneState copyWith({
    PageStatus? status,
    TaskEntity? task,
    Jiffy? completedAt,
    NoteEntity? currentTaskNote,
    TaskAutoNoteType? taskAutoNoteType,
    TaskAutoNoteType? subtaskAutoNoteType,
  }) {
    return TaskDoneState(
      status: status ?? this.status,
      task: task ?? this.task,
      completedAt: completedAt ?? this.completedAt,
      currentTaskNote: currentTaskNote ?? this.currentTaskNote,
      taskAutoNoteType: taskAutoNoteType ?? this.taskAutoNoteType,
      subtaskAutoNoteType: subtaskAutoNoteType ?? this.subtaskAutoNoteType,
    );
  }
}
