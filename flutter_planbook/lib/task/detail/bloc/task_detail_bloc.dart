import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/task/duration/model/task_duration_entity.dart';
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
    Jiffy? occurrenceAt,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       _taskId = taskId,
       _settingsRepository = settingsRepository,
       _occurrenceAt = occurrenceAt,
       super(const TaskDetailState()) {
    on<TaskDetailRequested>(_onRequested);
    on<TaskDetailNotesRequested>(_onNotesRequested);
    on<TaskDetailDeleted>(_onDeleted);
    on<TaskDetailTitleChanged>(_onTitleChanged);
    on<TaskDetailPriorityChanged>(_onPriorityChanged);
    on<TaskDetailTagsChanged>(_onTagsChanged);
    on<TaskDetailRecurrenceRuleChanged>(_onRecurrenceRuleChanged);
    on<TaskDetailDurationChanged>(_onDurationChanged);

    on<TaskDetailCompleted>(_onCompleted);
    on<TaskDetailNoteCreated>(_onNoteCreated);
    on<TaskDetailNoteDeleted>(_onNoteDeleted);

    on<TaskDetailChildrenChanged>(_onChildrenChanged);
    on<TaskDetailEditModeSelected>(_onEditModeSelected);
    on<TaskDetailUpdated>(_onUpdated);
  }

  final String _taskId;
  final Jiffy? _occurrenceAt;

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;
  final SettingsRepository _settingsRepository;

  Task? _updatedTask;
  List<TagEntity>? _updatedTags;
  List<TaskEntity>? _updatedChildren;

  Future<void> _onRequested(
    TaskDetailRequested event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    final task = await _tasksRepository.getTaskEntityById(
      _taskId,
      occurrenceAt: _occurrenceAt,
    );
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

    /// 取消任务的提醒
    unawaited(
      AlarmNotificationService.instance.cancelForTask(taskId),
    );
  }

  Future<void> _onTitleChanged(
    TaskDetailTitleChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    if (state.task?.title == event.title || event.title.isEmpty) return;
    final updatedTask = state.task!.task.copyWith(title: event.title);
    add(TaskDetailUpdated(task: updatedTask));
  }

  Future<void> _onChildrenChanged(
    TaskDetailChildrenChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    final entity = state.task;
    if (entity == null) return;
    final updatedTask = entity.task.copyWith(childCount: event.children.length);

    final newChildren = <TaskEntity>[...event.children];
    for (final child in entity.children) {
      if (!event.children.any((c) => c.id == child.id)) {
        newChildren.add(
          child.copyWith(
            task: child.task.copyWith(deletedAt: Value(Jiffy.now())),
          ),
        );
      }
    }
    add(
      TaskDetailUpdated(
        task: updatedTask,
        children: newChildren
            .map(
              (e) => e.copyWith(
                task: e.task.copyWith(
                  userId: Value(entity.task.userId),
                  parentId: Value(entity.id),
                  layer: entity.layer + 1,
                  priority: Value(entity.priority),
                  startAt: Value(entity.startAt),
                  endAt: Value(entity.endAt),
                  isAllDay: entity.isAllDay,
                  recurrenceRule: Value(entity.recurrenceRule),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _onPriorityChanged(
    TaskDetailPriorityChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    final updatedTask = state.task?.task.copyWith(
      priority: Value(event.priority),
    );
    add(TaskDetailUpdated(task: updatedTask));
  }

  Future<void> _onTagsChanged(
    TaskDetailTagsChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    add(TaskDetailUpdated(tags: event.tags));
  }

  Future<void> _onRecurrenceRuleChanged(
    TaskDetailRecurrenceRuleChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    final updatedTask = state.task?.task.copyWith(
      recurrenceRule: Value(event.recurrenceRule),
    );
    add(TaskDetailUpdated(task: updatedTask));
  }

  Future<void> _onDurationChanged(
    TaskDetailDurationChanged event,
    Emitter<TaskDetailState> emit,
  ) async {
    final updatedTask = state.task?.task.copyWith(
      isAllDay: event.entity?.isAllDay ?? true,
      startAt: Value(event.entity?.startAt),
      endAt: Value(event.entity?.endAt),
    );
    add(TaskDetailUpdated(task: updatedTask));
  }

  Future<void> _onCompleted(
    TaskDetailCompleted event,
    Emitter<TaskDetailState> emit,
  ) async {
    final task = event.task;
    if (task == null) return;

    final activities = await _tasksRepository.completeTask(
      task,
      occurrenceAt: state.task?.occurrence?.occurrenceAt,
    );
    for (final activity in activities) {
      add(TaskDetailNoteCreated(activity: activity));

      final index = state.task?.children.indexWhere(
        (child) => child.id == activity.taskId,
      );
      if (index != null && index != -1) {
        final newChildren = [...state.task!.children];
        newChildren[index] = newChildren[index].copyWith(activity: activity);
        emit(state.copyWith(task: state.task!.copyWith(children: newChildren)));
      }

      /// 取消任务的提醒
      if (activity.taskId != null) {
        unawaited(
          AlarmNotificationService.instance.cancelForTask(activity.taskId!),
        );
      }
    }
    emit(
      state.copyWith(
        status: PageStatus.success,
        task: state.task?.copyWith(
          activity: activities.firstWhereOrNull(
            (e) => e.taskId == state.task?.id,
          ),
        ),
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
    final taskId = event.activity.taskId;
    if (taskId == null) return;
    final task = await _tasksRepository.getTaskEntityById(taskId);
    if (task == null) return;

    final type = await _settingsRepository.getTaskAutoNoteTypeByTask(task);
    if (type == TaskAutoNoteType.none) return;

    NoteEntity? noteEntity;
    if (type.isCreate) {
      final note = await _notesRepository.create(
        title:
            '${event.activity.deletedAt == null ? '✅' : '❌'} '
            '${task.title}',
        tags: task.tags,
        taskId: task.id,
      );
      if (type == TaskAutoNoteType.createAndEdit) {
        noteEntity = await _notesRepository.getNoteEntityById(note.id);
      }
    } else if (type == TaskAutoNoteType.edit) {
      final note = Note(
        id: const Uuid().v4(),
        title:
            '${event.activity.deletedAt == null ? '✅' : '❌'} '
            '${task.title}',
        taskId: task.id,
        createdAt: Jiffy.now(),
        images: [],
      );
      noteEntity = NoteEntity(note: note, tags: task.tags);
    }
    emit(
      state.copyWith(status: PageStatus.success, currentTaskNote: noteEntity),
    );
  }

  Future<void> _onNoteDeleted(
    TaskDetailNoteDeleted event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await _notesRepository.deleteNoteById(event.noteId);
    emit(state.copyWith(status: PageStatus.success));
  }

  Future<void> _onEditModeSelected(
    TaskDetailEditModeSelected event,
    Emitter<TaskDetailState> emit,
  ) async {
    if (event.mode == null ||
        (_updatedTask == null &&
            _updatedTags == null &&
            _updatedChildren == null)) {
      _updatedTask = null;
      _updatedTags = null;
      _updatedChildren = null;
      emit(state.copyWith(showEditModeSelection: false));
      return;
    }

    final entity = state.task;
    if (entity == null) return;

    final task = _updatedTask ?? entity.task;
    await _tasksRepository.updateWithEditMode(
      entity: entity,
      task: task,
      editMode: event.mode!,
      tags: _updatedTags,
      children: _updatedChildren,
    );
    emit(
      state.copyWith(
        status: PageStatus.success,
        task: state.task?.copyWith(
          task: _updatedTask,
          tags: _updatedTags,
          children: _updatedChildren,
        ),
      ),
    );
    _updatedTask = null;
    _updatedTags = null;
    _updatedChildren = null;

    /// 重新调度任务的提醒
    unawaited(AlarmNotificationService.instance.scheduleForTask(task));
  }

  Future<void> _onUpdated(
    TaskDetailUpdated event,
    Emitter<TaskDetailState> emit,
  ) async {
    if (state.task == null) return;
    _updatedTask = event.task;
    _updatedTags = event.tags;
    _updatedChildren = event.children;

    final need = await _tasksRepository.needsEditModeSelection(state.task!);
    if (need) {
      emit(state.copyWith(showEditModeSelection: true));
    } else {
      add(
        const TaskDetailEditModeSelected(
          mode: RecurringTaskEditMode.allEvents,
        ),
      );
    }
  }
}
