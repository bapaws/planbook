import 'package:planbook_api/planbook_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseNoteTaskApi {
  SupabaseNoteTaskApi();

  SupabaseClient? get supabase => AppSupabase.client;

  String? get userId => supabase?.auth.currentUser?.id;

  Future<void> updateTypeNoteContent({
    required List<Note> notes,
  }) async {
    if (supabase == null) return;
    for (final note in notes) {
      await supabase!
          .from('notes')
          .update({
            'content': note.content,
            'updated_at': note.updatedAt?.format(),
          })
          .eq('id', note.id);
    }
  }
}
