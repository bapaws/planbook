import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_repository/note/notes_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseTagApi extends Mock implements DatabaseTagApi {}

class MockOutboxApi extends Mock implements OutboxApi {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

AppDatabase _createTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

Note _testNote({
  String id = 'note-1',
  String title = 'Test Note',
  Jiffy? createdAt,
  Jiffy? focusAt,
  NoteType? type,
  String? taskId,
}) {
  return Note(
    id: id,
    title: title,
    images: const [],
    createdAt: createdAt ?? Jiffy.now(),
    focusAt: focusAt,
    type: type,
    taskId: taskId,
  );
}

void main() {
  late AppDatabase db;
  late MockDatabaseTagApi mockTagApi;
  late MockOutboxApi mockOutboxApi;
  late MockSharedPreferences mockSp;
  late NotesRepository repository;

  setUp(() async {
    db = _createTestDb();
    mockTagApi = MockDatabaseTagApi();
    mockOutboxApi = MockOutboxApi();
    mockSp = MockSharedPreferences();
    repository = NotesRepository(
      sp: mockSp,
      db: db,
      tagApi: mockTagApi,
      outboxApi: mockOutboxApi,
    );

    when(
      () => mockOutboxApi.enqueue(
        tableName: any(named: 'tableName'),
        recordId: any(named: 'recordId'),
        operation: any(named: 'operation'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockTagApi.getTagEntityById(any()),
    ).thenAnswer((_) async => null);
  });

  tearDown(() async {
    await db.close();
  });

  group('NotesRepository', () {
    test('getTotalCount returns note count', () async {
      final count = await repository.getTotalCount();
      expect(count, 0);

      await repository.create(title: 'Note 1');
      await repository.create(title: 'Note 2');

      final count2 = await repository.getTotalCount();
      expect(count2, 2);
    });

    test('getNoteEntityById returns note by id', () async {
      final note = await repository.create(title: 'My Note');

      final result = await repository.getNoteEntityById(note.id);

      expect(result, isNotNull);
      expect(result!.note.id, note.id);
      expect(result.note.title, 'My Note');
    });

    test('createNote creates a note with given title', () async {
      final note = await repository.create(title: 'Hello World');

      expect(note.title, 'Hello World');
      final fetched = await repository.getNoteEntityById(note.id);
      expect(fetched, isNotNull);
      expect(fetched!.note.title, 'Hello World');
    });

    test('createNote generates note tags when tags provided', () async {
      final tag = TagEntity(
        tag: Tag(
          id: 'tag-1',
          name: 'Work',
          order: 0,
          level: 0,
          createdAt: Jiffy.now(),
        ),
      );
      when(
        () => mockTagApi.getTagEntityById('tag-1'),
      ).thenAnswer((_) async => tag);

      final note = await repository.create(
        title: 'Tagged Note',
        tags: [tag],
      );

      final fetched = await repository.getNoteEntityById(note.id);
      expect(fetched, isNotNull);
      expect(fetched!.tags.length, 1);
      expect(fetched.tags.first.id, 'tag-1');
    });

    test('updateNote updates note content', () async {
      final note = await repository.create(title: 'Original');

      await repository.update(
        note: note.copyWith(content: const drift.Value('Updated content')),
      );

      final fetched = await repository.getNoteEntityById(note.id);
      expect(fetched, isNotNull);
      expect(fetched!.note.content, 'Updated content');
    });

    test('deleteNoteById soft-deletes a note', () async {
      final note = await repository.create(title: 'To Delete');

      await repository.deleteNoteById(note.id);

      final fetched = await repository.getNoteEntityById(note.id);
      expect(fetched, isNull);
    });

    test('getNoteEntitiesByDate returns notes for given date', () async {
      final now = Jiffy.now();
      await repository.create(title: 'Today Note', createdAt: now);

      final stream = repository.getNoteEntitiesByDate(now);

      await expectLater(
        stream,
        emits(
          predicate<List<NoteEntity>>(
            (list) => list.length == 1 && list.first.title == 'Today Note',
          ),
        ),
      );
    });

    test('getNoteByFocusAt returns note matching focusAt and type', () async {
      final focusAt = Jiffy.now().startOf(Unit.day);
      final note = await repository.create(
        title: 'Daily Focus',
        focusAt: focusAt,
        type: NoteType.dailyFocus,
      );

      final stream = repository.getNoteByFocusAt(
        focusAt,
        type: NoteType.dailyFocus,
      );

      await expectLater(
        stream,
        emits(
          predicate<Note?>(
            (n) => n != null && n.id == note.id && n.title == 'Daily Focus',
          ),
        ),
      );
    });

    test('getNoteEntitiesByTaskId returns notes for task', () async {
      await repository.create(title: 'Task Note 1', taskId: 'task-1');
      await repository.create(title: 'Task Note 2', taskId: 'task-1');
      await repository.create(title: 'Other Note', taskId: 'task-2');

      final stream = repository.getNoteEntitiesByTaskId('task-1');

      await expectLater(
        stream,
        emits(
          predicate<List<NoteEntity>>(
            (list) =>
                list.length == 2 &&
                list.every((n) => n.note.taskId == 'task-1'),
          ),
        ),
      );
    });

    test('getStartDate returns earliest note createdAt', () async {
      final createdAt = Jiffy.now().subtract(days: 5);
      await repository.create(
        title: 'Early Note',
        createdAt: createdAt,
      );
      await repository.create(title: 'Late Note');

      final date = await repository.getStartDate();
      expect(date, isNotNull);
      expect(date!.year, createdAt.year);
      expect(date.month, createdAt.month);
      expect(date.date, createdAt.date);
    });

    test('getNoteEntitiesByTagId returns notes for tag', () async {
      final tag = Tag(
        id: 'tag-1',
        name: 'Work',
        order: 0,
        level: 0,
        createdAt: Jiffy.now(),
      );
      await db.into(db.tags).insert(tag);
      await repository.create(
        title: 'Tagged Note',
        tags: [TagEntity(tag: tag)],
      );

      final stream = repository.getNoteEntitiesByTagId('tag-1');

      await expectLater(
        stream,
        emits(
          predicate<List<NoteEntity>>(
            (list) =>
                list.length == 1 && list.first.note.title == 'Tagged Note',
          ),
        ),
      );
    });
  });
}
