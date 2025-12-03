import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'task_list_event.dart';
part 'task_list_state.dart';

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    TaskListMode mode = TaskListMode.inbox,
    TagEntity? tag,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       _mode = mode,
       super(TaskListState(tag: tag)) {
    on<TaskListRequested>(_onRequested, transformer: restartable());
    on<TaskListCompleted>(_onCompleted);
    on<TaskListDeleted>(_onDeleted);
    on<TaskListNoteCreated>(_onNoteCreated);
  }

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;
  final TaskListMode _mode;

  Future<void> _onRequested(
    TaskListRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final date = event.date ?? state.date ?? Jiffy.now();
    emit(state.copyWith(status: PageStatus.loading, date: date));
    final stream = _tasksRepository.getTaskEntities(
      mode: _mode,
      date: date,
      tagId: event.tagId,
      priority: event.priority,
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
    TaskListCompleted event,
    Emitter<TaskListState> emit,
  ) async {
    await _tasksRepository.completeTaskById(event.task.id);
    emit(state.copyWith(status: PageStatus.success));
    add(TaskListNoteCreated(task: event.task));
  }

  Future<void> _onDeleted(
    TaskListDeleted event,
    Emitter<TaskListState> emit,
  ) async {
    await _tasksRepository.deleteTaskById(event.taskId);
    emit(state.copyWith(status: PageStatus.success));
  }

  Future<void> _onNoteCreated(
    TaskListNoteCreated event,
    Emitter<TaskListState> emit,
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
