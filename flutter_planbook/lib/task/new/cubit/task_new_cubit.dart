import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:uuid/uuid.dart';

part 'task_new_state.dart';

class TaskNewCubit extends HydratedCubit<TaskNewState> {
  TaskNewCubit({
    required TasksRepository tasksRepository,
    TaskEntity? initialTask,
  }) : _tasksRepository = tasksRepository,
       super(
         TaskNewState.fromData(task: initialTask),
       );

  final TasksRepository _tasksRepository;

  @override
  TaskNewState? fromJson(Map<String, dynamic> json) {
    return TaskNewState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(TaskNewState state) {
    // 只在创建新任务时保存草稿（initialTask == null）
    if (state.initialTask != null) {
      return null; // 不保存编辑模式的状态
    }
    // 只在有实际内容时保存
    if (state.title.isEmpty &&
        state.tags.isEmpty &&
        state.dueAt == null &&
        state.startAt == null &&
        state.endAt == null &&
        state.priority == TaskPriority.none) {
      return null; // 空状态不保存
    }
    return state.toJson();
  }

  void onFocusChanged(TaskNewFocus focus) {
    emit(state.copyWith(focus: focus));
  }

  void onTitleChanged(String title) {
    emit(state.copyWith(title: title));
  }

  void onPriorityChanged(TaskPriority priority) {
    emit(state.copyWith(priority: priority));
  }

  void onDueAtChanged(Jiffy? dueAt) {
    emit(state.copyWith(dueAt: () => dueAt?.startOf(Unit.day)));
  }

  void onStartAtChanged(Jiffy? startAt) {
    emit(state.copyWith(startAt: () => startAt));
  }

  void onEndAtChanged(Jiffy? endAt) {
    emit(state.copyWith(endAt: () => endAt));
  }

  void onTagsChanged(List<TagEntity> tags) {
    emit(state.copyWith(tags: tags));
  }

  Future<void> onSave() async {
    emit(state.copyWith(status: PageStatus.loading));

    final initialTask = state.initialTask;
    if (initialTask == null) {
      final task = Task(
        id: const Uuid().v4(),
        title: state.title,
        priority: state.priority,
        dueAt: state.dueAt?.startOf(Unit.day),
        startAt: state.startAt,
        endAt: state.endAt,
        order: 0,
        isAllDay: false,
        alarms: [],
        createdAt: Jiffy.now(),
        layer: 0,
        childCount: 0,
      );
      await _tasksRepository.create(
        task: task,
        tags: state.tags,
      );
      await clear();
      // clear() 只清除持久化存储，需要手动重置状态
      emit(const TaskNewState(status: PageStatus.success));
    } else {
      final task = Task(
        id: initialTask.id,
        title: state.title,
        priority: state.priority,
        dueAt: state.dueAt?.startOf(Unit.day),
        startAt: state.startAt,
        endAt: state.endAt,
        order: initialTask.order,
        isAllDay: initialTask.isAllDay,
        alarms: initialTask.alarms ?? [],
        parentId: initialTask.parentId,
        recurrenceRule: initialTask.recurrenceRule,
        createdAt: initialTask.createdAt,
        updatedAt: Jiffy.now(),
        layer: 0,
        childCount: 0,
      );
      await _tasksRepository.update(
        task: task,
        tags: state.tags,
      );
      emit(state.copyWith(status: PageStatus.success));
    }
  }
}
