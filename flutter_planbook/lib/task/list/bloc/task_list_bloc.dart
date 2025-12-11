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
    this.priority,
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
  final TaskPriority? priority;

  Future<void> _onRequested(
    TaskListRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final date = event.date ?? state.date ?? Jiffy.now();
    emit(state.copyWith(status: PageStatus.loading, date: date));
    final stream = priority == null
        ? _tasksRepository.getTaskEntities(
            mode: _mode,
            date: date,
            tagId: event.tagId,
            isCompleted: event.isCompleted,
          )
        : _tasksRepository.getAllTodayTaskEntities(
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
    TaskListCompleted event,
    Emitter<TaskListState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    final activities = await _tasksRepository.completeTask(event.task);
    for (final activity in activities) {
      if (activity.deletedAt == null && activity.taskId != null) {
        add(TaskListNoteCreated(taskId: activity.taskId!));
      }
    }
    emit(state.copyWith(status: PageStatus.success));
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
    final task = await _tasksRepository.getTaskEntityById(event.taskId);
    if (task == null) return;
    final note = await _notesRepository.create(
      title: '✅ ${task.title}',
      tags: task.tags.map((tag) => tag.tag).toList(),
      taskId: task.id,
    );
    final entity = await _notesRepository.getNoteEntityById(note.id);
    emit(state.copyWith(status: PageStatus.success, currentTaskNote: entity));
  }
}
