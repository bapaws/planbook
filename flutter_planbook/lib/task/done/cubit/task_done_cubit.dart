import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:uuid/uuid.dart';

part 'task_done_state.dart';

class TaskDoneCubit extends Cubit<TaskDoneState> {
  TaskDoneCubit({
    required TasksRepository tasksRepository,
    required SettingsRepository settingsRepository,
    required NotesRepository notesRepository,
    required TaskEntity task,
  }) : _tasksRepository = tasksRepository,
       _settingsRepository = settingsRepository,
       _notesRepository = notesRepository,
       super(
         TaskDoneState(
           task: task,
           completedAt: Jiffy.now(),
         ),
       );

  final TasksRepository _tasksRepository;
  final SettingsRepository _settingsRepository;
  final NotesRepository _notesRepository;

  int get incompleteChildrenCount => state.incompleteChildrenCount;

  Future<void> onRequested() async {}

  Future<void> onCompletedAtChanged(Jiffy completedAt) async {
    emit(state.copyWith(completedAt: completedAt));
  }

  void onTaskAutoNoteTypeChanged(TaskAutoNoteType type) {
    emit(state.copyWith(taskAutoNoteType: type));
  }

  void onSubtaskAutoNoteTypeChanged(TaskAutoNoteType type) {
    emit(state.copyWith(subtaskAutoNoteType: type));
  }

  Future<void> onCompleted({TaskEntity? task}) async {
    emit(state.copyWith(status: PageStatus.loading));

    final activities = <TaskActivity>[];
    final entity = task ?? state.task;
    if (entity.children.isEmpty) {
      activities.addAll(await _completeTask(entity));
    } else {
      for (final child in entity.children) {
        if (entity.isCompleted || !child.isCompleted) {
          activities.addAll(await _completeTask(child));
        }
      }
    }
    emit(state.copyWith(status: PageStatus.success));

    var newTask = state.task;
    final parentTaskId = newTask.id;
    final sortedActivities = activities.sorted((a, b) {
      // 有 parentId 的（子任务）排在最后
      final aIsChild = a.taskId != parentTaskId;
      final bIsChild = b.taskId != parentTaskId;
      if (aIsChild != bIsChild) {
        return aIsChild ? 1 : -1;
      }
      return a.createdAt.dateTime.compareTo(b.createdAt.dateTime);
    });
    for (final activity in sortedActivities) {
      TaskEntity? currentTask;
      if (activity.taskId == newTask.id) {
        currentTask = newTask = newTask.copyWith(activity: activity);
      } else {
        final index = newTask.children.indexWhere(
          (child) => child.id == activity.taskId,
        );
        if (index != -1) {
          final newChildren = [...newTask.children];
          currentTask = newChildren[index] = newChildren[index].copyWith(
            activity: activity,
          );
          newTask = newTask.copyWith(children: newChildren);
        }
      }
      emit(state.copyWith(task: newTask));
      await _onNoteCreated(activity, currentTask, createdAt: state.completedAt);
    }
  }

  Future<List<TaskActivity>> _completeTask(TaskEntity task) async {
    final completedAt = state.completedAt;
    final activities = await _tasksRepository.completeTask(
      task,
      completedAt: completedAt,
      // 子任务与父任务的重复规则一致，直接使用传入的 occurrenceAt
      occurrenceAt: state.task.occurrence?.occurrenceAt,
    );
    return activities;
  }

  Future<void> _onNoteCreated(
    TaskActivity activity,
    TaskEntity? task, {
    Jiffy? createdAt,
  }) async {
    if (task == null) return;

    final type = await _settingsRepository.getTaskAutoNoteTypeByTask(task);
    if (type == TaskAutoNoteType.none) return;

    NoteEntity? noteEntity;
    if (type.isCreate) {
      final note = await _notesRepository.create(
        title:
            '${activity.deletedAt == null ? '✅' : '❌'} '
            '${task.title}',
        tags: task.tags,
        taskId: task.id,
        createdAt: createdAt ?? Jiffy.now(),
      );
      if (type == TaskAutoNoteType.createAndEdit) {
        noteEntity = await _notesRepository.getNoteEntityById(note.id);
      }
    } else if (type == TaskAutoNoteType.edit) {
      final note = Note(
        id: const Uuid().v4(),
        title:
            '${activity.deletedAt == null ? '✅' : '❌'} '
            '${task.title}',
        taskId: task.id,
        createdAt: createdAt ?? Jiffy.now(),
        images: [],
      );
      noteEntity = NoteEntity(note: note, tags: task.tags);
    }
    emit(
      state.copyWith(
        status: PageStatus.success,
        currentTaskNote: noteEntity,
      ),
    );
  }
}
