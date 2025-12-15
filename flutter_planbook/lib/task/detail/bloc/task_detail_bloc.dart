import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:uuid/uuid.dart';

part 'task_detail_event.dart';
part 'task_detail_state.dart';

class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
  TaskDetailBloc({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    required String taskId,
    required SettingsRepository settingsRepository,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       _taskId = taskId,
       _settingsRepository = settingsRepository,
       super(const TaskDetailState()) {
    on<TaskDetailRequested>(_onRequested);
    on<TaskDetailNotesRequested>(_onNotesRequested);
    on<TaskDetailDeleted>(_onDeleted);
    on<TaskDetailTitleChanged>(_onTitleChanged);
    on<TaskDetailDueAtChanged>(_onDueAtChanged);
    on<TaskDetailPriorityChanged>(_onPriorityChanged);
    on<TaskDetailTagsChanged>(_onTagsChanged);
    on<TaskDetailRecurrenceRuleChanged>(_onRecurrenceRuleChanged);
    on<TaskDetailIsAllDayChanged>(_onIsAllDayChanged);
    on<TaskDetailStartAtChanged>(_onStartAtChanged);
    on<TaskDetailEndAtChanged>(_onEndAtChanged);

    on<TaskDetailCompleted>(_onCompleted);
    on<TaskDetailNoteCreated>(_onNoteCreated);
  }

  final String _taskId;

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;
  final SettingsRepository _settingsRepository;

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

  Future<void> _onRecurrenceRuleChanged(
    TaskDetailRecurrenceRuleChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    final task = state.task?.task;
    if (task == null) return;
    final updatedTask = task.copyWith(
      recurrenceRule: Value(event.recurrenceRule),
    );
    await _tasksRepository.update(task: updatedTask);
    emit(
      state.copyWith(
        status: PageStatus.success,
        task: state.task?.copyWith(task: updatedTask),
      ),
    );
  }

  Future<void> _onIsAllDayChanged(
    TaskDetailIsAllDayChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    final task = state.task?.task;
    if (task == null) return;
    final updatedTask = task.copyWith(isAllDay: event.isAllDay);
    await _tasksRepository.update(task: updatedTask);
  }

  Future<void> _onStartAtChanged(
    TaskDetailStartAtChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    final task = state.task?.task;
    if (task == null) return;
    final updatedTask = task.copyWith(startAt: Value(event.startAt));
    await _tasksRepository.update(task: updatedTask);
  }

  Future<void> _onEndAtChanged(
    TaskDetailEndAtChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    final task = state.task?.task;
    if (task == null) return;
    final updatedTask = task.copyWith(endAt: Value(event.endAt));
    await _tasksRepository.update(task: updatedTask);
  }

  Future<void> _onCompleted(
    TaskDetailCompleted event,
    Emitter<TaskDetailState> emit,
  ) async {
    if (state.task == null) return;
    emit(state.copyWith(status: PageStatus.loading));
    final activities = await _tasksRepository.completeTask(state.task!);
    for (final activity in activities) {
      add(TaskDetailNoteCreated(task: state.task!, activity: activity));
    }
    emit(
      state.copyWith(
        status: PageStatus.success,
        task: state.task?.copyWith(activity: activities.firstOrNull),
      ),
    );

    final sound = await _settingsRepository.getTaskCompletedSound();
    if (sound != null && sound.isNotEmpty) {
      final player = AudioPlayer();
      await player.play(AssetSource(sound));
    }
  }

  Future<void> _onNoteCreated(
    TaskDetailNoteCreated event,
    Emitter<TaskDetailState> emit,
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
