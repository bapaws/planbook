import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:uuid/uuid.dart';

part 'task_list_event.dart';
part 'task_list_state.dart';

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    required SettingsRepository settingsRepository,
    TaskListMode mode = TaskListMode.inbox,
    this.priority,
    TagEntity? tag,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       _mode = mode,
       _settingsRepository = settingsRepository,
       super(TaskListState(tag: tag)) {
    on<TaskListRequested>(_onRequested, transformer: restartable());
    on<TaskListCompleted>(_onCompleted);
    on<TaskListDeleted>(_onDeleted);
    on<TaskListNoteCreated>(_onNoteCreated, transformer: sequential());
  }

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;
  final SettingsRepository _settingsRepository;

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
      add(TaskListNoteCreated(task: event.task, activity: activity));
    }
    emit(state.copyWith(status: PageStatus.success));

    final sound = await _settingsRepository.getTaskCompletedSound();
    if (sound != null && sound.isNotEmpty) {
      final player = AudioPlayer();
      await player.play(AssetSource(sound));
    }
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
    final rules = await _settingsRepository.getTaskAutoNoteRules();
    final rule = rules.firstWhereOrNull(
      (rule) => rule.priority == event.task.priority,
    );
    if (rule == null || rule.type == TaskAutoNoteType.none) return;

    NoteEntity? noteEntity;
    if (rule.type.isCreate) {
      final note = await _notesRepository.create(
        title:
            '${event.activity.deletedAt == null ? '✅' : '❌'} '
            '${event.task.title}',
        tags: event.task.tags,
        taskId: event.task.id,
      );
      if (rule.type == TaskAutoNoteType.createAndEdit) {
        noteEntity = await _notesRepository.getNoteEntityById(note.id);
      }
    } else if (rule.type == TaskAutoNoteType.edit) {
      final note = Note(
        id: const Uuid().v4(),
        title:
            '${event.activity.deletedAt == null ? '✅' : '❌'} '
            '${event.task.title}',
        taskId: event.task.id,
        createdAt: Jiffy.now(),
        images: [],
      );
      noteEntity = NoteEntity(note: note, tags: event.task.tags);
    }
    emit(
      state.copyWith(status: PageStatus.success, currentTaskNote: noteEntity),
    );
  }
}
