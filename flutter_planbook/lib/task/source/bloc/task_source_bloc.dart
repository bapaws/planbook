import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/task/service/task_action_service.dart';
import 'package:flutter_planbook/task/source/model/task_source_panel_type.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:uuid/uuid.dart';

part 'task_source_event.dart';
part 'task_source_state.dart';

class TaskSourcePanelBloc
    extends Bloc<TaskSourcePanelEvent, TaskSourcePanelState> {
  TaskSourcePanelBloc({
    required TasksRepository tasksRepository,
    required TagsRepository tagsRepository,
    required TaskActionService taskActionService,
  }) : _tasksRepository = tasksRepository,
       _tagsRepository = tagsRepository,
       _taskActionService = taskActionService,
       super(const TaskSourcePanelState()) {
    on<TaskSourcePanelLoaded>(_onLoaded, transformer: sequential());
    on<TaskSourcePanelSourceChanged>(
      _onSourceChanged,
      transformer: sequential(),
    );
    on<TaskSourcePanelVisibilityChanged>(
      _onVisibilityChanged,
      transformer: sequential(),
    );
    on<TaskSourcePanelTagChanged>(_onTagChanged, transformer: sequential());
    on<TaskSourcePanelDateChanged>(_onDateChanged, transformer: sequential());
    on<TaskSourcePanelFilterChanged>(
      _onFilterChanged,
      transformer: sequential(),
    );
    // 唯一持有 emit.forEach 的入口；Loaded / SourceChanged / FilterChanged
    // 只改状态后派发本事件，避免多路 forEach 并发互相覆盖列表。
    on<TaskSourcePanelTasksSubscriptionRequested>(
      _onTasksSubscriptionRequested,
      transformer: restartable(),
    );
    on<TaskSourcePanelTaskDropped>(_onTaskDropped, transformer: sequential());
    on<TaskSourcePanelTaskDragCompleted>(
      _onTaskDragCompleted,
      transformer: sequential(),
    );
    on<TaskSourcePanelTaskCompleted>(
      _onTaskCompleted,
      transformer: sequential(),
    );
  }

  final TasksRepository _tasksRepository;
  final TagsRepository _tagsRepository;
  final TaskActionService _taskActionService;

  /// 刚被目标事件处理过的任务 ID。
  ///
  /// 用于区分「同 BLoC 内拖拽」（目标事件已更新列表）和「跨 BLoC 拖拽」。
  final Set<String> _justDroppedTaskIds = {};

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
    add(const TaskSourcePanelTasksSubscriptionRequested());
  }

  Future<void> _onSourceChanged(
    TaskSourcePanelSourceChanged event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    emit(
      state.copyWith(
        sourceType: event.sourceType,
        optimisticRemovedTaskIds: const {},
        optimisticUpdatedTasks: const [],
      ),
    );
    add(const TaskSourcePanelTasksSubscriptionRequested());
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
    final current = state.sourceType;
    final filter = current is TaskSourcePanelDate
        ? current.filter
        : TaskSourcePanelDateFilter.all;
    emit(
      state.copyWith(
        sourceDate: () => event.date,
      ),
    );
    add(
      TaskSourcePanelSourceChanged(
        TaskSourcePanelDate(event.date, filter: filter),
      ),
    );
  }

  Future<void> _onFilterChanged(
    TaskSourcePanelFilterChanged event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    emit(
      state.copyWith(
        isCompleted: event.isCompleted,
        selectedTagIdsFilter: event.selectedTagIds,
        optimisticRemovedTaskIds: const {},
        optimisticUpdatedTasks: const [],
      ),
    );
    add(const TaskSourcePanelTasksSubscriptionRequested());
  }

  Future<void> _onTasksSubscriptionRequested(
    TaskSourcePanelTasksSubscriptionRequested event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    await _subscribeTasks(emit);
  }

  /// 按当前数据源类型接收拖入任务：
  /// - 收集箱：清除日期
  /// - 标签：追加所选标签
  /// - 日期（全部/非全天）：改到该日期
  /// - 日期（全天）：设为该日全天任务
  Future<void> _onTaskDropped(
    TaskSourcePanelTaskDropped event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    final task = event.task;
    switch (state.sourceType) {
      case TaskSourcePanelInbox():
        final isInbox =
            task.startAt == null && task.endAt == null && task.dueAt == null;
        if (isInbox) {
          // 无变更：仍登记，避免并发的 DragCompleted 误删。
          _justDroppedTaskIds.add(task.id);
          return;
        }
        final updatedTask = task.copyWith(
          task: task.task.copyWith(
            startAt: const Value(null),
            endAt: const Value(null),
            dueAt: const Value(null),
          ),
        );
        emit(
          state.copyWith(
            tasks: _replaceTask(state.tasks, updatedTask),
            optimisticUpdatedTasks: _optimisticUpdatedTasksWith(updatedTask),
          ),
        );
        _justDroppedTaskIds.add(task.id);
        await _tasksRepository.update(
          task: updatedTask.task,
          tags: task.tags,
          children: task.children.isEmpty ? null : task.children,
        );
        _justDroppedTaskIds.remove(task.id);
      case TaskSourcePanelTag(tags: final tags):
        final existingIds = task.tags.map((t) => t.id).toSet();
        final toAdd = tags
            .where((tag) => !existingIds.contains(tag.id))
            .toList();
        if (toAdd.isEmpty) {
          // 即使无实际变更，也标记为已处理，避免同 BLoC 内 dragCompleted 重复移除。
          _justDroppedTaskIds.add(task.id);
          return;
        }
        final updatedTask = task.copyWith(tags: [...task.tags, ...toAdd]);
        emit(
          state.copyWith(
            tasks: _replaceTask(state.tasks, updatedTask),
            optimisticUpdatedTasks: _optimisticUpdatedTasksWith(updatedTask),
          ),
        );
        _justDroppedTaskIds.add(task.id);
        await _tasksRepository.update(
          task: task.task,
          tags: updatedTask.tags,
          children: task.children.isEmpty ? null : task.children,
        );
        _justDroppedTaskIds.remove(task.id);
      case TaskSourcePanelDate(date: final date, filter: final filter):
        final targetDate = date.startOf(Unit.day);
        final taskDay = (task.occurrenceAt ?? task.startAt ?? task.dueAt)
            ?.startOf(Unit.day);
        final sameDay =
            taskDay != null && taskDay.isSame(targetDate, unit: Unit.day);

        if (filter == TaskSourcePanelDateFilter.allDay) {
          // 全天过滤：落到该日并设为全天
          if (task.isAllDay && sameDay) {
            _justDroppedTaskIds.add(task.id);
            return;
          }
          final updatedTask = task.copyWith(
            task: task.task.copyWith(
              startAt: Value(targetDate),
              endAt: Value(targetDate.endOf(Unit.day)),
              isAllDay: true,
            ),
          );
          emit(
            state.copyWith(
              tasks: _replaceTask(state.tasks, updatedTask),
              optimisticUpdatedTasks: _optimisticUpdatedTasksWith(updatedTask),
            ),
          );
          _justDroppedTaskIds.add(task.id);
          await _tasksRepository.update(
            task: updatedTask.task,
            tags: task.tags,
            children: task.children.isEmpty ? null : task.children,
          );
          _justDroppedTaskIds.remove(task.id);
          return;
        }

        // 全部 / 非全天：改到该日期
        if (sameDay) {
          _justDroppedTaskIds.add(task.id);
          return;
        }
        final hasDate =
            task.startAt != null || task.dueAt != null || task.endAt != null;
        final updatedTask = task.copyWith(
          task: task.task.copyWith(
            startAt: Value(targetDate),
            endAt: Value(targetDate.endOf(Unit.day)),
            isAllDay: true,
          ),
        );
        emit(
          state.copyWith(
            tasks: _replaceTask(state.tasks, updatedTask),
            optimisticUpdatedTasks: _optimisticUpdatedTasksWith(updatedTask),
          ),
        );
        _justDroppedTaskIds.add(task.id);
        if (!hasDate) {
          await _tasksRepository.update(
            task: updatedTask.task,
            tags: task.tags,
            children: task.children.isEmpty ? null : task.children,
          );
        } else {
          await _tasksRepository.delayTask(
            entity: task,
            delayTo: targetDate,
          );
        }
        _justDroppedTaskIds.remove(task.id);
    }
  }

  /// 拖拽被接受后，按需从 Source Panel 乐观移除任务。
  ///
  /// 如果该任务刚被同 BLoC 内的目标事件处理过（同列表内拖拽），
  /// 目标事件已经更新了状态，这里不再重复移除。
  ///
  /// 跨 BLoC 拖出时也不总是移除：例如「当天全部 / 非全天」拖到时间块后
  /// 任务仍属于当前列表，应保留；收集箱、当天「全天」拖出后通常不再匹配。
  Future<void> _onTaskDragCompleted(
    TaskSourcePanelTaskDragCompleted event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    if (_justDroppedTaskIds.remove(event.task.id)) {
      // 同 BLoC 内拖拽，目标事件已处理，无需移除。
      return;
    }
    if (!_shouldOptimisticRemoveOnExternalDrop()) {
      return;
    }
    emit(
      state.copyWith(
        tasks: _removeTask(state.tasks, event.task.id),
        optimisticRemovedTaskIds: {
          ...state.optimisticRemovedTaskIds,
          event.task.id,
        },
      ),
    );
  }

  /// 完成 / 取消完成任务，并处理自动笔记。
  Future<void> _onTaskCompleted(
    TaskSourcePanelTaskCompleted event,
    Emitter<TaskSourcePanelState> emit,
  ) async {
    final task = event.task;
    // 完成按钮是切换：当前未完成则完成，当前已完成则取消完成。
    final isCompleting = !task.isCompleted;

    final optimisticTask = isCompleting
        ? task.copyWith(
            activity: () => TaskActivity(
              id: const Uuid().v4(),
              createdAt: Jiffy.now(),
              taskId: task.id,
              occurrenceAt: task.occurrence?.occurrenceAt,
              completedAt: Jiffy.now(),
              activityType: 'completed',
            ),
          )
        : task.copyWith(activity: () => null);

    emit(
      state.copyWith(
        tasks: _optimisticTasksWith(optimisticTask),
        optimisticUpdatedTasks: _optimisticUpdatedTasksWith(optimisticTask),
        optimisticRemovedTaskIds: state.optimisticRemovedTaskIds.difference({
          task.id,
        }),
      ),
    );

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
      final taskId = activity.taskId;
      if (taskId == null) continue;
      final completedTask = await _tasksRepository.getTaskEntityById(taskId);
      if (completedTask == null) continue;

      final noteEntity = await _taskActionService.resolveAutoNote(
        activity: activity,
        task: completedTask,
      );
      if (noteEntity != null) {
        emit(state.copyWith(currentTaskNote: noteEntity));
      }
    }
  }

  /// 跨 BLoC 拖出被接受后，是否应对源列表做乐观移除。
  ///
  /// - 收集箱：落到时间块/日期后离开收集箱 → 移除
  /// - 当天全天：落到时间块后变为非全天 → 移除
  /// - 当天全部 / 非全天：改时间仍属于该日该过滤 → 不移除（stream 纠正跨日等）
  /// - 标签：标签通常仍匹配 → 不移除（stream 纠正）
  bool _shouldOptimisticRemoveOnExternalDrop() {
    return switch (state.sourceType) {
      TaskSourcePanelInbox() => true,
      TaskSourcePanelDate(filter: TaskSourcePanelDateFilter.allDay) => true,
      TaskSourcePanelDate() => false,
      TaskSourcePanelTag() => false,
    };
  }

  /// 用 [newTask] 替换列表中相同 ID 的任务；不存在则追加。
  List<TaskEntity> _replaceTask(List<TaskEntity> tasks, TaskEntity newTask) {
    final index = tasks.indexWhere((t) => t.id == newTask.id);
    if (index == -1) return [...tasks, newTask];
    return [...tasks]..[index] = newTask;
  }

  /// 用 [newTask] 替换列表中相同 ID 的任务；不满足当前完成状态筛选时改为移除。
  List<TaskEntity> _optimisticTasksWith(TaskEntity newTask) {
    if (state.isCompleted != null &&
        newTask.isCompleted != state.isCompleted) {
      return _removeTask(state.tasks, newTask.id);
    }
    return _replaceTask(state.tasks, newTask);
  }

  /// 从列表中移除指定 ID 的任务。
  List<TaskEntity> _removeTask(List<TaskEntity> tasks, String taskId) {
    return tasks.where((t) => t.id != taskId).toList();
  }

  /// 更新乐观更新列表中的任务；已存在则替换，不存在则追加。
  List<TaskEntity> _optimisticUpdatedTasksWith(TaskEntity updated) {
    final index = state.optimisticUpdatedTasks.indexWhere(
      (t) => t.id == updated.id,
    );
    if (index == -1) return [...state.optimisticUpdatedTasks, updated];
    return [...state.optimisticUpdatedTasks]..[index] = updated;
  }

  /// 将当前乐观操作应用到 stream 数据上。
  List<TaskEntity> _applyOptimisticOperations(List<TaskEntity> tasks) {
    var processedTasks = tasks;

    for (final updated in state.optimisticUpdatedTasks) {
      final index = processedTasks.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        processedTasks = [...processedTasks]..[index] = updated;
      } else {
        processedTasks = [...processedTasks, updated];
      }
    }

    if (state.optimisticRemovedTaskIds.isNotEmpty) {
      processedTasks = processedTasks
          .where((t) => !state.optimisticRemovedTaskIds.contains(t.id))
          .toList();
    }

    return processedTasks;
  }

  /// 判断两个任务在关键属性上是否一致。
  bool _tasksMatch(TaskEntity a, TaskEntity b) {
    return a.priority == b.priority &&
        _sameMinute(a.startAt, b.startAt) &&
        _sameMinute(a.endAt, b.endAt) &&
        _sameMinute(a.dueAt, b.dueAt) &&
        a.isAllDay == b.isAllDay &&
        a.isCompleted == b.isCompleted;
  }

  bool _sameMinute(Jiffy? a, Jiffy? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.isSame(b, unit: Unit.minute);
  }

  /// 按日期源过滤范围筛选任务
  List<TaskEntity> _applyDateFilter(
    List<TaskEntity> tasks,
    TaskSourcePanelDateFilter filter,
  ) {
    return switch (filter) {
      TaskSourcePanelDateFilter.all => tasks,
      TaskSourcePanelDateFilter.allDay =>
        tasks.where((t) => t.isAllDay).toList(),
      TaskSourcePanelDateFilter.notAllDay =>
        tasks.where((t) => !t.isAllDay).toList(),
    };
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
      TaskSourcePanelDate(date: final date, filter: final filter) =>
        _tasksRepository
            .getAllTodayTaskEntities(
              day: date,
              isCompleted: state.isCompleted,
            )
            .map((tasks) => _applyDateFilter(tasks, filter)),
    };

    await emit.forEach(
      stream,
      onData: _filterTasks,
    );
  }

  TaskSourcePanelState _filterTasks(List<TaskEntity> tasks) {
    final processedTasks = _applyOptimisticOperations(tasks);
    final filteredTasks = state.selectedTagIdsFilter.isEmpty
        ? processedTasks
        : processedTasks
              .where(
                (task) => task.tags.any(
                  (tag) => state.selectedTagIdsFilter.contains(tag.id),
                ),
              )
              .toList();

    // 移除已经反映到 stream 中的乐观操作。
    // 对于重复任务，repository 会创建新 ID 的分离实例，原 ID 从 stream 中消失，
    // 此时也应清除旧 ID 的乐观更新，避免旧任务和新任务同时显示。
    final remainingRemovedIds = state.optimisticRemovedTaskIds
        .where((id) => tasks.any((t) => t.id == id))
        .toSet();
    final remainingUpdatedTasks = state.optimisticUpdatedTasks.where(
      (updated) {
        final streamTask = tasks.firstWhereOrNull(
          (t) => t.id == updated.id,
        );
        if (streamTask == null) return false;
        return !_tasksMatch(streamTask, updated);
      },
    ).toList();

    return state.copyWith(
      status: PageStatus.success,
      tasks: filteredTasks,
      optimisticRemovedTaskIds: remainingRemovedIds,
      optimisticUpdatedTasks: remainingUpdatedTasks,
    );
  }
}
