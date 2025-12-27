import 'dart:async';
import 'dart:convert';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_planbook_api/task/supabase_task_api.dart';
import 'package:uuid/uuid.dart';

class TasksRepository {
  TasksRepository({
    required DatabaseTagApi tagApi,
    required SharedPreferences sp,
    required AppDatabase db,
  }) : _db = db,
       _tagApi = tagApi,
       _supabaseTaskApi = SupabaseTaskApi(sp: sp),
       _dbTaskApi = DatabaseTaskApi(db: db, tagApi: tagApi),
       _dbTaskInboxApi = DatabaseTaskInboxApi(db: db, tagApi: tagApi),
       _dbTaskOverdueApi = DatabaseTaskOverdueApi(db: db, tagApi: tagApi),
       _dbTaskTodayApi = DatabaseTaskTodayApi(db: db, tagApi: tagApi),
       _dbTaskCompletionApi = DatabaseTaskCompletionApi(db: db, tagApi: tagApi),
       _dbTaskDelayApi = DatabaseTaskDelayApi(db: db, tagApi: tagApi),
       _dbTaskUpdateApi = DatabaseTaskUpdateApi(db: db, tagApi: tagApi);

  final AppDatabase _db;
  final DatabaseTagApi _tagApi;

  final DatabaseTaskApi _dbTaskApi;
  final DatabaseTaskInboxApi _dbTaskInboxApi;
  final DatabaseTaskOverdueApi _dbTaskOverdueApi;
  final DatabaseTaskTodayApi _dbTaskTodayApi;
  final DatabaseTaskCompletionApi _dbTaskCompletionApi;
  final DatabaseTaskDelayApi _dbTaskDelayApi;
  final DatabaseTaskUpdateApi _dbTaskUpdateApi;

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
    await _supabaseTaskApi.create(
      task: newTask,
      taskTags: taskTags,
      children: newChildren,
    );
    await _dbTaskApi.create(
      task: newTask,
      taskTags: taskTags,
      children: newChildren,
    );
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
    await _supabaseTaskApi.update(
      task: newTask,
      taskTags: taskTags,
      children: newChildren,
    );
    await _dbTaskUpdateApi.update(
      task: newTask,
      taskTags: taskTags,
      children: newChildren,
    );
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

    // 同步到 Supabase
    if (result.originalTaskUpdated != null) {
      await _supabaseTaskApi.update(
        task: result.originalTaskUpdated!,
        taskTags: result.originalTaskTags ?? [],
      );
    }

    if (result.isNewTask) {
      await _supabaseTaskApi.create(
        task: result.updatedTask,
        taskTags: result.taskTags,
        children: result.children,
      );
    } else {
      await _supabaseTaskApi.update(
        task: result.updatedTask,
        taskTags: result.taskTags,
        children: result.children,
      );
    }

    // 保存到本地数据库
    await _dbTaskUpdateApi.saveUpdateResult(result);
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

  Future<void> _syncTasks({
    bool force = false,
  }) async {
    final list = await _supabaseTaskApi.getLatestTasks(force: force);
    if (list.isEmpty) return;
    for (final item in list) {
      print(item);
      final task = Task.fromJson(item);
      print(task);
    }

    await _db.transaction(() async {
      for (final item in list) {
        final task = Task.fromJson(item);
        await _db.into(_db.tasks).insertOnConflictUpdate(task);

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
      }
    });
  }

  Future<TaskEntity?> getTaskEntityById(
    String taskId, {
    Jiffy? occurrenceAt,
  }) async {
    return _dbTaskApi.getTaskEntityById(taskId, occurrenceAt: occurrenceAt);
  }

  Stream<int> getTaskCount({
    required TaskListMode mode,
    Jiffy? date,
    bool? isCompleted,
  }) async* {
    unawaited(_syncTasks());

    yield* switch (mode) {
      TaskListMode.inbox => _dbTaskInboxApi.getInboxTaskCount(
        isCompleted: isCompleted,
        userId: userId,
      ),
      TaskListMode.today => _dbTaskTodayApi.getTodayTaskCount(
        date: date ?? Jiffy.now(),
        isCompleted: isCompleted,
        userId: userId,
      ),
      TaskListMode.overdue =>
        isCompleted ?? false
            ? throw UnimplementedError()
            : _dbTaskOverdueApi.getOverdueTaskCount(
                date: date ?? Jiffy.now(),
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
      TaskListMode.tag => throw UnimplementedError(),
    };
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
      TaskListMode.inbox => _dbTaskTodayApi.getAllInboxTodayTaskEntities(
        tagId: tagId,
        priority: priority,
        isCompleted: isCompleted,
        userId: userId,
      ),
      TaskListMode.overdue => _dbTaskTodayApi.getAllTodayOverdueTaskEntities(
        day: day,
        tagId: tagId,
        priority: priority,
        userId: userId,
      ),
      TaskListMode.tag => throw UnimplementedError(),
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
    await _supabaseTaskApi.complete(activities: activities);
    await _dbTaskCompletionApi.completeTaskByActivities(activities);
    return activities;
  }

  Future<void> deleteTaskById(String taskId) async {
    final task = await _dbTaskApi.deleteTaskById(taskId);
    if (task == null) return;
    await _supabaseTaskApi.deleteByTaskId(taskId);
    await _dbTaskApi.deleteTaskById(taskId);
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
  }) {
    return _dbTaskCompletionApi.getCompletedTaskCount(
      date: date,
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

  Future<void> delayTask({
    required TaskEntity entity,
    required Jiffy delayTo,
  }) async {
    if (entity.dueAt == null &&
        entity.startAt == null &&
        entity.endAt == null) {
      return;
    }

    final newTask = _dbTaskDelayApi.prepareDelayTask(
      entity: entity,
      delayTo: delayTo,
      userId: userId,
    );
    final taskTags = _dbTaskApi.generateTaskTags(
      task: newTask,
      tags: entity.tags,
      userId: userId,
    );

    if (entity.recurrenceRule != null) {
      // 重复任务创建了新的分离实例
      await _supabaseTaskApi.create(
        task: newTask,
        taskTags: taskTags,
      );
      await _dbTaskApi.create(task: newTask, taskTags: taskTags);
    } else {
      // 非重复任务更新了时间
      await _supabaseTaskApi.update(
        task: newTask,
        taskTags: taskTags,
      );
      await _dbTaskUpdateApi.update(task: newTask, taskTags: taskTags);
    }
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

      /// Parse relative date from dueAt field
      /// Supports: "today", "tomorrow", "day+N", "day-N",
      /// and weekdays: "mon", "tue", "wed", "thu", "fri", "sat", "sun"
      if (taskMap['dueAt'] != null) {
        final dueAtStr = taskMap['dueAt'] as String;
        var date = Jiffy.now().toUtc();

        if (dueAtStr == 'tomorrow') {
          date = date.add(days: 1);
        } else if (dueAtStr.startsWith('day+')) {
          final days = int.tryParse(dueAtStr.substring(4)) ?? 0;
          date = date.add(days: days);
        } else if (dueAtStr.startsWith('day-')) {
          final days = int.tryParse(dueAtStr.substring(4)) ?? 0;
          date = date.subtract(days: days);
        } else {
          // Parse weekday: "mon", "tue", "wed", "thu", "fri", "sat", "sun"
          final weekdayMap = {
            'mon': 1,
            'tue': 2,
            'wed': 3,
            'thu': 4,
            'fri': 5,
            'sat': 6,
            'sun': 7,
          };
          final targetWeekday = weekdayMap[dueAtStr.toLowerCase()];
          if (targetWeekday != null) {
            // Get start of this week (Monday) and add days
            date = date.startOf(Unit.week).add(days: targetWeekday - 1);
          }
        }

        task = task.copyWith(dueAt: Value(date));
      }
      final tagNames = List<String>.from(map['tags'] as List<dynamic>);
      final tags = await Future.wait(
        tagNames.map((name) => _tagApi.getTagEntityByName(name, userId)),
      );
      await create(task: task, tags: tags.nonNulls.toList());
    }
  }
}
