part of 'task_detail_bloc.dart';

final class TaskDetailState extends Equatable {
  const TaskDetailState({
    this.status = PageStatus.initial,
    this.task,
    this.notes = const [],
    this.currentTaskNote,
    this.showEditModeSelection = false,
    this.showDeleteModeSelection = false,
    this.showDeleteConfirmation = false,
  });

  final PageStatus status;
  final TaskEntity? task;
  final List<NoteEntity> notes;

  final bool showEditModeSelection;
  final bool showDeleteModeSelection;
  final bool showDeleteConfirmation;

  final NoteEntity? currentTaskNote;

  bool get isCompleted => task?.isCompleted ?? false;

  @override
  List<Object?> get props => [
    status,
    task,
    notes,
    currentTaskNote,
    showEditModeSelection,
    showDeleteModeSelection,
    showDeleteConfirmation,
  ];

  TaskDetailState copyWith({
    PageStatus? status,
    TaskEntity? task,
    List<NoteEntity>? notes,
    NoteEntity? currentTaskNote,
    bool? showEditModeSelection,
    bool? showDeleteModeSelection,
    bool? showDeleteConfirmation,
  }) {
    return TaskDetailState(
      status: status ?? this.status,
      task: task ?? this.task,
      notes: notes ?? this.notes,
      currentTaskNote: currentTaskNote ?? this.currentTaskNote,
      showEditModeSelection:
          showEditModeSelection ?? this.showEditModeSelection,
      showDeleteModeSelection:
          showDeleteModeSelection ?? this.showDeleteModeSelection,
      showDeleteConfirmation:
          showDeleteConfirmation ?? this.showDeleteConfirmation,
    );
  }
}
