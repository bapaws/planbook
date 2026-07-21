import 'package:planbook_api/planbook_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_planbook_api/utils/supabase_sync_utils.dart';

class SupabaseTagApi {
  SupabaseTagApi({
    required SharedPreferences sp,
  }) : _sp = sp;

  final SharedPreferences _sp;
  SupabaseClient? get supabase => AppSupabase.client;

  String? get userId => supabase?.auth.currentUser?.id;

  static const kLastGetTagsTimestamp = 'supabase__last_get_tags_timestamp__';
  static const kLastGetTagsAttemptAt = 'supabase__last_get_tags_attempt_at__';

  Future<void> create({
    required Tag tag,
  }) async {
    if (supabase == null) return;
    await supabase!.from('tags').insert(tag.toJson());
  }

  Future<void> update({
    required Tag tag,
  }) async {
    if (supabase == null) return;
    await supabase!.from('tags').update(tag.toJson()).eq('id', tag.id);
  }

  Future<void> deleteById(String id) async {
    if (supabase == null) return;
    await supabase!
        .from('tags')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
    await supabase!
        .from('task_tags')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('tag_id', id);
    await supabase!
        .from('note_tags')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('tag_id', id);

    final directChildren = await supabase!
        .from('tags')
        .select('id')
        .eq('parent_id', id);
    for (final child in directChildren) {
      await deleteById(child['id'] as String);
    }
  }

  Future<List<Tag>> getLatestTags({bool force = false}) async {
    if (supabase == null) return [];

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final lastAttempt = _sp.getInt(kLastGetTagsAttemptAt);
    if (lastAttempt != null && timestamp - lastAttempt < 3000) {
      return [];
    }
    await _sp.setInt(kLastGetTagsAttemptAt, timestamp);

    final lastTimestamp = _sp.getInt(kLastGetTagsTimestamp);
    var builder = supabase!.from('tags').select();
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

    final response = await builder;

    // 仅在有服务端时间戳时推进游标；空结果保持原游标，避免本机时钟偏快导致漏同步。
    final maxTimestamp = maxTimestampFromSyncItems(response);
    if (maxTimestamp != null) {
      await _sp.setInt(kLastGetTagsTimestamp, maxTimestamp);
    }

    return response.map(Tag.fromJson).toList();
  }
}
