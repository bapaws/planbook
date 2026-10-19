import 'package:planbook_api/planbook_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_planbook_api/sync/remote_table_pull.dart';

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
    final client = supabase;
    final account = userId;
    if (client == null || account == null) return [];
    final pull = RemoteTablePull.supabase(
      sp: _sp,
      client: client,
      account: account,
    );
    final batches = <String, RemoteTableBatch>{};
    for (final table in ['tags', 'notes', 'note_tags']) {
      batches[table] = await pull.pull(table, force: force);
    }
    return RemoteSyncRows(batches, 'notes');
  }

  static String cursorKey(String? userId) =>
      '$kLastGetNotesTimestamp${userId ?? "guest"}';
}
