import 'package:drift/drift.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncRepository {
  SyncRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  SupabaseClient? get _supabase => AppSupabase.client;

  String? get userId => _supabase?.auth.currentUser?.id;

  Future<void> sync() async {
    if (userId == null) return;

    await _syncTasks();
    await _syncNotes();
    await _syncTags();
    await _syncNoteTags();
    await _syncTaskTags();
    await _syncTaskActivities();
  }

  Future<void> _syncTasks() async {
    final result =
        await (_db.selectOnly(_db.tasks, distinct: true)
              ..addColumns([_db.tasks.id.count()])
              ..where(_db.tasks.userId.equals(userId!)))
            .getSingleOrNull();
    final count = result?.read(_db.tasks.id.count()) ?? 0;

    final query = _db.select(_db.tasks)
      ..where((t) => t.userId.equals(userId!))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt.datetime)]);

    var offset = 0;
    while (offset < count) {
      final rows = await (query..limit(25, offset: offset)).get();
      final tasks = rows.map((e) => e.copyWith(userId: Value(userId))).toList();
      // 先向 Supabase 发送数据，成功后再更新本地数据库
      await _supabase!
          .from('tasks')
          .upsert(tasks.map((e) => e.toJson()).toList());
      // Supabase 操作成功后，更新本地数据库（insertOnConflictUpdate 本身是原子操作，不需要事务）
      for (final task in tasks) {
        await _db.into(_db.tasks).insertOnConflictUpdate(task);
      }
      offset += 25;
    }
  }

  Future<void> _syncNotes() async {
    final result =
        await (_db.selectOnly(_db.notes, distinct: true)
              ..addColumns([_db.notes.id.count()])
              ..where(_db.notes.userId.equals(userId!)))
            .getSingleOrNull();
    final count = result?.read(_db.notes.id.count()) ?? 0;

    final query = _db.select(_db.notes)
      ..where((t) => t.userId.equals(userId!))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt.datetime)]);

    var offset = 0;
    while (offset < count) {
      final rows = await (query..limit(25, offset: offset)).get();
      final notes = rows.map((e) => e.copyWith(userId: Value(userId))).toList();
      // 先向 Supabase 发送数据，成功后再更新本地数据库
      await _supabase!
          .from('notes')
          .upsert(notes.map((e) => e.toJson()).toList());
      // Supabase 操作成功后，更新本地数据库（insertOnConflictUpdate 本身是原子操作，不需要事务）
      for (final note in notes) {
        await _db.into(_db.notes).insertOnConflictUpdate(note);
      }
      offset += 25;
    }
  }

  Future<void> _syncTags() async {
    final result =
        await (_db.selectOnly(_db.tags, distinct: true)
              ..addColumns([_db.tags.id.count()])
              ..where(_db.tags.userId.equals(userId!)))
            .getSingleOrNull();
    final count = result?.read(_db.tags.id.count()) ?? 0;

    final query = _db.select(_db.tags)
      ..where((t) => t.userId.equals(userId!))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt.datetime)]);

    var offset = 0;
    while (offset < count) {
      final rows = await (query..limit(25, offset: offset)).get();
      final tags = rows.map((e) => e.copyWith(userId: Value(userId))).toList();
      // 先向 Supabase 发送数据，成功后再更新本地数据库
      await _supabase!
          .from('tags')
          .upsert(tags.map((e) => e.toJson()).toList());
      // Supabase 操作成功后，更新本地数据库（insertOnConflictUpdate 本身是原子操作，不需要事务）
      for (final tag in tags) {
        await _db.into(_db.tags).insertOnConflictUpdate(tag);
      }
      offset += 25;
    }
  }

  Future<void> _syncNoteTags() async {
    final result =
        await (_db.selectOnly(_db.noteTags, distinct: true)
              ..addColumns([_db.noteTags.id.count()])
              ..where(_db.noteTags.userId.equals(userId!)))
            .getSingleOrNull();
    final count = result?.read(_db.noteTags.id.count()) ?? 0;

    final query = _db.select(_db.noteTags)
      ..where((t) => t.userId.equals(userId!))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt.datetime)]);

    var offset = 0;
    while (offset < count) {
      final rows = await (query..limit(25, offset: offset)).get();
      final noteTags = rows
          .map((e) => e.copyWith(userId: Value(userId)))
          .toList();
      // 先向 Supabase 发送数据，成功后再更新本地数据库
      await _supabase!
          .from('note_tags')
          .upsert(noteTags.map((e) => e.toJson()).toList());
      // Supabase 操作成功后，更新本地数据库（insertOnConflictUpdate 本身是原子操作，不需要事务）
      for (final noteTag in noteTags) {
        await _db.into(_db.noteTags).insertOnConflictUpdate(noteTag);
      }
      offset += 25;
    }
  }

  Future<void> _syncTaskTags() async {
    final result =
        await (_db.selectOnly(_db.taskTags, distinct: true)
              ..addColumns([_db.taskTags.id.count()])
              ..where(_db.taskTags.userId.equals(userId!)))
            .getSingleOrNull();
    final count = result?.read(_db.taskTags.id.count()) ?? 0;

    final query = _db.select(_db.taskTags)
      ..where((t) => t.userId.equals(userId!))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt.datetime)]);

    var offset = 0;
    while (offset < count) {
      final rows = await (query..limit(25, offset: offset)).get();
      final taskTags = rows
          .map((e) => e.copyWith(userId: Value(userId)))
          .toList();
      // 先向 Supabase 发送数据，成功后再更新本地数据库
      await _supabase!
          .from('task_tags')
          .upsert(taskTags.map((e) => e.toJson()).toList());
      // Supabase 操作成功后，更新本地数据库（insertOnConflictUpdate 本身是原子操作，不需要事务）
      for (final taskTag in taskTags) {
        await _db.into(_db.taskTags).insertOnConflictUpdate(taskTag);
      }
      offset += 25;
    }
  }

  Future<void> _syncTaskActivities() async {
    final result =
        await (_db.selectOnly(_db.taskActivities, distinct: true)
              ..addColumns([_db.taskActivities.id.count()])
              ..where(_db.taskActivities.userId.equals(userId!)))
            .getSingleOrNull();
    final count = result?.read(_db.taskActivities.id.count()) ?? 0;

    final query = _db.select(_db.taskActivities)
      ..where((t) => t.userId.equals(userId!))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt.datetime)]);

    var offset = 0;
    while (offset < count) {
      final rows = await (query..limit(25, offset: offset)).get();
      final taskActivities = rows
          .map((e) => e.copyWith(userId: Value(userId)))
          .toList();
      // 先向 Supabase 发送数据，成功后再更新本地数据库
      await _supabase!
          .from('task_activities')
          .upsert(taskActivities.map((e) => e.toJson()).toList());
      // Supabase 操作成功后，更新本地数据库（insertOnConflictUpdate 本身是原子操作，不需要事务）
      for (final taskActivity in taskActivities) {
        await _db.into(_db.taskActivities).insertOnConflictUpdate(taskActivity);
      }
      offset += 25;
    }
  }
}
