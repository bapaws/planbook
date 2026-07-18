import 'package:database_planbook_api/sync/outbox_api.dart';
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
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #transaction) return Future.value(null);
    return null;
  }
}

class MockOutboxApi extends Mock implements OutboxApi {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Tag(
        id: 'fallback',
        name: 'Fallback',
        order: 0,
        level: 0,
        createdAt: Jiffy.now(),
      ),
    );
  });

  test('debug', () async {
    final mockTagApi = MockDatabaseTagApi();
    final mockDb = FakeAppDatabase();
    final mockOutboxApi = MockOutboxApi();
    final mockSp = MockSharedPreferences();
    final repository = TagsRepository(
      db: mockDb,
      tagApi: mockTagApi,
      outboxApi: mockOutboxApi,
      sp: mockSp,
    );

    when(
      () => mockTagApi.getTotalCount(userId: any(named: 'userId')),
    ).thenAnswer((_) async => 5);

    final result = await repository.getTotalCount();
    expect(result, 5);
  });
}
