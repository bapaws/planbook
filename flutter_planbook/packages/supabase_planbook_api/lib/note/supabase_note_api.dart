import 'package:planbook_api/planbook_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_planbook_api/utils/supabase_sync_utils.dart';

class SupabaseNoteApi {
  SupabaseNoteApi({
    required SharedPreferences sp,
  }) : _sp = sp;

  final SharedPreferences _sp;
  SupabaseClient? get supabase => AppSupabase.client;

  String? get userId => supabase?.auth.currentUser?.id;

  static const kLastGetNotesTimestamp = 'supabase__last_get_notes_timestamp__';
  static const kLastGetNotesAttemptAt = 'supabase__last_get_notes_attempt_at__';

  Future<void> create({
    required Note note,
    List<NoteTag>? noteTags,
  }) async {
    if (supabase == null) return;
    await supabase!.from('notes').insert(note.toJson());

    if (noteTags != null && noteTags.isNotEmpty) {
      await supabase!
          .from('note_tags')
          .insert(noteTags.map((e) => e.toJson()).toList());
    }
  }

  Future<void> update({
    required Note note,
    List<NoteTag>? noteTags,
  }) async {
    if (supabase == null) return;
    await supabase!.from('notes').update(note.toJson()).eq('id', note.id);

    await supabase!.from('note_tags').delete().eq('note_id', note.id);
    if (noteTags != null && noteTags.isNotEmpty) {
      await supabase!
          .from('note_tags')
          .insert(noteTags.map((e) => e.toJson()).toList());
    }
  }

  Future<void> deleteByNoteId({
    required String noteId,
  }) async {
    if (supabase == null) return;
    await supabase!
        .from('notes')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', noteId);
    await supabase!
        .from('note_tags')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('note_id', noteId);
  }

  Future<List<Map<String, dynamic>>> getLatestNotes({
    bool force = false,
  }) async {
    if (supabase == null) return [];

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final lastAttempt = _sp.getInt(kLastGetNotesAttemptAt);
    if (lastAttempt != null && timestamp - lastAttempt < 3000) {
      return [];
    }
    await _sp.setInt(kLastGetNotesAttemptAt, timestamp);

    final lastTimestamp = _sp.getInt(kLastGetNotesTimestamp);
    var builder = supabase!
        .from('notes')
        .select(
          '*,'
          'note_tags(*,tag:tags!note_tags_tag_id_fkey(*)),'
          'tasks(*)',
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
      await _sp.setInt(kLastGetNotesTimestamp, maxTimestamp);
    }

    return results;
  }
}
