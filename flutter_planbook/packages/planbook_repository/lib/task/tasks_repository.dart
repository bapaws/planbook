import 'dart:async';
import 'dart:convert';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/task/alarm_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_planbook_api/task/supabase_task_api.dart';
import 'package:uuid/uuid.dart';

class TasksRepository {
  TasksRepository({
    required DatabaseTagApi tagApi,
    required SharedPreferences sp,
    required AppDatabase db,
    required OutboxApi outboxApi,
    SupabaseTaskApi? supabaseTaskApi,
  }) : _db = db,
       _tagApi = tagApi,
       _supabaseTaskApi = supabaseTaskApi ?? SupabaseTaskApi(sp: sp),
       _dbTaskApi = DatabaseTaskApi(
         db: db,
         tagApi: tagApi,
         outboxApi: outboxApi,
       ),
       _dbTaskInboxApi = DatabaseTaskInboxApi(
         db: db,
         tagApi: tagApi,
         outboxApi: outboxApi,
       ),
       _dbTaskOverdueApi = DatabaseTaskOverdueApi(
         db: db,
         tagApi: tagApi,
         outboxApi: outboxApi,
       ),
       _dbTaskTodayApi = DatabaseTaskTodayApi(
         db: db,
         tagApi: tagApi,
         outboxApi: outboxApi,
       ),
       _dbTaskCompletionApi = DatabaseTaskCompletionApi(
         db: db,
         tagApi: tagApi,
         outboxApi: outboxApi,
       ),
       _dbTaskDelayApi = DatabaseTaskDelayApi(db: db, tagApi: tagApi),
       _dbTaskUpdateApi = DatabaseTaskUpdateApi(
         db: db,
         tagApi: tagApi,
         outboxApi: outboxApi,
       ),
       _dbTaskDeleteApi = DatabaseTaskDeleteApi(
         db: db,
         tagApi: tagApi,
         outboxApi: outboxApi,
       );

  final AppDatabase _db;
  final DatabaseTagApi _tagApi;

  final DatabaseTaskApi _dbTaskApi;
  final DatabaseTaskInboxApi _dbTaskInboxApi;
  final DatabaseTaskOverdueApi _dbTaskOverdueApi;
  final DatabaseTaskTodayApi _dbTaskTodayApi;
  final DatabaseTaskCompletionApi _dbTaskCompletionApi;
  final DatabaseTaskDelayApi _dbTaskDelayApi;
  final DatabaseTaskUpdateApi _dbTaskUpdateApi;
  final DatabaseTaskDeleteApi _dbTaskDeleteApi;

  final SupabaseTaskApi _supabaseTaskApi;

  String? get userId => AppSupabase.client?.auth.currentUser?.id;

  Future<int> getTotalCount() => _dbTaskApi.getTotalCount(userId: userId);

  Future<void> create({
    required Task task,
    List<TagEntity>? tags,
    List<TaskEntity>? children,
  }) async {
    final newTask = task.copyWith(
      userId: Value(userId),
      childCount: children?.length ?? 0,
    );
    final taskTags = _dbTaskApi.generateTaskTags(
      task: newTask,
      tags: tags,
      userId: userId,
    );
    final newChildren = children
        ?.map(
          (e) => e.task.copyWith(
            userId: Value(userId),
            parentId: Value(newTask.id),
            layer: newTask.layer + 1,
            priority: Value(newTask.priority),
            startAt: Value(newTask.startAt),
            endAt: Value(newTask.endAt),
            isAllDay: newTask.isAllDay,
            recurrenceRule: Value(newTask.recurrenceRule),
          ),
        )
        .toList();
    await _dbTaskApi.create(
      task: newTask,
      taskTags: taskTags,
      children: newChildren,
    );
    unawaited(AppHomeWidget.refreshQuadrantWidgets());
  }

  Future<void> update({
    required Task task,
    List<TagEntity>? tags,
    List<TaskEntity>? children,
  }) async {
    final taskTags = _dbTaskApi.generateTaskTags(
      task: task,
      tags: tags,
      userId: userId,
    );
    final newTask = task.copyWith(
      userId: Value(userId),
      updatedAt: Value(Jiffy.now()),
      childCount: children?.length,
    );
    final newChildren = children
        ?.map(
          (e) => e.task.copyWith(
            userId: Value(userId),
            parentId: Value(newTask.id),
            layer: newTask.layer + 1,
            priority: Value(newTask.priority),
            startAt: Value(newTask.startAt),
            endAt: Value(newTask.endAt),
            isAllDay: newTask.isAllDay,
            recurrenceRule: Value(newTask.recurrenceRule),
          ),
        )
        .toList();
    await _dbTaskUpdateApi.update(
      task: newTask,
      taskTags: taskTags,
      children: newChildren,
    );
    unawaited(AppHomeWidget.refreshQuadrantWidgets());
  }

  /// 使用编辑模式更新重复任务
  ///
  /// 根据 editMode 处理：
  /// - thisEventOnly: 创建分离实例
  /// - thisAndFutureEvents: 分裂重复序列
  /// - allEvents: 修改整个重复序列
  ///
  /// 业务层应先调用 [needsEditModeSelection] 判断是否需要让用户选择编辑模式
  Future<void> updateWithEditMode({
    required TaskEntity entity,
    required Task task,
    required RecurringTaskEditMode editMode,
    List<TagEntity>? tags,
    List<TaskEntity>? children,
    Jiffy? occurrenceAt,
  }) async {
    // allEvents 模式直接更新
    if (editMode == RecurringTaskEditMode.allEvents) {
      await update(task: task, tags: tags, children: children);
      return;
    }

    // 使用编辑模式处理重复任务
    final result = _dbTaskUpdateApi.prepareUpdate(
      entity: entity,
      updatedTask: task,
      tags: tags,
      children: children,
      occurrenceAt: occurrenceAt,
      userId: userId,
      editMode: editMode,
    );

    // 保存到本地数据库
    await _dbTaskUpdateApi.saveUpdateResult(result);
    unawaited(AppHomeWidget.refreshQuadrantWidgets());
  }

  /// 判断是否需要让用户选择编辑模式
  ///
  /// 返回 true 时，业务层应显示编辑模式选择对话框：
  /// - 仅此事件
  /// - 此事件及将来事件
  /// - 所有事件
  ///
  /// 返回 false 的情况：
  /// - 不是重复任务
  /// - 重复任务没有任何分离实例（从未被修改、完成或跳过）
  Future<bool> needsEditModeSelection(TaskEntity entity) async {
    final isRecurring = entity.task.recurrenceRule != null;
    if (!isRecurring) return false;

    // 检查是否有分离实例
    final hasDetached = await _dbTaskUpdateApi.hasDetachedInstances(
      entity.task.id,
    );
    return hasDetached;
  }

  Future<void> syncTasks({
    bool force = false,
  }) async {
    final list = await _supabaseTaskApi.getLatestTasks(force: force);
    if (list.isEmpty) return;

    final syncedTasks = <Task>[];
    await _db.transaction(() async {
      for (final item in list) {
        final task = Task.fromJson(item);

        // 如果本地还有该记录的待同步变更，优先保留本地版本，避免远程旧数据覆盖。
        final hasPending = await _dbTaskApi.hasPendingChanges(task.id);
        if (hasPending) continue;

        syncedTasks.add(task);
        await _db.into(_db.tasks).insertOnConflictUpdate(task);

        // 分离实例到达时，压制主系列对应日期的 occurrence，避免他机重复显示。
        final detachedFromId = task.detachedFromTaskId;
        final detachedAt = task.detachedRecurrenceAt;
        if (detachedFromId != null && detachedAt != null) {
          final parent = await (_db.select(
            _db.tasks,
          )..where((t) => t.id.equals(detachedFromId))).getSingleOrNull();
          if (parent != null) {
            await _dbTaskDelayApi.ensureSoftDeleteOccurrence(
              taskId: detachedFromId,
              occurrenceAt: detachedAt,
              task: parent,
            );
          }
        }

        if (item['task_tags'] is List<dynamic>) {
          for (final taskTag in item['task_tags'] as List<dynamic>) {
            final map = taskTag as Map<String, dynamic>;
            final tagMap = map['tag'] as Map<String, dynamic>?;
            if (tagMap == null) continue;
            final tag = Tag.fromJson(tagMap);
            await _db.into(_db.tags).insertOnConflictUpdate(tag);
            await _db
                .into(_db.taskTags)
                .insertOnConflictUpdate(
                  TaskTag.fromJson(map),
                );
          }
        }

        if (item['task_activities'] is List<dynamic>) {
          for (final taskActivity in item['task_activities'] as List<dynamic>) {
            final map = taskActivity as Map<String, dynamic>;
            final taskActivityMap = TaskActivity.fromJson(map);
            await _db
                .into(_db.taskActivities)
                .insertOnConflictUpdate(taskActivityMap);
          }
        }
      }
    });

    // scheduleForTask 内部会先 cancelForTask(task.id) 再调度，不会重复创建
    for (final task in syncedTasks) {
      if (task.alarms.isEmpty) continue;
      final startAt = task.startAt ?? task.dueAt;
      if (startAt == null) continue;
      unawaited(AlarmNotificationService.instance.scheduleForTask(task));
    }
  }

  /// 滚动补 schedule：为所有带闹钟的重复任务重新调度，使预约窗口始终覆盖「从现在起」的未来一段时间。
  /// 应在应用启动和从后台回到前台时调用。
  Future<void> rescheduleAllRecurringAlarms() async {
    final tasks = await _dbTaskApi.getRecurringTasksWithAlarms(userId: userId);
    for (final task in tasks) {
      try {
        await AlarmNotificationService.instance.scheduleForTask(task);
      } on Object catch (e) {
        debugPrint(
          'TasksRepository.rescheduleAllRecurringAlarms: '
          'failed task=${task.id} $e',
        );
      }
    }
  }

  Future<TaskEntity?> getTaskEntityById(
    String taskId, {
    Jiffy? occurrenceAt,
  }) async {
    return _dbTaskApi.getTaskEntityById(taskId, occurrenceAt: occurrenceAt);
  }

  /// 按关键词搜索任务（标题 / 备注内容）
  Future<List<TaskEntity>> search(String query) {
    return _dbTaskApi.searchTaskEntities(query: query, userId: userId);
  }

  Stream<int> getTaskCount({
    required TaskListMode mode,
    Jiffy? date,
    TaskPriority? priority,
    bool? isCompleted,
  }) async* {
    unawaited(syncTasks());

    yield* switch (mode) {
      TaskListMode.inbox => _dbTaskInboxApi.getInboxTaskCount(
        date: date,
        isCompleted: isCompleted,
        priority: priority,
        userId: userId,
      ),
      TaskListMode.today => _dbTaskTodayApi.getTodayTaskCount(
        date: date ?? Jiffy.now(),
        priority: priority,
        isCompleted: isCompleted,
        userId: userId,
      ),
      TaskListMode.overdue =>
        isCompleted ?? false
            ? throw UnimplementedError()
            : _dbTaskOverdueApi.getOverdueTaskCount(
                date: date ?? Jiffy.now(),
                priority: priority,
                userId: userId,
              ),
      TaskListMode.tag => throw UnimplementedError(),
    };
  }

  Stream<List<TaskEntity>> getTaskEntities({
    required Jiffy date,
    required TaskListMode mode,
    TaskPriority? priority,
    String? tagId,
    bool? isCompleted,
  }) {
    return switch (mode) {
      TaskListMode.inbox => _dbTaskInboxApi.getInboxTaskEntities(
        tagId: tagId,
        priority: priority,
        isCompleted: isCompleted,
        userId: userId,
      ),
      TaskListMode.today => _dbTaskTodayApi.getTaskEntities(
        date: date,
        tagId: tagId,
        priority: priority,
        isCompleted: isCompleted,
        userId: userId,
      ),
      TaskListMode.overdue => _dbTaskOverdueApi.getOverdueTaskEntities(
        date: date,
        tagId: tagId,
        priority: priority,
        userId: userId,
      ),
      TaskListMode.tag => tagId == null
          ? Stream.value(const <TaskEntity>[])
          : _dbTaskApi.getTaskEntitiesByTags(
              tagIds: [tagId],
              isCompleted: isCompleted,
              userId: userId,
            ),
    };
  }

  /// 获取指定标签下的任务
  Stream<List<TaskEntity>> getTaskEntitiesByTag({
    required String tagId,
    bool? isCompleted,
  }) {
    return getTaskEntitiesByTags(
      tagIds: [tagId],
      isCompleted: isCompleted,
    );
  }

  /// 获取指定多个标签下的任务（命中任一标签即可）
  Stream<List<TaskEntity>> getTaskEntitiesByTags({
    required List<String> tagIds,
    bool? isCompleted,
  }) {
    return _dbTaskApi.getTaskEntitiesByTags(
      tagIds: tagIds,
      isCompleted: isCompleted,
      userId: userId,
    );
  }

  /// 获取所有今天需要执行的任务，包括今天未完成和已完成任务
  Stream<List<TaskEntity>> getAllTodayTaskEntities({
    TaskListMode mode = TaskListMode.today,
    Jiffy? day,
    String? tagId,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return switch (mode) {
      TaskListMode.today => _dbTaskTodayApi.getAllTodayTaskEntities(
        day: day,
        tagId: tagId,
        priority: priority,
        isCompleted: isCompleted,
        userId: userId,
      ),
      TaskListMode.inbox => _dbTaskInboxApi.getAllInboxTodayTaskEntities(
        tagId: tagId,
        priority: priority,
        isCompleted: isCompleted,
        userId: userId,
      ),
      TaskListMode.overdue => _dbTaskOverdueApi.getAllTodayOverdueTaskEntities(
        day: day,
        tagId: tagId,
        priority: priority,
        userId: userId,
      ),
      TaskListMode.tag => tagId == null
          ? Stream.value(const <TaskEntity>[])
          : _dbTaskApi.getTaskEntitiesByTags(
              tagIds: [tagId],
              isCompleted: isCompleted,
              userId: userId,
            ),
    };
  }

  /// 切换任务完成状态
  ///
  /// 任务未完成时创建 TaskActivity，任务已完成时软删除对应记录。
  /// 同时根据子任务状态递归更新上级任务。
  /// 切换任务完成状态
  ///
  /// 通过查询数据库检查当前任务是否完成，如果已完成则取消完成，如果未完成则完成
  /// 同时根据子任务状态递归更新上级任务。
  ///
  /// 返回所有创建或标记删除的 taskActivities 对象
  Future<List<TaskActivity>> completeTask(
    TaskEntity entity, {
    Jiffy? completedAt,
    Jiffy? occurrenceAt,
  }) async {
    final activities = await _dbTaskCompletionApi.completeTask(
      entity,
      completedAt: completedAt,
      occurrenceAt: occurrenceAt,
    );
    if (userId != null) {
      for (var i = 0; i < activities.length; i++) {
        activities[i] = activities[i].copyWith(userId: Value(userId));
      }
    }
    await _dbTaskCompletionApi.completeTaskByActivities(activities);
    unawaited(AppHomeWidget.refreshQuadrantWidgets());
    return activities;
  }

  Future<void> deleteTaskById(String taskId) async {
    await _dbTaskApi.deleteTaskById(taskId);
    unawaited(AppHomeWidget.refreshQuadrantWidgets());
  }

  /// 根据删除模式删除重复任务
  ///
  /// [entity] 要删除的任务实体
  /// [mode] 重复任务的删除模式
  /// [occurrenceAt] 重复任务的发生时间（用于标识是哪个实例被删除）
  ///
  /// 返回：thisAndFutureEvents 模式下返回更新后的主任务，用于重新调度提醒
  Future<Task?> deleteRecurringTask({
    required TaskEntity entity,
    required RecurringTaskDeleteMode mode,
    Jiffy? occurrenceAt,
  }) async {
    final deletedTask = await _dbTaskDeleteApi.deleteTask(
      entity: entity,
      mode: mode,
      occurrenceAt: occurrenceAt,
    );
    unawaited(AppHomeWidget.refreshQuadrantWidgets());
    return deletedTask;
  }

  /// 更新任务优先级（用于四象限视图拖动调整）
  Future<void> updateTaskPriority(
    TaskEntity entity,
    TaskPriority newPriority,
  ) async {
    await update(
      task: entity.task.copyWith(priority: Value(newPriority)),
      tags: entity.tags,
    );
  }

  Stream<List<TaskEntity>> getCompletedTaskEntities({
    required Jiffy date,
    TaskPriority? priority,
  }) {
    return _dbTaskCompletionApi.getCompletedTaskEntities(
      date: date,
      priority: priority,
      userId: userId,
    );
  }

  Stream<int> getCompletedTaskCount({
    required Jiffy date,
    TaskPriority? priority,
  }) {
    return _dbTaskCompletionApi.getCompletedTaskCount(
      date: date,
      priority: priority,
      userId: userId,
    );
  }

  Stream<int> getCompletedTaskCountForMonth(
    Jiffy date, {
    TaskPriority? priority,
  }) {
    final startOfMonth = date.startOf(Unit.month);
    final endOfMonth = date.endOf(Unit.month);
    return _dbTaskCompletionApi.getCompletedTaskCountByDateRange(
      startOfMonth,
      endOfMonth,
      priority: priority,
      userId: userId,
    );
  }

  Stream<int> getPlannedTaskCountForMonth(Jiffy date) {
    final startOfMonth = date.startOf(Unit.month);
    final endOfMonth = date.endOf(Unit.month);
    return _dbTaskApi.getPlannedTaskCountByDateRange(
      startOfMonth,
      endOfMonth,
      userId: userId,
    );
  }

  Future<Jiffy?> getStartDate() async {
    return _dbTaskApi.getStartDate();
  }

  /// 延迟任务到指定时间（Apple Calendar 风格）
  ///
  /// 对于非重复任务：直接修改 dueAt/startAt/endAt 时间
  /// 对于重复任务：创建分离实例（仅延迟这一个实例）
  ///
  /// 注意：延迟任务只处理单个实例。如果需要修改整个重复序列，
  /// 应该使用"编辑任务"功能，并让用户选择修改模式。
  ///
  /// [entity] 要延迟的任务实体
  /// [delayTo] 延迟到的目标时间
  ///
  /// 返回延迟后的任务实体；如果是重复任务生成的新分离实例，返回新实例。
  Future<TaskEntity?> delayTask({
    required TaskEntity entity,
    required Jiffy delayTo,
  }) async {
    if (entity.dueAt == null &&
        entity.startAt == null &&
        entity.endAt == null) {
      return null;
    }

    final result = _dbTaskDelayApi.prepareDelayTask(
      entity: entity,
      delayTo: delayTo,
      userId: userId,
    );
    final taskTags = _dbTaskApi.generateTaskTags(
      task: result.task,
      tags: entity.tags,
      userId: userId,
    );

    if (result.isNewTask) {
      // 重复任务创建了新的分离实例
      await _db.transaction(() async {
        await _dbTaskApi.create(
          task: result.task,
          taskTags: taskTags,
          children: result.children,
        );

        // 将原始任务在该日期的 occurrence 标记为 deleted，避免重复显示
        if (result.originalTaskId != null &&
            result.originalOccurrenceAt != null) {
          await _dbTaskDelayApi.softDeleteOccurrence(
            taskId: result.originalTaskId!,
            occurrenceAt: result.originalOccurrenceAt!,
          );
        }

        // 如果原始实例已完成，将完成状态同步到新的分离实例，
        // 并软删除原实例的完成记录，避免完成数重复统计。
        final originalActivity = entity.activity;
        if (originalActivity != null &&
            originalActivity.completedAt != null &&
            originalActivity.deletedAt == null) {
          final now = Jiffy.now();
          final newActivity = TaskActivity(
            id: const Uuid().v4(),
            userId: userId,
            taskId: result.task.id,
            completedAt: originalActivity.completedAt,
            activityType: originalActivity.activityType ?? 'completed',
            startAt: originalActivity.startAt,
            endAt: originalActivity.endAt,
            duration: originalActivity.duration,
            createdAt: now,
          );
          final deletedOriginalActivity = originalActivity.copyWith(
            deletedAt: Value(now),
            updatedAt: Value(now),
          );
          await _dbTaskCompletionApi.completeTaskByActivities([
            newActivity,
            deletedOriginalActivity,
          ]);
        }
      });
    } else {
      // 非重复任务更新了时间
      await _dbTaskUpdateApi.update(
        task: result.task,
        taskTags: taskTags,
        children: result.children,
      );
    }
    unawaited(AppHomeWidget.refreshQuadrantWidgets());
    return _dbTaskApi.getTaskEntityById(result.task.id);
  }

  Future<void> createDefaultTasks({required String languageCode}) async {
    const uuid = Uuid();
    final taskJsonString = await rootBundle.loadString(
      'assets/${kDebugMode ? 'demo' : 'files'}/tasks_$languageCode.json',
    );
    final taskJson = jsonDecode(taskJsonString) as List<dynamic>;
    for (final json in taskJson) {
      final map = json as Map<String, dynamic>;
      final taskMap = map['task'] as Map<String, dynamic>;
      var task = Task.fromJson(taskMap).copyWith(
        id: kDebugMode ? null : uuid.v4(),
      );
      final startOfMonth = Jiffy.now().startOf(Unit.month);
      final diff = startOfMonth
          .diff(Jiffy.parseFromList([2026, 1]), unit: Unit.day)
          .toInt();
      if (task.dueAt != null) {
        task = task.copyWith(dueAt: Value(task.dueAt!.add(days: diff)));
      } else if (taskMap['dueAt'] == 'today') {
        task = task.copyWith(dueAt: Value(Jiffy.now().startOf(Unit.day)));
      }

      final tagNames = List<String>.from(map['tags'] as List<dynamic>);
      final tags = await Future.wait(
        tagNames.map((name) => _tagApi.getTagEntityByName(name, userId)),
      );
      await create(task: task, tags: tags.nonNulls.toList());
    }
  }
}
