import 'dart:async';

import 'package:planbook_api/planbook_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_planbook_api/utils/supabase_sync_utils.dart';

class SupabaseTaskApi {
  SupabaseTaskApi({
    required SharedPreferences sp,
  }) : _sp = sp;

  final SharedPreferences _sp;

  SupabaseClient? get supabase => AppSupabase.client;

  String? get userId => supabase?.auth.currentUser?.id;

  static const kLastGetTasksTimestamp = 'supabase__last_get_tasks_timestamp__';
  static const kLastGetTasksAttemptAt =
      'supabase__last_get_tasks_attempt_at__';

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
    if (supabase == null) return [];

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final lastAttempt = _sp.getInt(kLastGetTasksAttemptAt);
    if (lastAttempt != null && timestamp - lastAttempt < 3000) {
      return [];
    }
    await _sp.setInt(kLastGetTasksAttemptAt, timestamp);

    final lastTimestamp = _sp.getInt(kLastGetTasksTimestamp);
    var builder = supabase!
        .from('tasks')
        .select(
          '*,task_tags(*,tag:tags!task_tags_tag_id_fkey(*)),task_activities(*)',
        );
    if (!force) {
      if (lastTimestamp != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(
          lastTimestamp,
        ).toIso8601String();
        builder = builder.or(
          'updated_at.gte.$date,created_at.gte.$date,deleted_at.gte.$date',
        );
      }
    }

    final results = await builder;

    // 仅在有服务端时间戳时推进游标；空结果保持原游标，避免本机时钟偏快导致漏同步。
    final maxTimestamp = maxTimestampFromSyncItems(results);
    if (maxTimestamp != null) {
      await _sp.setInt(kLastGetTasksTimestamp, maxTimestamp);
    }

    return results;
  }

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
