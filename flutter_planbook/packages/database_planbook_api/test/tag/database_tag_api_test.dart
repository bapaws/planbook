import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/color_scheme_converter.dart';
import 'package:planbook_api/planbook_api.dart';

import '../test_helper.dart';

Tag _testTag({
  required String id,
  String? userId,
  required String name,
  String? color,
  int order = 0,
  String? parentId,
  int level = 0,
  ColorScheme? lightColorScheme,
  ColorScheme? darkColorScheme,
}) {
  return Tag(
    id: id,
    userId: userId,
    name: name,
    color: color,
    order: order,
    parentId: parentId,
    level: level,
    lightColorScheme: lightColorScheme,
    darkColorScheme: darkColorScheme,
    createdAt: Jiffy.now(),
  );
}

void main() {
  group('DatabaseTagApi', () {
    late AppDatabase db;
    late OutboxApi outboxApi;
    late DatabaseTagApi tagApi;

    setUp(() {
      db = createTestDatabase();
      outboxApi = OutboxApi(db: db);
      tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
    });

    tearDown(() async {
      await db.close();
    });

    group('create', () {
      test('inserts tag and enqueues outbox insert record', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        final stored = await tagApi.getTagById('tag-1');
        expect(stored, isNotNull);
        expect(stored!.name, 'Work');
        expect(stored.deletedAt, isNull);

        final outbox = await db.select(db.syncOutbox).get();
        expect(outbox, hasLength(1));
        expect(outbox.first.targetTable, 'tags');
        expect(outbox.first.recordId, 'tag-1');
        expect(outbox.first.operation, 'insert');
        expect(outbox.first.payload, contains('"id":"tag-1"'));
      });
    });

    group('update', () {
      test('updates tag and enqueues outbox update record', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        final updated = tag.copyWith(name: 'Personal');
        await tagApi.update(tag: updated);

        final stored = await tagApi.getTagById('tag-1');
        expect(stored!.name, 'Personal');

        final outbox = await db.select(db.syncOutbox).get();
        expect(outbox, hasLength(2));
        expect(outbox.last.targetTable, 'tags');
        expect(outbox.last.recordId, 'tag-1');
        expect(outbox.last.operation, 'update');
      });
    });

    group('updateTag', () {
      test('updates name and enqueues outbox record', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        await tagApi.updateTag(id: 'tag-1', name: 'Updated Work');

        final stored = await tagApi.getTagById('tag-1');
        expect(stored!.name, 'Updated Work');

        final outbox = await db.select(db.syncOutbox).get();
        expect(outbox, hasLength(2));
        expect(outbox.last.operation, 'update');
      });

      test('trims name whitespace', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        await tagApi.updateTag(id: 'tag-1', name: '  Trimmed  ');

        final stored = await tagApi.getTagById('tag-1');
        expect(stored!.name, 'Trimmed');
      });

      test('updates parent and level', () async {
        final parent = _testTag(id: 'parent-1', name: 'Parent');
        final child = _testTag(id: 'child-1', name: 'Child');
        await tagApi.create(tag: parent);
        await tagApi.create(tag: child);

        final parentEntity = await tagApi.getTagEntityById('parent-1');
        expect(parentEntity, isNotNull);

        await tagApi.updateTag(id: 'child-1', parentTag: parentEntity);

        final stored = await tagApi.getTagById('child-1');
        expect(stored!.parentId, 'parent-1');
        expect(stored.level, 1);
      });

      test('updates color schemes', () async {
        final scheme = const ColorScheme(
          argb: 0xFF000000,
          primaryArgb: 0xFF000000,
          onPrimaryArgb: 0xFFFFFFFF,
          primaryContainerArgb: 0xFF000000,
          onPrimaryContainerArgb: 0xFFFFFFFF,
          primaryFixedArgb: 0xFF000000,
          primaryFixedDimArgb: 0xFF000000,
          onPrimaryFixedArgb: 0xFFFFFFFF,
          onPrimaryFixedVariantArgb: 0xFFFFFFFF,
          secondaryArgb: 0xFF000000,
          onSecondaryArgb: 0xFFFFFFFF,
          secondaryContainerArgb: 0xFF000000,
          onSecondaryContainerArgb: 0xFFFFFFFF,
          secondaryFixedArgb: 0xFF000000,
          secondaryFixedDimArgb: 0xFF000000,
          onSecondaryFixedArgb: 0xFFFFFFFF,
          onSecondaryFixedVariantArgb: 0xFFFFFFFF,
          tertiaryArgb: 0xFF000000,
          onTertiaryArgb: 0xFFFFFFFF,
          tertiaryContainerArgb: 0xFF000000,
          onTertiaryContainerArgb: 0xFFFFFFFF,
          tertiaryFixedArgb: 0xFF000000,
          tertiaryFixedDimArgb: 0xFF000000,
          onTertiaryFixedArgb: 0xFFFFFFFF,
          onTertiaryFixedVariantArgb: 0xFFFFFFFF,
          errorArgb: 0xFF000000,
          onErrorArgb: 0xFFFFFFFF,
          errorContainerArgb: 0xFF000000,
          onErrorContainerArgb: 0xFFFFFFFF,
          outlineArgb: 0xFF000000,
          outlineVariantArgb: 0xFFFFFFFF,
          surfaceArgb: 0xFF000000,
          onSurfaceArgb: 0xFFFFFFFF,
          surfaceDimArgb: 0xFF000000,
          surfaceBrightArgb: 0xFFFFFFFF,
          surfaceContainerLowestArgb: 0xFF000000,
          surfaceContainerLowArgb: 0xFFFFFFFF,
          surfaceContainerArgb: 0xFF000000,
          surfaceContainerHighArgb: 0xFFFFFFFF,
          surfaceContainerHighestArgb: 0xFF000000,
          onSurfaceVariantArgb: 0xFFFFFFFF,
          inverseSurfaceArgb: 0xFF000000,
          onInverseSurfaceArgb: 0xFFFFFFFF,
          inversePrimaryArgb: 0xFF000000,
          shadowArgb: 0xFF000000,
          scrimArgb: 0xFF000000,
          surfaceTintArgb: 0xFF000000,
          surfaceVariantArgb: 0xFF000000,
        );
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        await tagApi.updateTag(
          id: 'tag-1',
          lightColorScheme: scheme,
          darkColorScheme: scheme,
        );

        final stored = await tagApi.getTagById('tag-1');
        expect(stored!.lightColorScheme, isNotNull);
        expect(stored.darkColorScheme, isNotNull);
      });

      test('does nothing when tag does not exist', () async {
        await tagApi.updateTag(id: 'non-existent', name: 'New Name');

        final outbox = await db.select(db.syncOutbox).get();
        expect(outbox, isEmpty);
      });
    });

    group('deleteById', () {
      test('soft deletes tag and sets deletedAt', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        await tagApi.deleteById('tag-1');

        final stored = await tagApi.getTagById('tag-1');
        expect(stored!.deletedAt, isNotNull);
      });

      test('soft deletes related taskTags and noteTags', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        await db.into(db.taskTags).insert(
          TaskTag(
            id: 'tt-1',
            taskId: 'task-1',
            tagId: 'tag-1',
            createdAt: Jiffy.now(),
          ),
        );
        await db.into(db.noteTags).insert(
          NoteTag(
            id: 'nt-1',
            noteId: 'note-1',
            tagId: 'tag-1',
            createdAt: Jiffy.now(),
          ),
        );

        await tagApi.deleteById('tag-1');

        final taskTags = await db.select(db.taskTags).get();
        expect(taskTags.first.deletedAt, isNotNull);

        final noteTags = await db.select(db.noteTags).get();
        expect(noteTags.first.deletedAt, isNotNull);
      });

      test('recursively soft deletes child tags', () async {
        final parent = _testTag(id: 'parent-1', name: 'Parent');
        final child = _testTag(
          id: 'child-1',
          name: 'Child',
          parentId: 'parent-1',
          level: 1,
        );
        final grandChild = _testTag(
          id: 'grand-1',
          name: 'GrandChild',
          parentId: 'child-1',
          level: 2,
        );
        await tagApi.create(tag: parent);
        await tagApi.create(tag: child);
        await tagApi.create(tag: grandChild);

        await tagApi.deleteById('parent-1');

        final parentTag = await tagApi.getTagById('parent-1');
        final childTag = await tagApi.getTagById('child-1');
        final grandTag = await tagApi.getTagById('grand-1');
        expect(parentTag!.deletedAt, isNotNull);
        expect(childTag!.deletedAt, isNotNull);
        expect(grandTag!.deletedAt, isNotNull);
      });
    });

    group('deleteTagById', () {
      test('removes tag and enqueues outbox delete record', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        await tagApi.deleteTagById('tag-1');

        final stored = await tagApi.getTagById('tag-1');
        expect(stored, isNull);

        final outbox = await db.select(db.syncOutbox).get();
        expect(outbox, hasLength(2));
        expect(outbox.last.targetTable, 'tags');
        expect(outbox.last.operation, 'delete');
        expect(outbox.last.payload, contains('tag-1'));
      });
    });

    group('getTagById', () {
      test('returns tag by id', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        final result = await tagApi.getTagById('tag-1');
        expect(result, isNotNull);
        expect(result!.id, 'tag-1');
        expect(result.name, 'Work');
      });

      test('returns null for non-existent id', () async {
        final result = await tagApi.getTagById('non-existent');
        expect(result, isNull);
      });
    });

    group('getTotalCount', () {
      test('counts non-deleted tags', () async {
        await tagApi.create(tag: _testTag(id: 'tag-1', name: 'A'));
        await tagApi.create(tag: _testTag(id: 'tag-2', name: 'B'));

        expect(await tagApi.getTotalCount(userId: null), 2);

        await tagApi.deleteById('tag-1');
        expect(await tagApi.getTotalCount(userId: null), 1);
      });

      test('filters by userId', () async {
        await tagApi.create(
          tag: _testTag(id: 'tag-1', name: 'A', userId: 'user-1'),
        );
        await tagApi.create(
          tag: _testTag(id: 'tag-2', name: 'B', userId: 'user-2'),
        );

        expect(await tagApi.getTotalCount(userId: 'user-1'), 1);
        expect(await tagApi.getTotalCount(userId: 'user-2'), 1);
        expect(await tagApi.getTotalCount(userId: null), 0);
      });
    });

    group('getTopLevelTags', () {
      test('returns only tags with null parentId', () async {
        await tagApi.create(tag: _testTag(id: 'tag-1', name: 'Parent'));
        await tagApi.create(
          tag: _testTag(
            id: 'tag-2',
            name: 'Child',
            parentId: 'tag-1',
            level: 1,
          ),
        );

        final tags = await tagApi.getTopLevelTags(userId: null).first;
        expect(tags, hasLength(1));
        expect(tags.first.id, 'tag-1');
      });

      test('filters by userId', () async {
        await tagApi.create(
          tag: _testTag(id: 'tag-1', name: 'A', userId: 'user-1'),
        );
        await tagApi.create(
          tag: _testTag(id: 'tag-2', name: 'B', userId: 'user-2'),
        );

        final tags = await tagApi.getTopLevelTags(userId: 'user-1').first;
        expect(tags, hasLength(1));
        expect(tags.first.id, 'tag-1');
      });
    });

    group('getAllTags', () {
      test('returns all non-deleted tags ordered by level/order/createdAt',
          () async {
        await tagApi.create(tag: _testTag(id: 'tag-1', name: 'A'));
        await tagApi.create(tag: _testTag(id: 'tag-2', name: 'B'));

        final tags = await tagApi.getAllTags(userId: null).first;
        expect(tags, hasLength(2));
      });

      test('excludes deleted tags', () async {
        await tagApi.create(tag: _testTag(id: 'tag-1', name: 'A'));
        await tagApi.create(tag: _testTag(id: 'tag-2', name: 'B'));
        await tagApi.deleteById('tag-1');

        final tags = await tagApi.getAllTags(userId: null).first;
        expect(tags, hasLength(1));
        expect(tags.first.id, 'tag-2');
      });

      test('excludes specified tag ids', () async {
        await tagApi.create(tag: _testTag(id: 'tag-1', name: 'A'));
        await tagApi.create(tag: _testTag(id: 'tag-2', name: 'B'));

        final tags = await tagApi
            .getAllTags(notIncludeTagIds: {'tag-1'}, userId: null)
            .first;
        expect(tags, hasLength(1));
        expect(tags.first.id, 'tag-2');
      });
    });

    group('getTagEntityById', () {
      test('returns tag entity with parent hierarchy', () async {
        final parent = _testTag(id: 'parent-1', name: 'Parent');
        final child = _testTag(
          id: 'child-1',
          name: 'Child',
          parentId: 'parent-1',
          level: 1,
        );
        await tagApi.create(tag: parent);
        await tagApi.create(tag: child);

        final entity = await tagApi.getTagEntityById('child-1');
        expect(entity, isNotNull);
        expect(entity!.id, 'child-1');
        expect(entity.parent, isNotNull);
        expect(entity.parent!.id, 'parent-1');
      });

      test('returns null for deleted tag', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);
        await tagApi.deleteById('tag-1');

        final entity = await tagApi.getTagEntityById('tag-1');
        expect(entity, isNull);
      });

      test('returns null for non-existent tag', () async {
        final entity = await tagApi.getTagEntityById('non-existent');
        expect(entity, isNull);
      });
    });

    group('getTagEntityByName', () {
      test('returns tag entity by exact name', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        final entity = await tagApi.getTagEntityByName('Work', null);
        expect(entity, isNotNull);
        expect(entity!.name, 'Work');
      });

      test('trims name before matching', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.create(tag: tag);

        final entity = await tagApi.getTagEntityByName('  Work  ', null);
        expect(entity, isNotNull);
        expect(entity!.name, 'Work');
      });
    });

    group('insertOrUpdateTag', () {
      test('inserts new tag', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.insertOrUpdateTag(tag);

        final stored = await tagApi.getTagById('tag-1');
        expect(stored, isNotNull);
      });

      test('updates existing tag', () async {
        final tag = _testTag(id: 'tag-1', name: 'Work');
        await tagApi.insertOrUpdateTag(tag);

        final updated = tag.copyWith(name: 'Personal');
        await tagApi.insertOrUpdateTag(updated);

        final stored = await tagApi.getTagById('tag-1');
        expect(stored!.name, 'Personal');
      });
    });

    group('getTaskTagsByTaskId', () {
      test('returns task tags for task', () async {
        await db.into(db.taskTags).insert(
          TaskTag(
            id: 'tt-1',
            taskId: 'task-1',
            tagId: 'tag-1',
            createdAt: Jiffy.now(),
          ),
        );

        final result = await tagApi.getTaskTagsByTaskId('task-1', null);
        expect(result, hasLength(1));
        expect(result.first.taskId, 'task-1');
      });

      test('excludes deleted task tags', () async {
        await db.into(db.taskTags).insert(
          TaskTag(
            id: 'tt-1',
            taskId: 'task-1',
            tagId: 'tag-1',
            createdAt: Jiffy.now(),
          ),
        );
        await db.into(db.taskTags).insert(
          TaskTag(
            id: 'tt-2',
            taskId: 'task-1',
            tagId: 'tag-2',
            createdAt: Jiffy.now(),
            deletedAt: Jiffy.now(),
          ),
        );

        final result = await tagApi.getTaskTagsByTaskId('task-1', null);
        expect(result, hasLength(1));
        expect(result.first.id, 'tt-1');
      });
    });

    group('getNoteTagsByNoteId', () {
      test('returns note tags for note', () async {
        await db.into(db.noteTags).insert(
          NoteTag(
            id: 'nt-1',
            noteId: 'note-1',
            tagId: 'tag-1',
            createdAt: Jiffy.now(),
          ),
        );

        final result = await tagApi.getNoteTagsByNoteId('note-1', null);
        expect(result, hasLength(1));
        expect(result.first.noteId, 'note-1');
      });
    });
  });
}
