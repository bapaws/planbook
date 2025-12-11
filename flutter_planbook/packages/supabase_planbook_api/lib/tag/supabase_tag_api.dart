import 'package:planbook_api/planbook_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTagApi {
  SupabaseTagApi({
    required SharedPreferences sp,
  }) : _sp = sp;

  final SharedPreferences _sp;
  SupabaseClient? get supabase => AppSupabase.client;

  String? get userId => supabase?.auth.currentUser?.id;

  static const kLastGetTagsTimestamp = 'supabase__last_get_tags_timestamp__';

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

  Future<void> delete({
    required Tag tag,
  }) async {
    if (supabase == null) return;
    await supabase!.from('tags').delete().eq('id', tag.id);
  }

  Future<List<Tag>> getLatestTags({bool force = false}) async {
    if (supabase == null) return [];

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final lastTimestamp = _sp.getInt(kLastGetTagsTimestamp);
    if (lastTimestamp != null && timestamp - lastTimestamp < 1000) {
      return [];
    }

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

    await _sp.setInt(kLastGetTagsTimestamp, timestamp);

    final response = await builder;
    return response.map(Tag.fromJson).toList();
  }
}
