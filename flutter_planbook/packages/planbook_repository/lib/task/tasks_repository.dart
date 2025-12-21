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
       _dbTaskDelayApi = DatabaseTaskDelayApi(
         db: db,
         tagApi: tagApi,
       );

  final AppDatabase _db;
  final DatabaseTagApi _tagApi;

  final DatabaseTaskApi _dbTaskApi;
  final DatabaseTaskInboxApi _dbTaskInboxApi;
  final DatabaseTaskOverdueApi _dbTaskOverdueApi;
  final DatabaseTaskTodayApi _dbTaskTodayApi;
  final DatabaseTaskCompletionApi _dbTaskCompletionApi;
  final DatabaseTaskDelayApi _dbTaskDelayApi;

  final SupabaseTaskApi _supabaseTaskApi;

  String? get userId => AppSupabase.client?.auth.currentUser?.id;

  Future<int> getTotalCount() => _dbTaskApi.getTotalCount(userId: userId);

  Future<void> create({
    required Task task,
    List<TagEntity>? tags,
  }) async {
    final newTask = task.copyWith(userId: Value(userId));
    final taskTags = _dbTaskApi.generateTaskTags(
      task: newTask,
      tags: tags,
      userId: userId,
    );
    await _supabaseTaskApi.create(task: newTask, taskTags: taskTags);
    await _dbTaskApi.create(task: newTask, taskTags: taskTags);
  }

  Future<void> update({
    required Task task,
    List<TagEntity>? tags,
  }) async {
    final taskTags = _dbTaskApi.generateTaskTags(
      task: task,
      tags: tags,
      userId: userId,
    );
    final newTask = task.copyWith(
      userId: Value(userId),
      updatedAt: Value(Jiffy.now()),
    );
    await _supabaseTaskApi.update(task: newTask, taskTags: taskTags);
    await _dbTaskApi.update(task: newTask, taskTags: taskTags);
  }

  Future<void> _syncTasks({
    bool force = false,
  }) async {
    final list = await _supabaseTaskApi.getLatestTasks(force: force);
    if (list.isEmpty) return;

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

  Future<TaskEntity?> getTaskEntityById(String taskId) async {
    return _dbTaskApi.getTaskEntityById(taskId);
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
    TaskEntity entity,
  ) async {
    final activities = await _dbTaskCompletionApi.completeTask(entity);
    if (userId != null) {
      for (var i = 0; i < activities.length; i++) {
        activities[i] = activities[i].copyWith(userId: Value(userId));
      }
    }
    await _supabaseTaskApi.complete(activities: activities);
    await _dbTaskCompletionApi.completeTaskByActivities(activities);
    return activities;
  }

  Future<TaskActivity?> getTaskActivityForTask(
    Task task, {
    required Jiffy? occurrenceAt,
  }) async {
    return _dbTaskCompletionApi.getTaskActivityForTask(
      task,
      occurrenceAt: occurrenceAt,
    );
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
      await _dbTaskApi.update(task: newTask, taskTags: taskTags);
    }
  }

  Future<void> createDefaultTasks({required String languageCode}) async {
    const uuid = Uuid();
    final taskJsonString = await rootBundle.loadString(
      'assets/files/${kDebugMode ? 'demo_' : ''}tasks_$languageCode.json',
    );
    final taskJson = jsonDecode(taskJsonString) as List<dynamic>;
    for (final json in taskJson) {
      final map = json as Map<String, dynamic>;
      final taskMap = map['task'] as Map<String, dynamic>;
      var task = Task.fromJson(taskMap).copyWith(
        id: kDebugMode ? null : uuid.v4(),
      );

      /// If dueAt is not null, set it to today
      if (taskMap['dueAt'] != null) {
        task = task.copyWith(dueAt: Value(Jiffy.now()));
      }
      final tagNames = List<String>.from(map['tags'] as List<dynamic>);
      final tags = await Future.wait(
        tagNames.map((name) => _tagApi.getTagEntityByName(name, userId)),
      );
      await create(task: task, tags: tags.nonNulls.toList());
    }
  }
}
