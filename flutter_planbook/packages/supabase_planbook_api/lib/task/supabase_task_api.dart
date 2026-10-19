import 'dart:async';

import 'package:planbook_api/planbook_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_planbook_api/sync/remote_table_pull.dart';

class SupabaseTaskApi {
  SupabaseTaskApi({
    required SharedPreferences sp,
  }) : _sp = sp;

  final SharedPreferences _sp;

  SupabaseClient? get supabase => AppSupabase.client;

  String? get userId => supabase?.auth.currentUser?.id;

  static const kLastGetTasksTimestamp = 'supabase__last_get_tasks_timestamp__';
  static const kLastGetTasksAttemptAt = 'supabase__last_get_tasks_attempt_at__';

  Future<void> create({
    required Task task,
    List<TaskTag>? taskTags,
    List<Task>? children,
  }) async {
    if (supabase == null) return;
    await supabase!.from('tasks').insert([
      task.toJson(),
      ...?children?.map((e) => e.toJson()),
    ]);

    if (taskTags != null && taskTags.isNotEmpty) {
      await supabase!
          .from('task_tags')
          .insert(taskTags.map((e) => e.toJson()).toList());
    }
  }

  Future<void> update({
    required Task task,
    List<TaskTag>? taskTags,
    List<Task>? children,
  }) async {
    if (supabase == null) return;

    // 更新任务
    await supabase!.from('tasks').upsert([
      task.toJson(),
    ], onConflict: 'id').select();

    if (children != null && children.isNotEmpty) {
      await supabase!
          .from('tasks')
          .upsert(children.map((e) => e.toJson()).toList());
    }

    if (taskTags != null) {
      await supabase!.from('task_tags').delete().eq('task_id', task.id);
      if (taskTags.isNotEmpty) {
        await supabase!
            .from('task_tags')
            .insert(taskTags.map((e) => e.toJson()).toList());
      }
    }
  }

  Future<List<Map<String, dynamic>>> getLatestTasks({
    bool force = false,
  }) async {
    final client = supabase;
    final account = userId;
    if (client == null || account == null) return [];
    final pull = RemoteTablePull.supabase(
      sp: _sp,
      client: client,
      account: account,
    );
    final batches = <String, RemoteTableBatch>{};
    for (final table in ['tags', 'tasks', 'task_activities', 'task_tags']) {
      batches[table] = await pull.pull(table, force: force);
    }
    return RemoteSyncRows(batches, 'tasks');
  }

  static String cursorKey(String? userId) =>
      '$kLastGetTasksTimestamp${userId ?? "guest"}';

  Future<void> complete({
    required List<TaskActivity> activities,
  }) async {
    if (supabase == null) return;
    await supabase!
        .from('task_activities')
        .upsert(activities.map((e) => e.toJson()).toList());
  }

  Future<void> deleteByTaskId(String taskId) async {
    if (supabase == null) return;
    await supabase!
        .from('tasks')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', taskId);
    await supabase!
        .from('task_tags')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('task_id', taskId);
  }
}
