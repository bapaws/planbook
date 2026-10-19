import 'dart:async';
import 'dart:convert';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_repository/sync/apply_remote_batch.dart';
import 'package:planbook_repository/sync/database_pull_lock.dart';
import 'package:planbook_repository/sync/merge_remote_rows.dart';
import 'package:planbook_repository/sync/pull_sync_coordinator.dart';
import 'package:planbook_repository/sync/pull_write_fence.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_planbook_api/note/supabase_note_api.dart';
import 'package:supabase_planbook_api/sync/remote_table_pull.dart';
import 'package:supabase_planbook_api/utils/supabase_sync_utils.dart';
import 'package:uuid/uuid.dart';

class NotesRepository {
  NotesRepository({
    required SharedPreferences sp,
    required AppDatabase db,
    required DatabaseTagApi tagApi,
    required OutboxApi outboxApi,
    DatabaseNoteApi? dbNoteApi,
    DatabaseNoteTaskApi? dbNoteTaskApi,
    DatabaseTaskApi? dbTaskApi,
    SupabaseNoteApi? supabaseNoteApi,
  }) : _dbNoteApi =
           dbNoteApi ??
           DatabaseNoteApi(db: db, tagApi: tagApi, outboxApi: outboxApi),
       _supabaseNoteApi = supabaseNoteApi ?? SupabaseNoteApi(sp: sp),
       _sp = sp,
       _db = db,
       _tagApi = tagApi,
       _dbNoteTaskApi = dbNoteTaskApi ?? DatabaseNoteTaskApi(db: db),
       _dbTaskApi =
           dbTaskApi ??
           DatabaseTaskApi(db: db, tagApi: tagApi, outboxApi: outboxApi);

  final DatabaseNoteApi _dbNoteApi;
  final SharedPreferences _sp;
  final _pullSync = PullSyncCoordinator();

  final SupabaseNoteApi _supabaseNoteApi;
  final AppDatabase _db;
  final DatabaseTagApi _tagApi;
  final DatabaseTaskApi _dbTaskApi;

  final DatabaseNoteTaskApi _dbNoteTaskApi;

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
    await _dbNoteApi.update(note: newNote, noteTags: noteTags);
  }

  Future<void> syncNotes({bool force = false}) {
    final account = userId;
    return _pullSync.run(
      userId: account,
      force: force,
      action: ({required force}) => DatabasePullLock.run(
        _db,
        () => _syncNotes(force: force, account: account),
      ),
    );
  }

  Future<void> _syncNotes({
    required bool force,
    required String? account,
  }) async {
    void validateAccount() {
      if (userId != account) throw StateError('同步账号已变化，丢弃旧请求');
    }

    validateAccount();
    final fence = await PullWriteFence.capture(_db);
    final list = await _supabaseNoteApi.getLatestNotes(force: force);
    validateAccount();
    for (final item in list) {
      final note = Note.fromJson(item);
      if (note.userId != account) throw StateError('远程笔记不属于请求账号');
      await _db.transaction(() async {
        validateAccount();

        // 如果本地还有该记录的待同步变更，优先保留本地版本，避免远程旧数据覆盖。
        final hasPending = await _dbNoteApi.hasPendingChanges(note.id);
        if (hasPending || await fence.protects(note.id)) return;

        final accepted = await mergeRemoteRows(
          db: _db,
          table: _db.notes,
          idColumn: _db.notes.id,
          rows: [note],
          protectedIds: fence.blocked,
        );
        if (list is RemoteSyncRows) list.batches['notes']!.accept(accepted);

        final tags = <Tag>[];
        final links = <NoteTag>[];
        if (item['note_tags'] is List<dynamic>) {
          for (final noteTag in item['note_tags'] as List<dynamic>) {
            final map = noteTag as Map<String, dynamic>;
            final tagMap = map['tag'] as Map<String, dynamic>?;
            if (tagMap == null) continue;
            final tag = Tag.fromJson(tagMap);
            tags.add(tag);
            links.add(NoteTag.fromJson(map));
          }
        }
        await mergeRemoteRows(
          db: _db,
          table: _db.tags,
          idColumn: _db.tags.id,
          rows: tags,
        );
        await mergeRemoteRows(
          db: _db,
          table: _db.noteTags,
          idColumn: _db.noteTags.id,
          rows: links,
        );

        if (item['tasks'] is List<dynamic>) {
          for (final taskItem in item['tasks'] as List<dynamic>) {
            final map = taskItem as Map<String, dynamic>;
            final taskMap = map['task'] as Map<String, dynamic>?;
            if (taskMap == null) continue;
            final task = Task.fromJson(taskMap);

            // 本地有待同步变更时保留本地任务，避免被 note 嵌套带下的远程副本覆盖。
            final hasPendingTask = await _dbTaskApi.hasPendingChanges(task.id);
            if (hasPendingTask) continue;

            await _db.into(_db.tasks).insertOnConflictUpdate(task);
          }
        }
        validateAccount();
      });
    }
    validateAccount();
    if (list is RemoteSyncRows) {
      for (final batch in list.batches.values) {
        if (batch.table == 'notes') {
          await batch.commit();
        } else {
          await applyRemoteBatch(
            db: _db,
            batch: batch,
            fence: fence,
            account: account!,
            validateAccount: validateAccount,
          );
        }
      }
    }
    final cursor = list is RemoteSyncRows
        ? null
        : maxTimestampFromSyncItems(list);
    if (cursor != null) {
      final key = SupabaseNoteApi.cursorKey(account);
      final previous = _sp.getInt(key);
      if (previous == null || cursor > previous) {
        if (!await _sp.setInt(key, cursor)) throw StateError('笔记同步游标保存失败');
      }
    }
  }

  Future<NoteEntity?> getNoteEntityById(String noteId) async {
    return _dbNoteApi.getNoteEntityById(noteId);
  }

  /// 按关键词搜索笔记（标题 / 内容）
  Future<List<NoteEntity>> search(String query) {
    return _dbNoteApi.searchNoteEntities(query: query, userId: userId);
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
    OrderingMode orderingMode = OrderingMode.desc,
  }) {
    syncNotes();
    return _dbNoteApi.getNoteEntitiesByDate(
      date,
      tagIds: tagIds,
      userId: userId,
      mode: mode,
      orderingMode: orderingMode,
    );
  }

  Stream<List<NoteEntity>> getNoteEntitiesForMonth(
    Jiffy date, {
    NoteListMode mode = NoteListMode.all,
    List<String>? tagIds,
    OrderingMode orderingMode = OrderingMode.desc,
  }) {
    syncNotes();
    final startOfMonth = date.startOf(Unit.month);
    final endOfMonth = date.endOf(Unit.month);
    return _dbNoteApi.getNoteEntitiesByDateRange(
      startOfMonth,
      endOfMonth,
      tagIds: tagIds,
      userId: userId,
      mode: mode,
      orderingMode: orderingMode,
    );
  }

  Stream<List<NoteImageEntity>> getNoteImageEntities(int year) {
    return _dbNoteApi.getNoteImageEntities(year, userId);
  }

  Stream<List<NoteImageEntity>> getNoteImageEntitiesForMonth(Jiffy date) {
    final startOfMonth = date.startOf(Unit.month);
    final endOfMonth = date.endOf(Unit.month);
    return _dbNoteApi.getNoteImageEntitiesByDateRange(
      startOfMonth,
      endOfMonth,
      userId,
    );
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
        note = note.copyWith(
          createdAt: note.createdAt.add(days: diff),
          focusAt: Value(note.focusAt?.add(days: diff)),
        );
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

  Future<void> appendTaskLineToNote({
    required String title,
    required Jiffy focusAt,
    required NoteType noteType,
    required TaskEntity task,
    required Note? currentNote,
  }) async {
    final newLine = '${task.isCompleted ? '✅' : '⭕️'} ${task.title}';
    final base = (currentNote?.content ?? '').trim();

    final String newContent;
    if (base.isEmpty) {
      newContent = newLine;
    } else {
      final lines = base.split('\n').toList();
      final taskTitle = task.title;

      bool isSameTaskLine(String l) {
        if (l.length < 2) return false;
        final first = l[0];
        if (first != '✅' && first != '⭕️') return false;
        return l.substring(1).trimLeft() == taskTitle;
      }

      int? firstIdx;
      final result = <String>[];
      for (var i = 0; i < lines.length; i++) {
        if (isSameTaskLine(lines[i])) {
          firstIdx ??= result.length;
          if (firstIdx == result.length) {
            result.add(newLine);
          }
        } else {
          result.add(lines[i]);
        }
      }
      if (firstIdx != null) {
        newContent = result.join('\n');
      } else {
        newContent = '$base\n$newLine';
      }
    }

    if (currentNote == null) {
      await create(
        title: title,
        content: newContent,
        focusAt: focusAt,
        type: noteType,
      );
    } else {
      await update(
        note: currentNote.copyWith(content: Value(newContent)),
      );
    }
  }

  Future<void> updateTypeNoteContentByTaskActivities(
    List<TaskActivity> activities,
  ) async {
    final notes = await _dbNoteTaskApi.generateNoteContentByTaskActivities(
      activities,
    );
    await _dbNoteTaskApi.updateTypeNoteContent(notes);
  }
}
