import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/task/service/task_action_service.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'task_list_event.dart';
part 'task_list_state.dart';

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc({
    required TasksRepository tasksRepository,
    required TaskActionService taskActionService,
    TaskListMode mode = TaskListMode.inbox,
    this.priority,
  }) : _tasksRepository = tasksRepository,
       _taskActionService = taskActionService,
       _mode = mode,
       super(const TaskListState()) {
    on<TaskListRequested>(_onRequested, transformer: restartable());
    on<TaskListDayAllRequested>(_onDayAllRequested, transformer: restartable());
    on<TaskListCompleted>(_onCompleted);
    on<TaskListDeleted>(_onDeleted);
    on<TaskListNoteCreated>(_onNoteCreated, transformer: sequential());
    on<TaskListTaskDelayed>(_onTaskDelayed);
    on<TaskListTaskExpanded>(_onTaskExpanded);
    on<TaskListPriorityChanged>(_onPriorityChanged);
  }

  final TasksRepository _tasksRepository;
  final TaskActionService _taskActionService;

  final TaskListMode _mode;
  final TaskPriority? priority;

  Set<String> _selectedTagIds = {};

  Future<void> _onRequested(
    TaskListRequested event,
    Emitter<TaskListState> emit,
  ) async {
    _selectedTagIds = event.selectedTagIds;
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
    _selectedTagIds = event.selectedTagIds;
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
    final filteredTasks = _selectedTagIds.isEmpty
        ? tasks
        : tasks.where((task) =>
            task.tags.any((tag) => _selectedTagIds.contains(tag.id)),
          ).toList();
    final displayedTasks = <TaskEntity>[];
    for (final task in filteredTasks) {
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
      uncompletedTaskCount:
          filteredTasks.where((task) => !task.isCompleted).length,
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
    final activities = await _taskActionService.completeTask(
      task: task,
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
    await _taskActionService.deleteTask(event.taskId);
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

    final noteEntity = await _taskActionService.resolveAutoNote(
      activity: event.activity,
      task: task,
    );
    emit(
      state.copyWith(status: PageStatus.success, currentTaskNote: noteEntity),
    );

    /// 延迟 1 秒后请求评论
    Future.delayed(const Duration(seconds: 1), _requestReview);
  }

  /// 延迟任务到指定时间
  ///
  /// delayTo 非 null 时使用该日期；否则按“已过期→明天、否则→今天”计算。
  /// 对于非重复任务：直接修改 dueAt/startAt/endAt 时间
  /// 对于重复任务：创建分离实例（仅延迟这一个实例）
  Future<void> _onTaskDelayed(
    TaskListTaskDelayed event,
    Emitter<TaskListState> emit,
  ) async {
    Jiffy delayTo;
    if (event.delayTo != null) {
      delayTo = event.delayTo!.startOf(Unit.day);
      final taskDay =
          (event.task.occurrenceAt ?? event.task.startAt ?? event.task.dueAt)
              ?.startOf(Unit.day);
      if (taskDay != null && taskDay.isSame(delayTo, unit: Unit.day)) {
        return;
      }
    } else {
      final endAt = event.task.occurrence?.endAt ?? event.task.endAt;
      if (endAt != null && endAt.isBefore(Jiffy.now())) {
        delayTo = Jiffy.now().add(days: 1);
      } else {
        delayTo = Jiffy.now();
      }
    }
    emit(state.copyWith(status: PageStatus.loading));
    await _tasksRepository.delayTask(
      entity: event.task,
      delayTo: delayTo,
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

  Future<void> _onPriorityChanged(
    TaskListPriorityChanged event,
    Emitter<TaskListState> emit,
  ) async {
    if (event.task.priority == event.targetPriority) return;
    emit(state.copyWith(status: PageStatus.loading));
    await _tasksRepository.updateTaskPriority(
      event.task,
      event.targetPriority,
    );
    emit(state.copyWith(status: PageStatus.success));
  }

  Future<void> _requestReview() async {
    if (kDebugMode) return;
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }
}
