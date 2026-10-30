import 'package:planbook_api/planbook_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_planbook_api/sync/remote_table_pull.dart';

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

  Future<RemoteTableBatch?> getLatestTagRows({bool force = false}) async {
    final client = supabase;
    final account = userId;
    if (client == null || account == null) return null;
    return RemoteTablePull.supabase(
      sp: _sp,
      client: client,
      account: account,
    ).pull('tags', force: force);
  }

  Future<List<Tag>> getLatestTags({bool force = false}) async =>
      (await getLatestTagRows(force: force))?.rows.map(Tag.fromJson).toList() ??
      [];
}
