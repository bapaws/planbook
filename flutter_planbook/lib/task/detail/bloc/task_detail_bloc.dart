import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'task_detail_event.dart';
part 'task_detail_state.dart';

class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
  TaskDetailBloc({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    required String taskId,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       _taskId = taskId,
       super(const TaskDetailState()) {
    on<TaskDetailRequested>(_onRequested);
    on<TaskDetailNotesRequested>(_onNotesRequested);
    on<TaskDetailDeleted>(_onDeleted);
    on<TaskDetailTitleChanged>(_onTitleChanged);
    on<TaskDetailDueAtChanged>(_onDueAtChanged);
    on<TaskDetailPriorityChanged>(_onPriorityChanged);
    on<TaskDetailTagsChanged>(_onTagsChanged);
  }

  final String _taskId;

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;

  Future<void> _onRequested(
    TaskDetailRequested event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    final task = await _tasksRepository.getTaskEntityById(_taskId);
    emit(state.copyWith(status: PageStatus.success, task: task));
  }

  Future<void> _onNotesRequested(
    TaskDetailNotesRequested event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await emit.forEach(
      _notesRepository.getNoteEntitiesByTaskId(_taskId),
      onData: (notes) =>
          state.copyWith(status: PageStatus.success, notes: notes),
    );
  }

  Future<void> _onDeleted(
    TaskDetailDeleted event,
    Emitter<TaskDetailState> emit,
  ) async {
    final taskId = state.task?.id;
    if (taskId == null) return;
    await _tasksRepository.deleteTaskById(taskId);
    emit(state.copyWith(status: PageStatus.dispose));
  }

  Future<void> _onTitleChanged(
    TaskDetailTitleChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    final task = state.task?.task;
    if (task == null) return;
    if (task.title == event.title || event.title.isEmpty) return;
    final updatedTask = task.copyWith(title: event.title);
    await _tasksRepository.update(task: updatedTask);
    emit(
      state.copyWith(
        status: PageStatus.success,
        task: state.task?.copyWith(task: updatedTask),
      ),
    );
  }

  Future<void> _onDueAtChanged(
    TaskDetailDueAtChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    final task = state.task?.task;
    if (task == null) return;

    final updatedTask = task.copyWith(dueAt: Value(event.dueAt));
    await _tasksRepository.update(task: updatedTask);
    emit(
      state.copyWith(
        status: PageStatus.success,
        task: state.task?.copyWith(task: updatedTask),
      ),
    );
  }

  Future<void> _onPriorityChanged(
    TaskDetailPriorityChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    final task = state.task?.task;
    if (task == null) return;
    final updatedTask = task.copyWith(priority: Value(event.priority));
    await _tasksRepository.update(task: updatedTask);
    emit(
      state.copyWith(
        status: PageStatus.success,
        task: state.task?.copyWith(task: updatedTask),
      ),
    );
  }

  Future<void> _onTagsChanged(
    TaskDetailTagsChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    final task = state.task?.task;
    if (task == null) return;

    await _tasksRepository.update(task: task, tags: event.tags);
    emit(
      state.copyWith(
        status: PageStatus.success,
        task: state.task?.copyWith(tags: event.tags),
      ),
    );
  }
}
