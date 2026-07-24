import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/task/source/model/task_source_panel_type.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'task_source_event.dart';
part 'task_source_state.dart';

class TaskSourcePanelBloc
    extends Bloc<TaskSourcePanelEvent, TaskSourcePanelState> {
  TaskSourcePanelBloc({
    required TasksRepository tasksRepository,
    required TagsRepository tagsRepository,
  }) : _tasksRepository = tasksRepository,
       _tagsRepository = tagsRepository,
       super(const TaskSourcePanelState()) {
    on<TaskSourcePanelLoaded>(_onLoaded, transformer: restartable());
    on<TaskSourcePanelSourceChanged>(
      _onSourceChanged,
      transformer: restartable(),
    );
    on<TaskSourcePanelVisibilityChanged>(
      _onVisibilityChanged,
      transformer: sequential(),
    );
    on<TaskSourcePanelTagChanged>(_onTagChanged, transformer: restartable());
    on<TaskSourcePanelDateChanged>(_onDateChanged, transformer: restartable());
    on<TaskSourcePanelFilterChanged>(
      _onFilterChanged,
      transformer: restartable(),
    );
    on<TaskSourcePanelTaskDropped>(_onTaskDropped, transformer: sequential());
  }

  final TasksRepository _tasksRepository;
  final TagsRepository _tagsRepository;

  Future<void> _onLoaded(
    TaskSourcePanelLoaded event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    emit(
      state.copyWith(
        isCompleted: event.isCompleted,
        selectedTagIdsFilter: event.selectedTagIds,
      ),
    );
    await _subscribeTasks(emit);
  }

  Future<void> _onSourceChanged(
    TaskSourcePanelSourceChanged event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    emit(state.copyWith(sourceType: event.sourceType));
    await _subscribeTasks(emit);
  }

  Future<void> _onVisibilityChanged(
    TaskSourcePanelVisibilityChanged event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    emit(state.copyWith(isVisible: event.isVisible));
  }

  Future<void> _onTagChanged(
    TaskSourcePanelTagChanged event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    emit(state.copyWith(selectedTagId: event.tagId));
    final tag = await _tagsRepository.getTagEntityById(event.tagId);
    if (tag != null) {
      add(TaskSourcePanelSourceChanged(TaskSourcePanelTag([tag])));
    }
  }

  Future<void> _onDateChanged(
    TaskSourcePanelDateChanged event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    emit(
      state.copyWith(
        sourceDate: () => event.date,
      ),
    );
    add(TaskSourcePanelSourceChanged(TaskSourcePanelDate(event.date)));
  }

  Future<void> _onFilterChanged(
    TaskSourcePanelFilterChanged event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    emit(
      state.copyWith(
        isCompleted: event.isCompleted,
        selectedTagIdsFilter: event.selectedTagIds,
      ),
    );
    await _subscribeTasks(emit);
  }

  /// 按当前数据源类型接收拖入任务：
  /// - 收集箱：清除日期
  /// - 标签：追加所选标签
  /// - 日期：改到该日期
  /// - 全天：设为该日全天任务
  Future<void> _onTaskDropped(
    TaskSourcePanelTaskDropped event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    final task = event.task;
    switch (state.sourceType) {
      case TaskSourcePanelInbox():
        await _moveTaskToInbox(task);
      case TaskSourcePanelTag(tags: final tags):
        await _addTagsToTask(task, tags);
      case TaskSourcePanelDate(date: final date):
        await _moveTaskToDate(task, date);
      case TaskSourcePanelAllDay(date: final date):
        await _moveTaskToAllDay(task, date);
    }
  }

  Future<void> _moveTaskToInbox(TaskEntity task) async {
    final isInbox =
        task.startAt == null && task.endAt == null && task.dueAt == null;
    if (isInbox) return;
    await _tasksRepository.update(
      task: task.task.copyWith(
        startAt: const Value(null),
        endAt: const Value(null),
        dueAt: const Value(null),
      ),
      tags: task.tags,
      children: task.children.isEmpty ? null : task.children,
    );
  }

  Future<void> _addTagsToTask(TaskEntity task, List<TagEntity> tags) async {
    final existingIds = task.tags.map((t) => t.id).toSet();
    final toAdd = tags.where((tag) => !existingIds.contains(tag.id)).toList();
    if (toAdd.isEmpty) return;
    await _tasksRepository.update(
      task: task.task,
      tags: [...task.tags, ...toAdd],
      children: task.children.isEmpty ? null : task.children,
    );
  }

  Future<void> _moveTaskToDate(TaskEntity task, Jiffy date) async {
    final targetDate = date.startOf(Unit.day);
    final taskDay = (task.occurrenceAt ?? task.startAt ?? task.dueAt)?.startOf(
      Unit.day,
    );
    if (taskDay != null && taskDay.isSame(targetDate, unit: Unit.day)) {
      return;
    }

    final hasDate =
        task.startAt != null || task.dueAt != null || task.endAt != null;
    if (!hasDate) {
      await _tasksRepository.update(
        task: task.task.copyWith(
          startAt: Value(targetDate),
          endAt: Value(targetDate.endOf(Unit.day)),
          isAllDay: true,
        ),
        tags: task.tags,
        children: task.children.isEmpty ? null : task.children,
      );
    } else {
      await _tasksRepository.delayTask(
        entity: task,
        delayTo: targetDate,
      );
    }
  }

  Future<void> _moveTaskToAllDay(TaskEntity task, Jiffy date) async {
    final targetDate = date.startOf(Unit.day);
    final taskDay = (task.occurrenceAt ?? task.startAt ?? task.dueAt)?.startOf(
      Unit.day,
    );
    if (task.isAllDay &&
        taskDay != null &&
        taskDay.isSame(targetDate, unit: Unit.day)) {
      return;
    }
    await _tasksRepository.update(
      task: task.task.copyWith(
        startAt: Value(targetDate),
        endAt: Value(targetDate.endOf(Unit.day)),
        isAllDay: true,
      ),
      tags: task.tags,
      children: task.children.isEmpty ? null : task.children,
    );
  }

  Future<void> _subscribeTasks(Emitter<TaskSourcePanelState> emit) async {
    emit(state.copyWith(status: PageStatus.loading));

    final stream = switch (state.sourceType) {
      // getTaskEntities(inbox) 在 tagId 为 null 时只返回无标签任务；
      // Source Panel 需要展示全部收集箱任务。
      TaskSourcePanelInbox() => _tasksRepository.getAllTodayTaskEntities(
        mode: TaskListMode.inbox,
        isCompleted: state.isCompleted,
      ),
      TaskSourcePanelTag(tags: final tags) =>
        _tasksRepository.getTaskEntitiesByTags(
          tagIds: tags.map((tag) => tag.id).toList(),
          isCompleted: state.isCompleted,
        ),
      TaskSourcePanelDate(date: final date) =>
        _tasksRepository.getAllTodayTaskEntities(
          day: date,
          isCompleted: state.isCompleted,
        ),
      TaskSourcePanelAllDay(date: final date) =>
        _tasksRepository
            .getAllTodayTaskEntities(
              day: date,
              isCompleted: state.isCompleted,
            )
            .map(
              (tasks) =>
                  tasks.where((t) => t.parentId == null && t.isAllDay).toList(),
            ),
    };

    await emit.forEach(
      stream,
      onData: _filterTasks,
    );
  }

  TaskSourcePanelState _filterTasks(List<TaskEntity> tasks) {
    final filteredTasks = state.selectedTagIdsFilter.isEmpty
        ? tasks
        : tasks
              .where(
                (task) => task.tags.any(
                  (tag) => state.selectedTagIdsFilter.contains(tag.id),
                ),
              )
              .toList();
    return state.copyWith(
      status: PageStatus.success,
      tasks: filteredTasks,
    );
  }
}
