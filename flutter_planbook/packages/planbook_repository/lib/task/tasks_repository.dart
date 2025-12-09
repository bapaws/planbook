import 'dart:async';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class TasksRepository {
  TasksRepository({
    required DatabaseTagApi tagApi,
    required AppDatabase db,
  }) : _dbTaskApi = DatabaseTaskApi(db: db, tagApi: tagApi),
       _dbTaskInboxApi = DatabaseTaskInboxApi(db: db, tagApi: tagApi),
       _dbTaskOverdueApi = DatabaseTaskOverdueApi(db: db, tagApi: tagApi),
       _dbTaskTodayApi = DatabaseTaskTodayApi(db: db, tagApi: tagApi),
       _dbTaskCompletionApi = DatabaseTaskCompletionApi(db: db, tagApi: tagApi);

  final DatabaseTaskApi _dbTaskApi;
  final DatabaseTaskInboxApi _dbTaskInboxApi;
  final DatabaseTaskOverdueApi _dbTaskOverdueApi;
  final DatabaseTaskTodayApi _dbTaskTodayApi;
  final DatabaseTaskCompletionApi _dbTaskCompletionApi;

  Future<void> create({
    required Task task,
    List<TagEntity>? tags,
  }) async {
    await _dbTaskApi.create(task: task, tags: tags);
  }

  Future<void> update({
    required Task task,
    List<TagEntity>? tags,
  }) async {
    await _dbTaskApi.update(task: task, tags: tags);
  }

  Future<TaskEntity?> getTaskEntityById(String taskId) async {
    return _dbTaskApi.getTaskEntityById(taskId);
  }

  Stream<int> getTaskCount({
    required TaskListMode mode,
    Jiffy? date,
    bool? isCompleted,
  }) {
    return switch (mode) {
      TaskListMode.inbox => _dbTaskInboxApi.getInboxTaskCount(
        isCompleted: isCompleted,
      ),
      TaskListMode.today => _dbTaskTodayApi.getTodayTaskCount(
        date: date ?? Jiffy.now(),
        isCompleted: isCompleted,
      ),
      TaskListMode.overdue =>
        isCompleted ?? false
            ? throw UnimplementedError()
            : _dbTaskOverdueApi.getOverdueTaskCount(
                date: date ?? Jiffy.now(),
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
      ),
      TaskListMode.today => _dbTaskTodayApi.getTaskEntities(
        date: date,
        tagId: tagId,
        priority: priority,
        isCompleted: isCompleted,
      ),
      TaskListMode.overdue => _dbTaskOverdueApi.getOverdueTaskEntities(
        date: date,
        tagId: tagId,
        priority: priority,
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
      ),
      TaskListMode.inbox => _dbTaskTodayApi.getAllInboxTodayTaskEntities(
        tagId: tagId,
        priority: priority,
        isCompleted: isCompleted,
      ),
      TaskListMode.overdue => _dbTaskTodayApi.getAllTodayOverdueTaskEntities(
        day: day,
        tagId: tagId,
        priority: priority,
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
    return _dbTaskCompletionApi.completeTask(entity);
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
    await _dbTaskApi.deleteTaskById(taskId);
  }

  Stream<List<TaskEntity>> getCompletedTaskEntities({
    required Jiffy date,
    TaskPriority? priority,
    int limit = 10,
  }) {
    return _dbTaskCompletionApi.getCompletedTaskEntities(
      date: date,
      priority: priority,
      limit: limit,
    );
  }

  Stream<int> getCompletedTaskCount({
    required Jiffy date,
  }) {
    return _dbTaskCompletionApi.getCompletedTaskCount(date: date);
  }

  Future<Jiffy?> getStartDate() async {
    return _dbTaskApi.getStartDate();
  }
}
