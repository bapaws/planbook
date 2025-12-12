import 'dart:async';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_planbook_api/supabase_planbook_api.dart';
import 'package:uuid/uuid.dart';

class NotesRepository {
  NotesRepository({
    required SharedPreferences sp,
    required AppDatabase db,
    required DatabaseTagApi tagApi,
  }) : _dbNoteApi = DatabaseNoteApi(db: db, tagApi: tagApi),
       _supabaseNoteApi = SupabaseNoteApi(sp: sp),
       _db = db,
       _tagApi = tagApi;

  final DatabaseNoteApi _dbNoteApi;
  final SupabaseNoteApi _supabaseNoteApi;
  final AppDatabase _db;
  final DatabaseTagApi _tagApi;

  String? get userId => AppSupabase.client?.auth.currentUser?.id;

  Future<Note> create({
    required String title,
    String? content,
    List<String>? images,
    List<TagEntity>? tags,
    String? taskId,
    Jiffy? createdAt,
  }) async {
    final noteId = const Uuid().v4();

    final note = Note(
      id: noteId,
      title: title,
      content: content,
      images: images ?? [],
      taskId: taskId,
      createdAt: createdAt ?? Jiffy.now(),
      userId: userId,
    );
    final noteTags = _dbNoteApi.generateNoteTags(
      tags: tags,
      noteId: noteId,
      userId: userId,
    );

    await _supabaseNoteApi.create(note: note, noteTags: noteTags);
    await _dbNoteApi.create(note: note, noteTags: noteTags);
    return note;
  }

  Future<void> update({
    required Note note,
    List<TagEntity>? tags,
  }) async {
    final noteTags = _dbNoteApi.generateNoteTags(
      tags: tags,
      noteId: note.id,
      userId: userId,
    );
    await _supabaseNoteApi.update(note: note, noteTags: noteTags);
    await _dbNoteApi.update(note: note, noteTags: noteTags);
  }

  Future<void> _syncNotes({
    bool force = false,
  }) async {
    final list = await _supabaseNoteApi.getLatestNotes(force: force);
    await _db.transaction(() async {
      for (final item in list) {
        final note = Note.fromJson(item);
        await _db.into(_db.notes).insertOnConflictUpdate(note);

        if (item['note_tags'] is List<dynamic>) {
          for (final noteTag in item['note_tags'] as List<dynamic>) {
            final map = noteTag as Map<String, dynamic>;
            final tagMap = map['tag'] as Map<String, dynamic>?;
            if (tagMap == null) continue;
            final tag = Tag.fromJson(tagMap);
            await _db.into(_db.tags).insertOnConflictUpdate(tag);
            await _db
                .into(_db.noteTags)
                .insertOnConflictUpdate(NoteTag.fromJson(map));
          }
        }
      }
    });
  }

  Future<NoteEntity?> getNoteEntityById(String noteId) async {
    return _dbNoteApi.getNoteEntityById(noteId);
  }

  Stream<List<NoteEntity>> getNoteEntitiesByTaskId(String taskId) {
    return _dbNoteApi.getNoteEntitiesByTaskId(taskId);
  }

  Stream<List<NoteEntity>> getNoteEntitiesByTagId(String tagId) {
    return _dbNoteApi.getNoteEntitiesByTagId(tagId);
  }

  Stream<List<NoteEntity>> getNoteEntitiesByDate(
    Jiffy date, {
    List<String>? tagIds,
  }) {
    _syncNotes();
    return _dbNoteApi.getNoteEntitiesByDate(
      date,
      tagIds: tagIds,
      userId: userId,
    );
  }

  Stream<List<NoteImageEntity>> getNoteImageEntities(int year) {
    return _dbNoteApi.getNoteImageEntities(year, userId);
  }

  Stream<List<NoteEntity>> getWrittenNoteEntities(
    Jiffy date, {
    List<String>? tagIds,
  }) {
    return _dbNoteApi.getWrittenNoteEntities(
      date,
      tagIds: tagIds,
      userId: userId,
    );
  }

  Future<Jiffy?> getStartDate() async {
    return _dbNoteApi.getStartDate(userId: userId);
  }

  Future<void> deleteNoteById(String noteId) async {
    await _supabaseNoteApi.deleteByNoteId(noteId: noteId);
    return _dbNoteApi.deleteNoteById(noteId);
  }
}
