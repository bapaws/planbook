import 'dart:async';

import 'package:database_planbook_api/note/database_note_api.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

import '../test_helper.dart';

void main() {
  test('整本日记按用户隔离，排除任务、周期笔记和已删除日记，并按时间排序', () async {
    final apis = createTestApis();
    final db = apis.db;
    addTearDown(db.close);
    final api = DatabaseNoteApi(
      db: db,
      tagApi: apis.tagApi,
      outboxApi: apis.outboxApi,
    );
    final date = Jiffy.parse('2026-10-23');
    await db
        .into(db.tasks)
        .insert(
          Task(
            id: 'task',
            layer: 0,
            childCount: 0,
            order: 0,
            isAllDay: false,
            alarms: const [],
            title: '任务',
            createdAt: date,
          ),
        );
    for (final note in [
      Note(
        images: const [],
        id: 'later',
        title: '显式日记',
        userId: 'me',
        type: NoteType.journal,
        createdAt: date,
      ),
      Note(
        images: const [],
        id: 'earlier',
        title: '旧版日记',
        userId: 'me',
        createdAt: date.subtract(years: 1),
      ),
      Note(
        images: const [],
        id: 'other',
        title: '其他用户',
        userId: 'other',
        createdAt: date,
      ),
      Note(images: const [], id: 'guest', title: '访客日记', createdAt: date),
      Note(
        images: const [],
        id: 'task-note',
        title: '任务记录',
        userId: 'me',
        taskId: 'task',
        type: NoteType.journal,
        createdAt: date,
      ),
      Note(
        images: const [],
        id: 'deleted',
        title: '已删除',
        userId: 'me',
        deletedAt: date,
        createdAt: date,
      ),
      for (final type in NoteType.values.where((type) => !type.isJournal))
        Note(
          images: const [],
          id: type.name,
          title: '周期笔记',
          userId: 'me',
          type: type,
          createdAt: date,
        ),
    ]) {
      await db.into(db.notes).insert(note);
    }
    expect(
      (await api.watchDiaryNotes(userId: 'me').first).map((note) => note.id),
      ['earlier', 'later'],
    );
    expect(
      (await api.watchDiaryNotes(userId: null).first).map((note) => note.id),
      ['guest'],
    );
  });

  test('新增、编辑和软删除实时更新日记本', () async {
    final apis = createTestApis();
    final db = apis.db;
    addTearDown(db.close);
    final api = DatabaseNoteApi(
      db: db,
      tagApi: apis.tagApi,
      outboxApi: apis.outboxApi,
    );
    final iterator = StreamIterator(api.watchDiaryNotes(userId: 'me'));
    addTearDown(iterator.cancel);
    await iterator.moveNext();
    expect(iterator.current, isEmpty);
    await db
        .into(db.notes)
        .insert(
          Note(
            images: const [],
            id: 'diary',
            title: '第一版',
            userId: 'me',
            createdAt: Jiffy.now(),
          ),
        );
    await iterator.moveNext();
    expect(iterator.current.single.title, '第一版');
    await (db.update(db.notes)..where((note) => note.id.equals('diary'))).write(
      const NotesCompanion(title: Value('编辑后')),
    );
    await iterator.moveNext();
    expect(iterator.current.single.title, '编辑后');
    await (db.update(db.notes)..where((note) => note.id.equals('diary'))).write(
      NotesCompanion(deletedAt: Value(Jiffy.now())),
    );
    await iterator.moveNext();
    expect(iterator.current, isEmpty);
  });
}
