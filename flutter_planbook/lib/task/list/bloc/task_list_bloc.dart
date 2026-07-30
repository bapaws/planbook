import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/task/service/task_action_service.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:uuid/uuid.dart';

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
    // TaskListDayAllRequested 继承 TaskListRequested；
    // bloc 的 on<E> 用 `event is E` 过滤，
    // 若同时注册 on<TaskListRequested> 与 on<TaskListDayAllRequested>，
    // 同一事件会进两个 handler，出现 getTaskEntities 与 getAllTodayTaskEntities 两套流竞态，
    // 四象限 UI 会错乱。
    on<TaskListRequested>(_onLoadRequested, transformer: restartable());
    on<TaskListCompleted>(_onCompleted, transformer: sequential());
    on<TaskListDeleteRequested>(_onDeleteRequested);
    on<TaskListDeleteConfirmed>(_onDeleteConfirmed, transformer: sequential());
    on<TaskListNoteCreated>(_onNoteCreated, transformer: sequential());
    on<TaskListTaskDelayed>(_onTaskDelayed, transformer: sequential());
    on<TaskListTaskExpanded>(_onTaskExpanded);
    on<TaskListPriorityChanged>(
      _onPriorityChanged,
      transformer: sequential(),
    );
    on<TaskListTaskScheduled>(_onTaskScheduled, transformer: sequential());
    on<TaskListTaskTimeBlocked>(
      _onTaskTimeBlocked,
      transformer: sequential(),
    );
    on<TaskListTaskAllDayScheduled>(
      _onTaskAllDayScheduled,
      transformer: sequential(),
    );
    on<TaskListTaskDragCompleted>(
      _onTaskDragCompleted,
      transformer: sequential(),
    );
  }

  final TasksRepository _tasksRepository;
  final TaskActionService _taskActionService;

  final TaskListMode _mode;
  final TaskPriority? priority;

  Set<String> _selectedTagIds = {};

  /// 当前列表的单个标签过滤（与 [_selectedTagIds] 不同，这是列表自身的 tagId）。
  String? _tagId;

  /// 刚被目标事件处理过的任务 ID。
  ///
  /// 用于区分「同 BLoC 内拖拽」（目标事件已更新列表）和「跨 BLoC 拖拽」
  /// （源列表需要在 onDragCompleted 时自己移除）。
  final Set<String> _justDroppedTaskIds = {};

  Future<void> _onLoadRequested(
    TaskListRequested event,
    Emitter<TaskListState> emit,
  ) async {
    if (event is TaskListDayAllRequested) {
      await _onDayAllRequested(event, emit);
    } else {
      await _onRequested(event, emit);
    }
  }

  Future<void> _onRequested(
    TaskListRequested event,
    Emitter<TaskListState> emit,
  ) async {
    _selectedTagIds = event.selectedTagIds;
    _tagId = event.tagId;
    final date = event.date ?? state.date ?? Jiffy.now();
    emit(
      state.copyWith(
        status: PageStatus.loading,
        date: date,
        isCompleted: () => event.isCompleted,
      ),
    );
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
    _tagId = event.tagId;
    final date = event.date ?? state.date ?? Jiffy.now();
    emit(
      state.copyWith(
        status: PageStatus.loading,
        date: date,
        isCompleted: () => event.isCompleted,
      ),
    );
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
    final processedTasks = _applyOptimisticOperations(tasks);
    final displayedTasks = _buildDisplayedTasks(processedTasks);

    // 计算未完成任务数时仍用原始 stream 数据，避免乐观添加/移除影响计数。
    final uncompletedTasks = _selectedTagIds.isEmpty
        ? tasks
        : tasks
              .where(
                (task) =>
                    task.tags.any((tag) => _selectedTagIds.contains(tag.id)),
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
      tasks: displayedTasks,
      uncompletedTaskCount: uncompletedTasks
          .where((task) => !task.isCompleted)
          .length,
      optimisticRemovedTaskIds: remainingRemovedIds,
      optimisticUpdatedTasks: remainingUpdatedTasks,
    );
  }

  /// 将当前乐观操作应用到 stream 数据上。
  List<TaskEntity> _applyOptimisticOperations(List<TaskEntity> tasks) {
    var processedTasks = tasks;

    // 先应用更新：stream 中的旧任务被乐观版本替换；不存在的任务若满足查询条件则追加。
    for (final updated in state.optimisticUpdatedTasks) {
      final index = processedTasks.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        processedTasks = [...processedTasks]..[index] = updated;
      } else if (_taskMatchesCurrentQuery(updated)) {
        processedTasks = [...processedTasks, updated];
      }
    }

    // 再应用移除。
    if (state.optimisticRemovedTaskIds.isNotEmpty) {
      processedTasks = processedTasks
          .where((t) => !state.optimisticRemovedTaskIds.contains(t.id))
          .toList();
    }

    return processedTasks;
  }

  /// 判断两个任务在关键属性上是否一致（用于确认 stream 已反映乐观更新）。
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

  bool _sameTagIds(List<TagEntity> a, List<TagEntity> b) {
    if (a.length != b.length) return false;
    final ids = b.map((t) => t.id).toSet();
    return a.every((t) => ids.contains(t.id));
  }

  /// 将原始任务列表按当前选中的标签和展开状态展开为显示列表。
  List<TaskEntity> _buildDisplayedTasks(List<TaskEntity> tasks) {
    final filteredTasks = _selectedTagIds.isEmpty
        ? tasks
        : tasks
              .where(
                (task) =>
                    task.tags.any((tag) => _selectedTagIds.contains(tag.id)),
              )
              .toList();
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
    return displayedTasks;
  }

  /// 用 [newTask] 替换列表中相同 ID 的任务；不存在则追加。
  /// 如果 [newTask] 不再满足当前列表查询条件，则改为移除。
  List<TaskEntity> _optimisticTasksWith(TaskEntity newTask) {
    if (!_taskMatchesCurrentQuery(newTask)) {
      return _removeTask(state.tasks, newTask.id);
    }
    return _replaceTask(state.tasks, newTask);
  }

  /// 更新乐观更新列表中的任务；已存在则替换，不存在则追加。
  List<TaskEntity> _optimisticUpdatedTasksWith(TaskEntity updated) {
    final index = state.optimisticUpdatedTasks.indexWhere(
      (t) => t.id == updated.id,
    );
    if (index == -1) return [...state.optimisticUpdatedTasks, updated];
    return [...state.optimisticUpdatedTasks]..[index] = updated;
  }

  /// 判断任务是否满足当前列表的查询条件（mode / date / priority / tag / 完成状态）。
  bool _taskMatchesCurrentQuery(TaskEntity task) {
    if (priority != null && task.priority != priority) return false;
    if (_tagId != null && !task.tags.any((t) => t.id == _tagId)) return false;
    if (state.isCompleted != null && task.isCompleted != state.isCompleted) {
      return false;
    }

    final taskDay = (task.occurrenceAt ?? task.startAt ?? task.dueAt)?.startOf(
      Unit.day,
    );

    switch (_mode) {
      case TaskListMode.inbox:
        if (task.startAt != null || task.dueAt != null || task.endAt != null) {
          return false;
        }
      case TaskListMode.today:
        final date = state.date;
        if (date == null) return true;
        if (taskDay == null || !taskDay.isSame(date, unit: Unit.day)) {
          return false;
        }
      case TaskListMode.overdue:
        final date = state.date ?? Jiffy.now();
        if (taskDay == null || !taskDay.isBefore(date, unit: Unit.day)) {
          return false;
        }
      case TaskListMode.tag:
        throw UnimplementedError();
    }
    return true;
  }

  /// 用 [newTask] 替换列表中相同 ID 的任务；不存在则追加。
  List<TaskEntity> _replaceTask(List<TaskEntity> tasks, TaskEntity newTask) {
    final index = tasks.indexWhere((t) => t.id == newTask.id);
    if (index == -1) return [...tasks, newTask];
    return [...tasks]..[index] = newTask;
  }

  /// 从列表中移除指定 ID 的任务。
  List<TaskEntity> _removeTask(List<TaskEntity> tasks, String taskId) {
    return tasks.where((t) => t.id != taskId).toList();
  }

  Future<void> _onCompleted(
    TaskListCompleted event,
    Emitter<TaskListState> emit,
  ) async {
    final task = event.task;
    // 完成按钮是切换：当前未完成则完成，当前已完成则取消完成。
    final isCompleting = !task.isCompleted;

    // 根据切换方向构造乐观任务实体。
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

    // 按当前列表的完成状态过滤决定是更新还是移除。
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
      add(TaskListNoteCreated(activity: activity));
    }
  }

  Future<void> _onDeleteRequested(
    TaskListDeleteRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final task = event.task;
    if (task.recurrenceRule == null) {
      emit(
        state.copyWith(
          showDeleteConfirmation: true,
          pendingDeleteTask: () => task,
        ),
      );
    } else {
      emit(
        state.copyWith(
          showDeleteModeSelection: true,
          pendingDeleteTask: () => task,
        ),
      );
    }
  }

  Future<void> _onDeleteConfirmed(
    TaskListDeleteConfirmed event,
    Emitter<TaskListState> emit,
  ) async {
    final task = state.pendingDeleteTask;
    emit(
      state.copyWith(
        showDeleteModeSelection: false,
        showDeleteConfirmation: false,
        pendingDeleteTask: () => null,
      ),
    );
    if (task == null) return;

    final mode = event.mode;
    if (mode == null) return;

    // 同步乐观移除
    emit(
      state.copyWith(
        tasks: _removeTask(state.tasks, task.id),
        optimisticRemovedTaskIds: {
          ...state.optimisticRemovedTaskIds,
          task.id,
        },
      ),
    );

    if (task.recurrenceRule == null ||
        mode == RecurringTaskDeleteMode.allEvents) {
      await _taskActionService.deleteTask(task.id);
    } else {
      await _taskActionService.deleteRecurringTask(
        entity: task,
        mode: mode,
        occurrenceAt: task.occurrence?.occurrenceAt,
      );
    }
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
        // 同日无变更：仍登记，避免并发的 DragCompleted 误删。
        _justDroppedTaskIds.add(event.task.id);
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

    final task = event.task;
    final occurrence = task.occurrence;
    final taskDay = (task.occurrenceAt ?? task.startAt ?? task.dueAt)?.startOf(
      Unit.day,
    );
    final daysDiff = taskDay != null
        ? delayTo.diff(taskDay, unit: Unit.day).toInt()
        : null;

    // 重复任务实例需要同步更新 occurrence，否则乐观位置仍停留在原日期。
    final updatedOccurrence = occurrence?.copyWith(
      occurrenceAt: delayTo,
      startAt: Value(
        daysDiff != null && occurrence.startAt != null
            ? occurrence.startAt!.add(days: daysDiff)
            : delayTo,
      ),
      endAt: Value(
        daysDiff != null && occurrence.endAt != null
            ? occurrence.endAt!.add(days: daysDiff)
            : delayTo.endOf(Unit.day),
      ),
      dueAt: Value(
        daysDiff != null && occurrence.dueAt != null
            ? occurrence.dueAt!.add(days: daysDiff)
            : null,
      ),
    );

    final hasDate =
        task.startAt != null || task.dueAt != null || task.endAt != null;

    // 同步乐观更新日期
    final updatedTask = task.copyWith(
      task: task.task.copyWith(
        startAt: Value(
          daysDiff != null && task.task.startAt != null
              ? task.task.startAt!.add(days: daysDiff)
              : delayTo,
        ),
        endAt: Value(
          daysDiff != null && task.task.endAt != null
              ? task.task.endAt!.add(days: daysDiff)
              : delayTo.endOf(Unit.day),
        ),
        dueAt: Value(
          daysDiff != null && task.task.dueAt != null
              ? task.task.dueAt!.add(days: daysDiff)
              : null,
        ),
        isAllDay: !hasDate || task.task.isAllDay,
      ),
      occurrence: updatedOccurrence,
    );
    emit(
      state.copyWith(
        tasks: _optimisticTasksWith(updatedTask),
        optimisticUpdatedTasks: _optimisticUpdatedTasksWith(updatedTask),
      ),
    );
    _justDroppedTaskIds.add(task.id);

    if (!hasDate) {
      // 无日期任务：直接设置日期
      await _tasksRepository.update(
        task: updatedTask.task,
        tags: task.tags,
        children: task.children.isEmpty ? null : task.children,
      );
    } else if (task.recurrenceRule != null) {
      // 重复任务：创建分离实例
      await _tasksRepository.delayTask(
        entity: task,
        delayTo: delayTo,
      );
    } else {
      await _tasksRepository.delayTask(
        entity: task,
        delayTo: delayTo,
      );
    }
    _justDroppedTaskIds.remove(task.id);
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
    if (event.task.priority == event.targetPriority) {
      // 无变更：仍登记，避免并发的 DragCompleted 误删。
      _justDroppedTaskIds.add(event.task.id);
      return;
    }

    // 同步乐观更新优先级
    final updatedTask = event.task.copyWith(
      task: event.task.task.copyWith(priority: Value(event.targetPriority)),
    );
    emit(
      state.copyWith(
        tasks: _optimisticTasksWith(updatedTask),
        optimisticUpdatedTasks: _optimisticUpdatedTasksWith(updatedTask),
      ),
    );
    _justDroppedTaskIds.add(event.task.id);

    await _tasksRepository.updateTaskPriority(
      event.task,
      event.targetPriority,
    );
    _justDroppedTaskIds.remove(event.task.id);
  }

  Future<void> _onTaskScheduled(
    TaskListTaskScheduled event,
    Emitter<TaskListState> emit,
  ) async {
    final task = event.task;
    final targetDate = event.targetDate.startOf(Unit.day);
    final taskDay = (task.occurrenceAt ?? task.startAt ?? task.dueAt)?.startOf(
      Unit.day,
    );
    final sameDay =
        taskDay != null && taskDay.isSame(targetDate, unit: Unit.day);
    final samePriority = task.priority == event.targetPriority;
    final tagsUnchanged =
        event.tags == null || _sameTagIds(event.tags!, task.tags);
    if (sameDay && samePriority && tagsUnchanged) {
      // 无实际变更：仍登记，避免并发的 DragCompleted 误删。
      _justDroppedTaskIds.add(task.id);
      return;
    }

    // 同步乐观更新：任务移动到目标日期并设置优先级
    final updatedTask = task.copyWith(
      task: task.task.copyWith(
        startAt: Value(targetDate),
        endAt: Value(targetDate.endOf(Unit.day)),
        isAllDay: true,
        priority: Value(event.targetPriority),
      ),
      tags: event.tags ?? task.tags,
    );
    emit(
      state.copyWith(
        tasks: _optimisticTasksWith(updatedTask),
        optimisticUpdatedTasks: _optimisticUpdatedTasksWith(updatedTask),
      ),
    );
    _justDroppedTaskIds.add(task.id);

    final hasDate =
        task.startAt != null || task.dueAt != null || task.endAt != null;

    if (!hasDate) {
      // 无日期任务：设置为当天全天任务并更新优先级
      await _tasksRepository.update(
        task: task.task.copyWith(
          startAt: Value(targetDate),
          endAt: Value(targetDate.endOf(Unit.day)),
          isAllDay: true,
          priority: Value(event.targetPriority),
        ),
        tags: event.tags ?? task.tags,
        children: task.children.isEmpty ? null : task.children,
      );
    } else {
      // 有日期任务：先延迟到当天，再更新优先级
      final delayed = await _tasksRepository.delayTask(
        entity: task,
        delayTo: targetDate,
      );
      final entityToUpdate = delayed ?? task;
      if (entityToUpdate.priority != event.targetPriority ||
          event.tags != null) {
        await _tasksRepository.update(
          task: entityToUpdate.task.copyWith(
            priority: Value(event.targetPriority),
          ),
          tags: event.tags ?? entityToUpdate.tags,
        );
      }
    }
    _justDroppedTaskIds.remove(task.id);
  }

  Future<void> _onTaskTimeBlocked(
    TaskListTaskTimeBlocked event,
    Emitter<TaskListState> emit,
  ) async {
    final task = event.task;
    final startAt = event.startAt;
    final endAt = event.endAt;

    // 先登记，避免随后的 DragCompleted 在网格内改期时误删。
    _justDroppedTaskIds.add(task.id);

    // 时间块布局优先使用 occurrence 的 startAt/endAt，
    // 所以重复任务实例需要同步更新 occurrence，否则乐观位置会弹回旧位置。
    final occurrence = task.occurrence;
    final updatedOccurrence = occurrence?.copyWith(
      startAt: Value(startAt),
      endAt: Value(endAt),
    );

    // 同步乐观更新时间
    final updatedTask = task.copyWith(
      task: task.task.copyWith(
        startAt: Value(startAt),
        endAt: Value(endAt),
        isAllDay: false,
      ),
      occurrence: updatedOccurrence,
    );
    emit(
      state.copyWith(
        tasks: _optimisticTasksWith(updatedTask),
        optimisticUpdatedTasks: _optimisticUpdatedTasksWith(updatedTask),
      ),
    );

    if (task.recurrenceRule != null) {
      // 重复任务：先创建/获取 detached 实例，再更新时间
      final delayed = await _tasksRepository.delayTask(
        entity: task,
        delayTo: startAt.startOf(Unit.day),
      );
      if (delayed != null) {
        await _tasksRepository.update(
          task: delayed.task.copyWith(
            startAt: Value(startAt),
            endAt: Value(endAt),
            isAllDay: false,
          ),
          tags: delayed.tags,
        );
      }
    } else {
      await _tasksRepository.update(
        task: task.task.copyWith(
          startAt: Value(startAt),
          endAt: Value(endAt),
          isAllDay: false,
        ),
        tags: task.tags,
      );
    }
    _justDroppedTaskIds.remove(task.id);
  }

  Future<void> _onTaskAllDayScheduled(
    TaskListTaskAllDayScheduled event,
    Emitter<TaskListState> emit,
  ) async {
    final task = event.task;
    final targetDate = event.date.startOf(Unit.day);
    final taskDay = (task.occurrenceAt ?? task.startAt ?? task.dueAt)?.startOf(
      Unit.day,
    );
    if (task.isAllDay &&
        taskDay != null &&
        taskDay.isSame(targetDate, unit: Unit.day)) {
      // 无变更：仍登记，避免并发的 DragCompleted 误删。
      _justDroppedTaskIds.add(task.id);
      return;
    }

    // 同步乐观更新为全天任务
    final updatedTask = task.copyWith(
      task: task.task.copyWith(
        startAt: Value(targetDate),
        endAt: Value(targetDate.endOf(Unit.day)),
        isAllDay: true,
      ),
    );
    emit(state.copyWith(tasks: _optimisticTasksWith(updatedTask)));
    _justDroppedTaskIds.add(task.id);

    if (task.recurrenceRule != null) {
      final delayed = await _tasksRepository.delayTask(
        entity: task,
        delayTo: targetDate,
      );
      if (delayed != null) {
        await _tasksRepository.update(
          task: delayed.task.copyWith(
            startAt: Value(targetDate),
            endAt: Value(targetDate.endOf(Unit.day)),
            isAllDay: true,
          ),
          tags: delayed.tags,
        );
      }
    } else {
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
    _justDroppedTaskIds.remove(task.id);
  }

  /// 拖拽被接受后，源列表同步移除任务。
  ///
  /// 如果该任务刚被同 BLoC 内的目标事件处理过（同列表内拖拽），
  /// 目标事件已经更新了状态，这里不再重复移除。
  Future<void> _onTaskDragCompleted(
    TaskListTaskDragCompleted event,
    Emitter<TaskListState> emit,
  ) async {
    if (_justDroppedTaskIds.remove(event.task.id)) {
      // 同 BLoC 内拖拽，目标事件已处理，无需移除。
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

  Future<void> _requestReview() async {
    if (kDebugMode) return;
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }
}
