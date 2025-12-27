import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTaskApi {
  SupabaseTaskApi({
    required SharedPreferences sp,
  }) : _sp = sp;

  final SharedPreferences _sp;

  SupabaseClient? get supabase => AppSupabase.client;

  String? get userId => supabase?.auth.currentUser?.id;

  static const kLastGetTasksTimestamp = 'supabase__last_get_tasks_timestamp__';

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
    final lastTimestamp = _sp.getInt(kLastGetTasksTimestamp);
    if (lastTimestamp != null && timestamp - lastTimestamp < 3000) {
      return [];
    }

    var builder = supabase!
        .from('tasks')
        .select('*,task_tags(*,tag:tags!task_tags_tag_id_fkey(*))');
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

    await _sp.setInt(kLastGetTasksTimestamp, timestamp);

    return await builder;
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
    if (kDebugMode) {
      await supabase!.from('tasks').delete().eq('id', taskId);
      await supabase!.from('task_tags').delete().eq('task_id', taskId);
    } else {
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
}
