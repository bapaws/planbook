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
    on<TaskListDayAllRequested>(_onDayAllRequested, transformer: restartable());
    on<TaskListCompleted>(_onCompleted);
    on<TaskListDeleted>(_onDeleted);
    on<TaskListNoteCreated>(_onNoteCreated, transformer: sequential());
    on<TaskListTaskDelayed>(_onTaskDelayed);
    on<TaskListTaskExpanded>(_onTaskExpanded);
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
    final stream = _tasksRepository.getTaskEntities(
      mode: _mode,
      date: date,
      tagId: event.tagId,
      isCompleted: event.isCompleted,
    );
    await emit.forEach(stream, onData: _onTasksDataChanged);
  }

  Future<void> _onDayAllRequested(
    TaskListDayAllRequested event,
    Emitter<TaskListState> emit,
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
    await emit.forEach(stream, onData: _onTasksDataChanged);
  }

  TaskListState _onTasksDataChanged(List<TaskEntity> tasks) {
    final displayedTasks = <TaskEntity>[];
    for (final task in tasks) {
      if (state.expandedTaskIds.contains(task.id)) {
        displayedTasks
          ..add(task)
          ..addAll(task.children);
      } else {
        displayedTasks.add(task);
      }
    }
    return state.copyWith(
      status: PageStatus.success,
      tasks: displayedTasks,
    );
  }

  Future<void> _onCompleted(
    TaskListCompleted event,
    Emitter<TaskListState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    final task = event.task;
    var occurrenceAt = task.occurrence?.occurrenceAt;
    if (task.parentId != null) {
      final parentTask = state.tasks.firstWhereOrNull(
        (t) => t.id == task.parentId,
      );
      if (parentTask != null && parentTask.occurrence?.occurrenceAt != null) {
        occurrenceAt = parentTask.occurrence!.occurrenceAt;
      }
    }
    final activities = await _tasksRepository.completeTask(
      task,
      occurrenceAt: occurrenceAt,
    );
    for (final activity in activities) {
      add(TaskListNoteCreated(activity: activity));
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
    final taskId = event.activity.taskId;
    if (taskId == null) return;
    final task = await _tasksRepository.getTaskEntityById(taskId);
    if (task == null) return;

    var type = TaskAutoNoteType.createAndEdit;
    final rules = await _settingsRepository.getTaskAutoNoteRules();
    if (task.parentId != null) {
      final subtaskRule = rules.firstWhereOrNull((rule) => rule.isSubtask);
      if (subtaskRule == null || subtaskRule.type == TaskAutoNoteType.none) {
        return;
      }
      type = subtaskRule.type;
    } else {
      final rule = rules.firstWhereOrNull(
        (rule) => rule.priority == task.priority,
      );
      if (rule == null || rule.type == TaskAutoNoteType.none) return;
      type = rule.type;
    }

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

  /// 延迟任务到指定时间
  ///
  /// 对于非重复任务：直接修改 dueAt/startAt/endAt 时间
  /// 对于重复任务：创建分离实例（仅延迟这一个实例）
  Future<void> _onTaskDelayed(
    TaskListTaskDelayed event,
    Emitter<TaskListState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await _tasksRepository.delayTask(
      entity: event.task,
      delayTo: event.delayTo ?? Jiffy.now(),
    );
    emit(state.copyWith(status: PageStatus.success));
  }

  Future<void> _onTaskExpanded(
    TaskListTaskExpanded event,
    Emitter<TaskListState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    final expandedTaskIds = {...state.expandedTaskIds};
    if (expandedTaskIds.contains(event.task.id)) {
      expandedTaskIds.remove(event.task.id);
      final displayedTasks = state.tasks
          .where((task) => task.parentId != event.task.id)
          .toList();
      emit(
        state.copyWith(
          status: PageStatus.success,
          tasks: displayedTasks,
          expandedTaskIds: expandedTaskIds,
        ),
      );
    } else {
      final index = state.tasks.indexWhere(
        (task) => task.id == event.task.id,
      );
      if (index == -1) return;

      expandedTaskIds.add(event.task.id);
      final displayedTasks = [...state.tasks]
        ..insertAll(index + 1, event.task.children);
      emit(
        state.copyWith(
          status: PageStatus.success,
          tasks: displayedTasks,
          expandedTaskIds: expandedTaskIds,
        ),
      );
    }
  }
}
