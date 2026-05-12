import 'package:database_planbook_api/note/database_note_api.dart';
import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

import '../test_helper.dart';

Note _testNote({
  required String id,
  String? userId,
  required String title,
  String? content,
  List<String> images = const [],
  String? coverImage,
  String? taskId,
  NoteType? type,
  Jiffy? focusAt,
}) {
  return Note(
    id: id,
    userId: userId,
    title: title,
    content: content,
    images: images,
    coverImage: coverImage,
    taskId: taskId,
    type: type,
    focusAt: focusAt,
    createdAt: Jiffy.now(),
  );
}

Tag _testTag({
  required String id,
  String? userId,
  required String name,
  String? parentId,
  int level = 0,
}) {
  return Tag(
    id: id,
    userId: userId,
    name: name,
    order: 0,
    parentId: parentId,
    level: level,
    createdAt: Jiffy.now(),
  );
}

void main() {
  group('DatabaseNoteApi', () {
    late AppDatabase db;
    late OutboxApi outboxApi;
    late DatabaseTagApi tagApi;
    late DatabaseNoteApi noteApi;

    setUp(() {
      final apis = createTestApis();
      db = apis.db;
      outboxApi = apis.outboxApi;
      tagApi = apis.tagApi;
      noteApi = DatabaseNoteApi(
        db: db,
        tagApi: tagApi,
        outboxApi: outboxApi,
      );
    });

    tearDown(() async {
      await db.close();
    });

    group('create', () {
      test('inserts note and enqueues outbox records', () async {
        final note = _testNote(id: 'note-1', title: 'Test Note');
        await noteApi.create(note: note);

        final stored = await db.select(db.notes).getSingle();
        expect(stored.id, 'note-1');
        expect(stored.title, 'Test Note');

        final outbox = await db.select(db.syncOutbox).get();
        expect(outbox, hasLength(2));
        final noteOutbox = outbox.firstWhere(
          (o) => o.targetTable == 'notes',
        );
        expect(noteOutbox.operation, 'insert');
        expect(noteOutbox.recordId, 'note-1');

        final tagAssocOutbox = outbox.firstWhere(
          (o) => o.targetTable == 'note_tags',
        );
        expect(tagAssocOutbox.operation, 'replace_associations');
      });

      test('inserts note with noteTags', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        final note = _testNote(id: 'note-1', title: 'Test Note');
        final noteTags = [
          NoteTag(
            id: 'nt-1',
            noteId: 'note-1',
            tagId: 'tag-1',
            createdAt: Jiffy.now(),
          ),
        ];
        await noteApi.create(note: note, noteTags: noteTags);

        final storedTags = await db.select(db.noteTags).get();
        expect(storedTags, hasLength(1));
        expect(storedTags.first.tagId, 'tag-1');
        expect(storedTags.first.noteId, 'note-1');
      });
    });

    group('update', () {
      test('updates note and replaces noteTags', () async {
        final note = _testNote(id: 'note-1', title: 'Original');
        await noteApi.create(note: note);

        final updated = note.copyWith(title: 'Updated');
        await noteApi.update(note: updated);

        final stored = await db.select(db.notes).getSingle();
        expect(stored.title, 'Updated');

        final outbox = await db.select(db.syncOutbox).get();
        final noteOutbox = outbox
            .where((o) => o.targetTable == 'notes' && o.operation == 'update')
            .toList();
        expect(noteOutbox, hasLength(1));
      });

      test('replaces noteTags on update', () async {
        final tag1 = _testTag(id: 'tag-1', name: 'Work');
        final tag2 = _testTag(id: 'tag-2', name: 'Personal');
        await tagApi.create(tag: tag1);
        await tagApi.create(tag: tag2);

        final note = _testNote(id: 'note-1', title: 'Test');
        final oldTags = [
          NoteTag(
            id: 'nt-1',
            noteId: 'note-1',
            tagId: 'tag-1',
            createdAt: Jiffy.now(),
          ),
        ];
        await noteApi.create(note: note, noteTags: oldTags);

        final newTags = [
          NoteTag(
            id: 'nt-2',
            noteId: 'note-1',
            tagId: 'tag-2',
            createdAt: Jiffy.now(),
          ),
        ];
        await noteApi.update(note: note, noteTags: newTags);

        final storedTags = await db.select(db.noteTags).get();
        expect(storedTags, hasLength(1));
        expect(storedTags.first.tagId, 'tag-2');
      });
    });

    group('deleteNoteById', () {
      test('soft deletes note and sets deletedAt', () async {
        final note = _testNote(id: 'note-1', title: 'Test');
        await noteApi.create(note: note);

        await noteApi.deleteNoteById('note-1');

        final stored = await db.select(db.notes).getSingle();
        expect(stored.deletedAt, isNotNull);
      });

      test('soft deletes related noteTags', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        final note = _testNote(id: 'note-1', title: 'Test');
        final noteTags = [
          NoteTag(
            id: 'nt-1',
            noteId: 'note-1',
            tagId: 'tag-1',
            createdAt: Jiffy.now(),
          ),
        ];
        await noteApi.create(note: note, noteTags: noteTags);

        await noteApi.deleteNoteById('note-1');

        final storedTags = await db.select(db.noteTags).get();
        expect(storedTags.first.deletedAt, isNotNull);
      });

      test('enqueues outbox delete record', () async {
        final note = _testNote(id: 'note-1', title: 'Test');
        await noteApi.create(note: note);

        await noteApi.deleteNoteById('note-1');

        final outbox = await db.select(db.syncOutbox).get();
        final deleteOutbox = outbox.firstWhere(
          (o) => o.targetTable == 'notes' && o.operation == 'delete',
        );
        expect(deleteOutbox.recordId, 'note-1');
        expect(deleteOutbox.payload, contains('note-1'));
      });
    });

    group('getNoteEntityById', () {
      test('returns note entity with tags', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        final note = _testNote(id: 'note-1', title: 'Test');
        final noteTag = NoteTag(
          id: 'nt-1',
          noteId: 'note-1',
          tagId: 'tag-1',
          createdAt: Jiffy.now(),
        );
        await noteApi.create(note: note, noteTags: [noteTag]);

        final entity = await noteApi.getNoteEntityById('note-1');
        expect(entity, isNotNull);
        expect(entity!.note.id, 'note-1');
        expect(entity.tags, hasLength(1));
        expect(entity.tags.first.id, 'tag-1');
      });

      test('returns null for non-existent note', () async {
        final entity = await noteApi.getNoteEntityById('non-existent');
        expect(entity, isNull);
      });

      test('returns null for deleted note', () async {
        final note = _testNote(id: 'note-1', title: 'Test');
        await noteApi.create(note: note);
        await noteApi.deleteNoteById('note-1');

        final entity = await noteApi.getNoteEntityById('note-1');
        expect(entity, isNull);
      });
    });

    group('getTotalCount', () {
      test('counts only non-deleted notes', () async {
        await noteApi.create(note: _testNote(id: 'note-1', title: 'A'));
        await noteApi.create(note: _testNote(id: 'note-2', title: 'B'));

        expect(await noteApi.getTotalCount(userId: null), 2);

        await noteApi.deleteNoteById('note-1');
        expect(await noteApi.getTotalCount(userId: null), 1);
      });

      test('filters by userId', () async {
        await noteApi.create(
          note: _testNote(id: 'note-1', title: 'A', userId: 'user-1'),
        );
        await noteApi.create(
          note: _testNote(id: 'note-2', title: 'B', userId: 'user-2'),
        );

        expect(await noteApi.getTotalCount(userId: 'user-1'), 1);
        expect(await noteApi.getTotalCount(userId: 'user-2'), 1);
        expect(await noteApi.getTotalCount(userId: null), 0);
      });
    });

    group('generateNoteTags', () {
      test('generates direct note tags for flat tags', () async {
        final tags = [
          TagEntity(
            tag: _testTag(id: 'tag-1', name: 'Work'),
          ),
        ];
        final noteTags = noteApi.generateNoteTags(
          noteId: 'note-1',
          userId: null,
          tags: tags,
        );

        expect(noteTags, hasLength(1));
        expect(noteTags.first.noteId, 'note-1');
        expect(noteTags.first.tagId, 'tag-1');
        expect(noteTags.first.linkedTagId, isNull);
      });

      test('generates linked tags for parent hierarchy', () async {
        final parent = TagEntity(
          tag: _testTag(id: 'parent-1', name: 'Parent'),
        );
        final child = TagEntity(
          tag: _testTag(
            id: 'child-1',
            name: 'Child',
            parentId: 'parent-1',
            level: 1,
          ),
          parent: parent,
        );

        final noteTags = noteApi.generateNoteTags(
          noteId: 'note-1',
          userId: null,
          tags: [child],
        );

        expect(noteTags, hasLength(2));

        final direct = noteTags.firstWhere((nt) => nt.tagId == 'child-1');
        expect(direct.linkedTagId, isNull);

        final linked = noteTags.firstWhere((nt) => nt.tagId == 'parent-1');
        expect(linked.linkedTagId, 'child-1');
      });

      test('handles multiple tags with shared ancestors', () async {
        final grandParent = TagEntity(
          tag: _testTag(id: 'gp-1', name: 'GrandParent'),
        );
        final parent = TagEntity(
          tag: _testTag(
            id: 'parent-1',
            name: 'Parent',
            parentId: 'gp-1',
            level: 1,
          ),
          parent: grandParent,
        );
        final child = TagEntity(
          tag: _testTag(
            id: 'child-1',
            name: 'Child',
            parentId: 'parent-1',
            level: 2,
          ),
          parent: parent,
        );

        final noteTags = noteApi.generateNoteTags(
          noteId: 'note-1',
          userId: null,
          tags: [child],
        );

        expect(noteTags, hasLength(3));
        expect(noteTags.where((nt) => nt.tagId == 'child-1').length, 1);
        expect(noteTags.where((nt) => nt.tagId == 'parent-1').length, 1);
        expect(noteTags.where((nt) => nt.tagId == 'gp-1').length, 1);
      });

      test('returns empty list for null tags', () {
        final result = noteApi.generateNoteTags(
          noteId: 'note-1',
          userId: null,
          tags: null,
        );
        expect(result, isEmpty);
      });

      test('returns empty list for empty tags', () {
        final result = noteApi.generateNoteTags(
          noteId: 'note-1',
          userId: null,
          tags: [],
        );
        expect(result, isEmpty);
      });

      test('sets userId on generated tags', () {
        final tags = [
          TagEntity(tag: _testTag(id: 'tag-1', name: 'Work')),
        ];
        final noteTags = noteApi.generateNoteTags(
          noteId: 'note-1',
          userId: 'user-1',
          tags: tags,
        );

        expect(noteTags.first.userId, 'user-1');
      });
    });

    group('getNoteEntitiesByTaskId', () {
      test('returns notes linked to task', () async {
        final note = _testNote(id: 'note-1', title: 'Task Note', taskId: 'task-1');
        await noteApi.create(note: note);

        final notes = await noteApi.getNoteEntitiesByTaskId('task-1').first;
        expect(notes, hasLength(1));
        expect(notes.first.id, 'note-1');
      });

      test('excludes deleted notes', () async {
        final note = _testNote(id: 'note-1', title: 'Task Note', taskId: 'task-1');
        await noteApi.create(note: note);
        await noteApi.deleteNoteById('note-1');

        final notes = await noteApi.getNoteEntitiesByTaskId('task-1').first;
        expect(notes, isEmpty);
      });
    });

    group('getNoteEntitiesByDate', () {
      test('returns notes created on specific date', () async {
        final now = Jiffy.now();
        final note = _testNote(id: 'note-1', title: 'Today');
        await noteApi.create(note: note);

        final notes = await noteApi.getNoteEntitiesByDate(now).first;
        expect(notes, hasLength(1));
        expect(notes.first.id, 'note-1');
      });

      test('excludes notes from other dates', () async {
        final now = Jiffy.now();
        final yesterday = now.subtract(days: 1);

        final note = _testNote(id: 'note-1', title: 'Yesterday');
        await noteApi.create(note: note);

        final notes = await noteApi.getNoteEntitiesByDate(yesterday).first;
        expect(notes, isEmpty);
      });
    });

    group('getNoteByFocusAt', () {
      test('returns note by focus date and type', () async {
        final focusAt = Jiffy.now();
        final note = _testNote(
          id: 'note-1',
          title: 'Focus',
          type: NoteType.dailyFocus,
          focusAt: focusAt,
        );
        await noteApi.create(note: note);

        final result = await noteApi
            .getNoteByFocusAt(focusAt, type: NoteType.dailyFocus)
            .first;
        expect(result, isNotNull);
        expect(result!.id, 'note-1');
      });
    });

    group('getStartDate', () {
      test('returns earliest note createdAt', () async {
        final note = _testNote(id: 'note-1', title: 'First');
        await noteApi.create(note: note);

        final startDate = await noteApi.getStartDate(userId: null);
        expect(startDate, isNotNull);
      });
    });
  });
}
