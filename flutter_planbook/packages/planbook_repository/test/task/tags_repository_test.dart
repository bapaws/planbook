import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_api/database/color_scheme_converter.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_repository/task/tags_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseTagApi extends Mock implements DatabaseTagApi {}

class FakeAppDatabase implements AppDatabase {
  @override
  Future<T> transaction<T>(
    Future<T> Function() action, {
    bool requireNew = false,
  }) async {
    return await action();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockSharedPreferences extends Mock implements SharedPreferences {}

Tag _testTag({
  String id = 'tag-1',
  String name = 'Test Tag',
  int level = 0,
  String? parentId,
}) {
  return Tag(
    id: id,
    name: name,
    order: 0,
    level: level,
    parentId: parentId,
    createdAt: Jiffy.now(),
  );
}

TagEntity _testTagEntity({
  String id = 'tag-1',
  String name = 'Test Tag',
  int level = 0,
  String? parentId,
}) {
  return TagEntity(
    tag: _testTag(id: id, name: name, level: level, parentId: parentId),
  );
}

ColorScheme _testColorScheme(int color) {
  return ColorScheme(
    argb: color,
    primaryArgb: color,
    onPrimaryArgb: color,
    primaryContainerArgb: color,
    onPrimaryContainerArgb: color,
    primaryFixedArgb: color,
    primaryFixedDimArgb: color,
    onPrimaryFixedArgb: color,
    onPrimaryFixedVariantArgb: color,
    secondaryArgb: color,
    onSecondaryArgb: color,
    secondaryContainerArgb: color,
    onSecondaryContainerArgb: color,
    secondaryFixedArgb: color,
    secondaryFixedDimArgb: color,
    onSecondaryFixedArgb: color,
    onSecondaryFixedVariantArgb: color,
    tertiaryArgb: color,
    onTertiaryArgb: color,
    tertiaryContainerArgb: color,
    onTertiaryContainerArgb: color,
    tertiaryFixedArgb: color,
    tertiaryFixedDimArgb: color,
    onTertiaryFixedArgb: color,
    onTertiaryFixedVariantArgb: color,
    errorArgb: color,
    onErrorArgb: color,
    errorContainerArgb: color,
    onErrorContainerArgb: color,
    outlineArgb: color,
    outlineVariantArgb: color,
    surfaceArgb: color,
    onSurfaceArgb: color,
    surfaceDimArgb: color,
    surfaceBrightArgb: color,
    surfaceContainerLowestArgb: color,
    surfaceContainerLowArgb: color,
    surfaceContainerArgb: color,
    surfaceContainerHighArgb: color,
    surfaceContainerHighestArgb: color,
    onSurfaceVariantArgb: color,
    inverseSurfaceArgb: color,
    onInverseSurfaceArgb: color,
    inversePrimaryArgb: color,
    shadowArgb: color,
    scrimArgb: color,
    surfaceTintArgb: color,
    surfaceVariantArgb: color,
  );
}

void main() {
  late MockDatabaseTagApi mockTagApi;
  late FakeAppDatabase mockDb;
  late MockSharedPreferences mockSp;
  late TagsRepository repository;

  setUpAll(() {
    registerFallbackValue(_testTag());
  });

  setUp(() {
    mockTagApi = MockDatabaseTagApi();
    mockDb = FakeAppDatabase();
    mockSp = MockSharedPreferences();
    repository = TagsRepository(
      db: mockDb,
      tagApi: mockTagApi,
      sp: mockSp,
    );
  });

  group('TagsRepository', () {
    test('getTotalCount proxies to tagApi and returns result', () async {
      when(
        () => mockTagApi.getTotalCount(userId: any(named: 'userId')),
      ).thenAnswer((_) async => 5);

      final result = await repository.getTotalCount();

      expect(result, 5);
      verify(() => mockTagApi.getTotalCount(userId: null)).called(1);
    });

    test('getTopLevelTags proxies to tagApi and returns stream', () {
      final tags = [_testTagEntity()];
      when(
        () => mockTagApi.getTopLevelTags(userId: any(named: 'userId')),
      ).thenAnswer((_) => Stream.value(tags));

      final stream = repository.getTopLevelTags();

      expect(stream, emits(tags));
      verify(() => mockTagApi.getTopLevelTags(userId: null)).called(1);
    });

    test('getAllTags proxies to tagApi with notIncludeTagIds', () async {
      final tags = [_testTagEntity()];
      when(
        () => mockTagApi.getAllTags(
          notIncludeTagIds: any(named: 'notIncludeTagIds'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) => Stream.value(tags));

      final stream = repository.getAllTags(notIncludeTagIds: {'tag-2'});

      await expectLater(stream, emits(tags));
      verify(
        () => mockTagApi.getAllTags(
          notIncludeTagIds: {'tag-2'},
          userId: null,
        ),
      ).called(1);
    });

    test('createTag creates tag when no existing tag with same name', () async {
      when(
        () => mockTagApi.getTagEntityByName(any(), any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockTagApi.create(tag: any(named: 'tag')),
      ).thenAnswer((_) async {});

      await repository.createTag(
        name: '  New Tag  ',
        lightColorScheme: _testColorScheme(0xFFFF0000),
        darkColorScheme: _testColorScheme(0xFF0000FF),
      );

      verify(() => mockTagApi.getTagEntityByName('New Tag', null)).called(1);
      verify(() => mockTagApi.create(tag: any(named: 'tag'))).called(1);
    });

    test('createTag does nothing when tag with same name exists', () async {
      final existing = _testTagEntity(name: 'Existing');
      when(
        () => mockTagApi.getTagEntityByName(any(), any()),
      ).thenAnswer((_) async => existing);

      await repository.createTag(
        name: 'Existing',
        lightColorScheme: _testColorScheme(0xFFFF0000),
        darkColorScheme: _testColorScheme(0xFF0000FF),
      );

      verify(() => mockTagApi.getTagEntityByName('Existing', null)).called(1);
      verifyNever(() => mockTagApi.create(tag: any(named: 'tag')));
    });

    test('createTag uses parentTag level for new tag level', () async {
      when(
        () => mockTagApi.getTagEntityByName(any(), any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockTagApi.create(tag: any(named: 'tag')),
      ).thenAnswer((_) async {});

      final parent = _testTagEntity(id: 'parent', name: 'Parent', level: 1);
      await repository.createTag(
        name: 'Child',
        lightColorScheme: _testColorScheme(0xFFFF0000),
        darkColorScheme: _testColorScheme(0xFF0000FF),
        parentTag: parent,
      );

      final captured = verify(
        () => mockTagApi.create(tag: captureAny(named: 'tag')),
      ).captured;
      final createdTag = captured.first as Tag;
      expect(createdTag.level, 2);
      expect(createdTag.parentId, 'parent');
    });

    test('updateTag updates tag when found', () async {
      final tag = _testTag(id: 'tag-1', name: 'Old Name');
      when(() => mockTagApi.getTagById('tag-1')).thenAnswer((_) async => tag);
      when(
        () => mockTagApi.update(tag: any(named: 'tag')),
      ).thenAnswer((_) async {});

      await repository.updateTag(
        id: 'tag-1',
        name: 'New Name',
        lightColorScheme: _testColorScheme(0xFF00FF00),
      );

      verify(() => mockTagApi.getTagById('tag-1')).called(1);
      final captured = verify(
        () => mockTagApi.update(tag: captureAny(named: 'tag')),
      ).captured;
      final updatedTag = captured.first as Tag;
      expect(updatedTag.name, 'New Name');
    });

    test('updateTag does nothing when tag not found', () async {
      when(
        () => mockTagApi.getTagById('unknown'),
      ).thenAnswer((_) async => null);

      await repository.updateTag(id: 'unknown', name: 'New Name');

      verify(() => mockTagApi.getTagById('unknown')).called(1);
      verifyNever(() => mockTagApi.update(tag: any(named: 'tag')));
    });

    test('deleteById proxies to tagApi', () async {
      when(() => mockTagApi.deleteById('tag-1')).thenAnswer((_) async {});

      await repository.deleteById('tag-1');

      verify(() => mockTagApi.deleteById('tag-1')).called(1);
    });

    test('deleteAllTags proxies to tagApi', () async {
      when(() => mockTagApi.deleteAllTags()).thenAnswer((_) async {});

      await repository.deleteAllTags();

      verify(() => mockTagApi.deleteAllTags()).called(1);
    });

    test('getTagEntityById proxies to tagApi and returns result', () async {
      final entity = _testTagEntity(id: 'tag-1');
      when(
        () => mockTagApi.getTagEntityById('tag-1'),
      ).thenAnswer((_) async => entity);

      final result = await repository.getTagEntityById('tag-1');

      expect(result, entity);
      verify(() => mockTagApi.getTagEntityById('tag-1')).called(1);
    });

    test('getTagEntityByName proxies to tagApi and returns result', () async {
      final entity = _testTagEntity(name: 'Work');
      when(
        () => mockTagApi.getTagEntityByName('Work', null),
      ).thenAnswer((_) async => entity);

      final result = await repository.getTagEntityByName('Work');

      expect(result, entity);
      verify(() => mockTagApi.getTagEntityByName('Work', null)).called(1);
    });
  });
}
