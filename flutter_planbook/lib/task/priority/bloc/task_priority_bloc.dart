import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'task_priority_event.dart';
part 'task_priority_state.dart';

class TaskPriorityBloc extends Bloc<TaskPriorityEvent, TaskPriorityState> {
  TaskPriorityBloc({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    required this.priority,
    TaskListMode mode = TaskListMode.inbox,
    TagEntity? tag,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       _mode = mode,

       super(TaskPriorityState(tag: tag)) {
    on<TaskPriorityRequested>(_onRequested);
    on<TaskPriorityCompleted>(_onCompleted);
    on<TaskPriorityDeleted>(_onDeleted);
    on<TaskPriorityNoteCreated>(_onNoteCreated);
  }

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;
  final TaskListMode _mode;

  final TaskPriority priority;

  Future<void> _onRequested(
    TaskPriorityRequested event,
    Emitter<TaskPriorityState> emit,
  ) async {
    final date = event.date ?? state.date ?? Jiffy.now();
    emit(state.copyWith(status: PageStatus.loading, date: date));
    final stream = _tasksRepository.getAllTodayTaskEntities(
      mode: _mode,
      day: date,
      tagId: event.tagId,
      priority: priority,
      isCompleted: event.isCompleted,
    );
    await emit.forEach(
      stream,
      onData: (tasks) => state.copyWith(
        status: PageStatus.success,
        tasks: tasks,
      ),
    );
  }

  Future<void> _onCompleted(
    TaskPriorityCompleted event,
    Emitter<TaskPriorityState> emit,
  ) async {
    await _tasksRepository.completeTask(event.task);
    emit(state.copyWith(status: PageStatus.success));
    add(TaskPriorityNoteCreated(task: event.task));
  }

  Future<void> _onDeleted(
    TaskPriorityDeleted event,
    Emitter<TaskPriorityState> emit,
  ) async {
    await _tasksRepository.deleteTaskById(event.taskId);
    emit(state.copyWith(status: PageStatus.success));
  }

  Future<void> _onNoteCreated(
    TaskPriorityNoteCreated event,
    Emitter<TaskPriorityState> emit,
  ) async {
    final noteId = await _notesRepository.create(
      title: '✅ ${event.task.title}',
      tags: event.task.tags.map((tag) => tag.tag).toList(),
      taskId: event.task.id,
    );
    final note = await _notesRepository.getNoteEntityById(noteId);
    emit(state.copyWith(status: PageStatus.success, currentTaskNote: note));
  }
}
