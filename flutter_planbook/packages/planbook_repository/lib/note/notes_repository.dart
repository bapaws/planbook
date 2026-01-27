import 'dart:async';
import 'dart:convert';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  Future<int> getTotalCount() => _dbNoteApi.getTotalCount(userId: userId);

  List<NoteTag> generateNoteTags({
    required List<TagEntity>? tags,
    required String noteId,
  }) {
    return _dbNoteApi.generateNoteTags(
      tags: tags,
      noteId: noteId,
      userId: userId,
    );
  }

  Future<Note> create({
    required String title,
    String? id,
    String? content,
    List<String>? images,
    List<TagEntity>? tags,
    String? taskId,
    Jiffy? createdAt,
    Jiffy? focusAt,
    NoteType? type,
  }) async {
    final noteId = id ?? const Uuid().v4();

    final note = Note(
      id: noteId,
      title: title,
      content: content,
      images: images ?? [],
      taskId: taskId,
      createdAt: createdAt ?? Jiffy.now(),
      userId: userId,
      focusAt: focusAt,
      type: type,
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
    final newNote = note.copyWith(userId: Value(userId));
    await _supabaseNoteApi.update(note: newNote, noteTags: noteTags);
    await _dbNoteApi.update(note: newNote, noteTags: noteTags);
  }

  Future<void> syncNotes({
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

        if (item['tasks'] is List<dynamic>) {
          for (final taskItem in item['tasks'] as List<dynamic>) {
            final map = taskItem as Map<String, dynamic>;
            final taskMap = map['task'] as Map<String, dynamic>?;
            if (taskMap == null) continue;
            final task = Task.fromJson(taskMap);
            await _db.into(_db.tasks).insertOnConflictUpdate(task);
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
    NoteListMode mode = NoteListMode.all,
    List<String>? tagIds,
  }) {
    syncNotes();
    return _dbNoteApi.getNoteEntitiesByDate(
      date,
      tagIds: tagIds,
      userId: userId,
      mode: mode,
    );
  }

  Stream<List<NoteImageEntity>> getNoteImageEntities(int year) {
    return _dbNoteApi.getNoteImageEntities(year, userId);
  }

  Stream<List<NoteEntity>> getWrittenNoteEntities(
    Jiffy date, {
    List<String>? tagIds,
  }) {
    syncNotes();
    return _dbNoteApi.getWrittenNoteEntities(
      date,
      tagIds: tagIds,
      userId: userId,
    );
  }

  Stream<Note?> getNoteByFocusAt(
    Jiffy focusAt, {
    NoteType type = NoteType.dailyFocus,
  }) {
    return _dbNoteApi.getNoteByFocusAt(focusAt, type: type, userId: userId);
  }

  Stream<List<Note>> getYearlyNotes(
    int year,
    List<NoteType> types,
  ) {
    return _dbNoteApi.getYearlyNotes(year, types, userId: userId);
  }

  Future<Jiffy?> getStartDate() async {
    return _dbNoteApi.getStartDate(userId: userId);
  }

  Future<void> deleteNoteById(String noteId) async {
    await _supabaseNoteApi.deleteByNoteId(noteId: noteId);
    return _dbNoteApi.deleteNoteById(noteId);
  }

  Future<void> createDefaultNotes({required String languageCode}) async {
    if (!kDebugMode) return;
    const uuid = Uuid();

    final fileNames = [
      'notes',
      'task_notes',
      'focus_notes',
    ];
    for (final fileName in fileNames) {
      final jsonString = await rootBundle.loadString(
        'assets/${kDebugMode ? 'demo' : 'files'}/${fileName}_$languageCode.json',
      );
      final json = jsonDecode(jsonString) as List<dynamic>;
      final startOfMonth = Jiffy.now().startOf(Unit.month);
      final diff = startOfMonth
          .diff(Jiffy.parseFromList([2026, 1]), unit: Unit.day)
          .toInt();
      for (final item in json) {
        final map = item as Map<String, dynamic>;
        final noteMap = map['note'] as Map<String, dynamic>;
        var note = Note.fromJson(noteMap).copyWith(
          id: kDebugMode ? null : uuid.v4(),
        );
        note = note.copyWith(createdAt: note.createdAt.add(days: diff));
        final tagNames = List<String>.from(map['tags'] as List<dynamic>);
        final tags = await Future.wait(
          tagNames.map((name) => _tagApi.getTagEntityByName(name, userId)),
        );
        await create(
          title: note.title,
          content: note.content,
          images: note.images,
          taskId: note.taskId,
          focusAt: note.focusAt,
          type: note.type,
          tags: tags.nonNulls.toList(),
          createdAt: note.createdAt,
        );
      }
    }
  }
}
