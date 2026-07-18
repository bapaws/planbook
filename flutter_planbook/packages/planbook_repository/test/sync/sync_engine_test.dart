import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_repository/sync/sync_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:database_planbook_api/sync/outbox_api.dart';

class MockOutboxApi extends Mock implements OutboxApi {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockConnectivity extends Mock implements Connectivity {}

class MockInternetConnectionChecker extends Mock
    implements InternetConnectionChecker {}

/// 伪造的 SupabaseQueryBuilder，支持 upsert/update/insert + await 链式调用。
class FakeSupabaseQueryBuilder implements SupabaseQueryBuilder {
  final List<Invocation> invocations = [];
  Object? _throwError;

  void throwOnAwait(Object error) {
    _throwError = error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
    if (invocation.memberName == #update ||
        invocation.memberName == #insert ||
        invocation.memberName == #upsert) {
      final builder = _FakePostgrestFilterBuilder();
      if (_throwError != null) {
        builder.throwOnAwait(_throwError!);
      }
      return builder;
    }
    return super.noSuchMethod(invocation);
  }
}

/// 伪造的 PostgrestFilterBuilder，支持 `.eq(...)` 链式调用以及 `await`。
class _FakePostgrestFilterBuilder implements PostgrestFilterBuilder {
  final List<Invocation> invocations = [];

  Object? _throwError;

  void throwOnAwait(Object error) {
    _throwError = error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
    if (invocation.memberName == #then) {
      if (_throwError != null) {
        final error = _throwError!;
        final future = Future<dynamic>.error(error, StackTrace.current);
        return (future as dynamic).then(
          invocation.positionalArguments[0],
          onError: invocation.namedArguments[#onError],
        );
      }
      final onValue = invocation.positionalArguments[0] as Function;
      return Future.value(
        onValue(PostgrestResponse<dynamic>(data: null, count: 0)),
      );
    }
    if (invocation.memberName == #eq) return this;
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late MockOutboxApi mockOutboxApi;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockConnectivity mockConnectivity;
  late MockInternetConnectionChecker mockConnectionChecker;
  late FakeSupabaseQueryBuilder fakeQueryBuilder;
  late SyncEngine engine;

  setUp(() {
    mockOutboxApi = MockOutboxApi();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockConnectivity = MockConnectivity();
    mockConnectionChecker = MockInternetConnectionChecker();
    fakeQueryBuilder = FakeSupabaseQueryBuilder();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user-123');
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockSupabase.from(any())).thenAnswer((_) => fakeQueryBuilder);

    engine = SyncEngine(
      outboxApi: mockOutboxApi,
      supabase: mockSupabase,
      connectivity: mockConnectivity,
      connectionChecker: mockConnectionChecker,
    );
  });

  group('triggerSync', () {
    test('没有 pending 记录时什么都不做', () async {
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) async => true);
      when(
        () => mockOutboxApi.getPending(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);

      engine.triggerSync();
      await Future.delayed(Duration.zero);

      verify(() => mockOutboxApi.getPending(limit: 50)).called(1);
      verifyNever(() => mockOutboxApi.markSynced(any()));
      verifyNever(
        () => mockOutboxApi.markFailed(
          outboxId: any(named: 'outboxId'),
          error: any(named: 'error'),
          retryCount: any(named: 'retryCount'),
        ),
      );
    });

    test('有 pending 记录且网络可用时调用 supabase upsert', () async {
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) async => true);
      final pending = [
        SyncOutboxData(
          id: 1,
          targetTable: 'tags',
          recordId: 'tag-1',
          operation: 'insert',
          payload: jsonEncode({'id': 'tag-1', 'name': 'Test'}),
          createdAt: 0,
          retryCount: 0,
        ),
      ];
      when(
        () => mockOutboxApi.getPending(limit: any(named: 'limit')),
      ).thenAnswer((_) async => pending);
      when(() => mockOutboxApi.markSynced(any())).thenAnswer((_) async {});

      engine.triggerSync();
      await Future.delayed(Duration.zero);

      verify(() => mockSupabase.from('tags')).called(1);
      final upsertInvocation = fakeQueryBuilder.invocations.firstWhere(
        (i) => i.memberName == #upsert,
      );
      expect(
        upsertInvocation.positionalArguments[0],
        isA<List<Map<String, dynamic>>>(),
      );
      expect(upsertInvocation.namedArguments[#onConflict], 'id');
      verify(() => mockOutboxApi.markSynced(1)).called(1);
    });

    test('网络不可用时直接返回', () async {
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) async => false);

      engine.triggerSync();
      await Future.delayed(Duration.zero);

      verifyNever(() => mockOutboxApi.getPending(limit: any(named: 'limit')));
    });

    test('成功同步后调用 outboxApi.markSynced', () async {
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) async => true);
      final pending = [
        SyncOutboxData(
          id: 2,
          targetTable: 'notes',
          recordId: 'note-1',
          operation: 'update',
          payload: jsonEncode({'id': 'note-1', 'title': 'Hello'}),
          createdAt: 0,
          retryCount: 0,
        ),
      ];
      when(
        () => mockOutboxApi.getPending(limit: any(named: 'limit')),
      ).thenAnswer((_) async => pending);
      when(() => mockOutboxApi.markSynced(any())).thenAnswer((_) async {});

      engine.triggerSync();
      await Future.delayed(Duration.zero);

      verify(() => mockOutboxApi.markSynced(2)).called(1);
      verifyNever(
        () => mockOutboxApi.markFailed(
          outboxId: any(named: 'outboxId'),
          error: any(named: 'error'),
          retryCount: any(named: 'retryCount'),
        ),
      );
    });

    test('同步失败后调用 outboxApi.markFailed', () async {
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) async => true);
      final pending = [
        SyncOutboxData(
          id: 3,
          targetTable: 'tags',
          recordId: 'tag-2',
          operation: 'insert',
          payload: jsonEncode({'id': 'tag-2'}),
          createdAt: 0,
          retryCount: 0,
        ),
      ];
      when(
        () => mockOutboxApi.getPending(limit: any(named: 'limit')),
      ).thenAnswer((_) async => pending);
      when(
        () => mockOutboxApi.markFailed(
          outboxId: any(named: 'outboxId'),
          error: any(named: 'error'),
          retryCount: any(named: 'retryCount'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockOutboxApi.markSynced(any())).thenAnswer((_) async {});

      // 让 upsert 抛异常
      fakeQueryBuilder.throwOnAwait(
        PostgrestException(message: 'DB error', code: '500'),
      );

      engine.triggerSync();
      await Future.delayed(Duration.zero);

      verify(
        () => mockOutboxApi.markFailed(
          outboxId: 3,
          error: 'DB error',
          retryCount: 1,
        ),
      ).called(1);
      verifyNever(() => mockOutboxApi.markSynced(3));
    });
  });

  group('syncSingle', () {
    test('insert operation calls upsert with user_id', () async {
      final item = SyncOutboxData(
        id: 5,
        targetTable: 'tags',
        recordId: 'tag-insert',
        operation: 'insert',
        payload: jsonEncode({'id': 'tag-insert', 'name': 'Insert'}),
        createdAt: 0,
        retryCount: 0,
      );

      await engine.syncSingle(item);

      final upsertInvocations = fakeQueryBuilder.invocations
          .where((i) => i.memberName == #upsert)
          .toList();
      expect(upsertInvocations, hasLength(1));
      final payload =
          upsertInvocations.first.positionalArguments[0]
              as List<Map<String, dynamic>>;
      expect(payload.first['id'], 'tag-insert');
      expect(payload.first['user_id'], 'user-123');
      expect(upsertInvocations.first.namedArguments[#onConflict], 'id');
    });

    test('update operation calls upsert with user_id', () async {
      final item = SyncOutboxData(
        id: 6,
        targetTable: 'notes',
        recordId: 'note-update',
        operation: 'update',
        payload: jsonEncode({'id': 'note-update', 'title': 'Updated'}),
        createdAt: 0,
        retryCount: 0,
      );

      await engine.syncSingle(item);

      final upsertInvocations = fakeQueryBuilder.invocations
          .where((i) => i.memberName == #upsert)
          .toList();
      expect(upsertInvocations, hasLength(1));
      final payload =
          upsertInvocations.first.positionalArguments[0]
              as List<Map<String, dynamic>>;
      expect(payload.first['id'], 'note-update');
      expect(payload.first['user_id'], 'user-123');
    });

    test('delete operation calls update with deleted_at', () async {
      final item = SyncOutboxData(
        id: 7,
        targetTable: 'tasks',
        recordId: 'task-delete',
        operation: 'delete',
        payload: jsonEncode({'id': 'task-delete'}),
        createdAt: 0,
        retryCount: 0,
      );

      await engine.syncSingle(item);

      final updateInvocations = fakeQueryBuilder.invocations
          .where((i) => i.memberName == #update)
          .toList();
      expect(updateInvocations, hasLength(1));
      final payload = updateInvocations.first.positionalArguments[0] as Map;
      expect(payload.containsKey('deleted_at'), isTrue);
    });

    test('replace_associations 执行 delete + insert 逻辑', () async {
      when(
        () => mockSupabase.from('note_tags'),
      ).thenAnswer((_) => fakeQueryBuilder);

      final item = SyncOutboxData(
        id: 4,
        targetTable: 'note_tags',
        recordId: 'note-1',
        operation: 'replace_associations',
        payload: jsonEncode({
          'parent_id': 'note-1',
          'associations': [
            {'note_id': 'note-1', 'tag_id': 'tag-a'},
            {'note_id': 'note-1', 'tag_id': 'tag-b'},
          ],
        }),
        createdAt: 0,
        retryCount: 0,
      );

      await engine.syncSingle(item);

      verify(() => mockSupabase.from('note_tags')).called(1);

      // update().eq(...) 被调用
      final updateInvocations = fakeQueryBuilder.invocations
          .where((i) => i.memberName == #update)
          .toList();
      expect(updateInvocations, hasLength(1));
      expect(
        updateInvocations.first.positionalArguments[0],
        containsPair('deleted_at', isA<String>()),
      );

      // insert 被调用
      final insertInvocations = fakeQueryBuilder.invocations
          .where((i) => i.memberName == #insert)
          .toList();
      expect(insertInvocations, hasLength(1));
      final inserted =
          insertInvocations.first.positionalArguments[0]
              as List<Map<String, dynamic>>;
      expect(inserted, hasLength(2));
    });

    test(
      'replace_associations with empty associations only calls update',
      () async {
        when(
          () => mockSupabase.from('task_tags'),
        ).thenAnswer((_) => fakeQueryBuilder);

        final item = SyncOutboxData(
          id: 8,
          targetTable: 'task_tags',
          recordId: 'task-empty',
          operation: 'replace_associations',
          payload: jsonEncode({
            'parent_id': 'task-empty',
            'associations': <Map<String, dynamic>>[],
          }),
          createdAt: 0,
          retryCount: 0,
        );

        await engine.syncSingle(item);

        final updateInvocations = fakeQueryBuilder.invocations
            .where((i) => i.memberName == #update)
            .toList();
        expect(updateInvocations, hasLength(1));

        final insertInvocations = fakeQueryBuilder.invocations
            .where((i) => i.memberName == #insert)
            .toList();
        expect(insertInvocations, isEmpty);
      },
    );

    test('replace_associations throws when parent_id is missing', () async {
      when(
        () => mockSupabase.from('note_tags'),
      ).thenAnswer((_) => fakeQueryBuilder);

      final item = SyncOutboxData(
        id: 9,
        targetTable: 'note_tags',
        recordId: 'note-bad',
        operation: 'replace_associations',
        payload: jsonEncode({
          'associations': [
            {'note_id': 'note-bad', 'tag_id': 'tag-a'},
          ],
        }),
        createdAt: 0,
        retryCount: 0,
      );

      expect(() => engine.syncSingle(item), throwsException);
    });
  });

  group('start', () {
    test('triggers sync when wifi connectivity is detected', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => controller.stream);
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) async => true);
      when(
        () => mockOutboxApi.getPending(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);

      engine.start();
      controller.add([ConnectivityResult.wifi]);
      await Future.delayed(Duration.zero);

      verify(() => mockOutboxApi.getPending(limit: 50)).called(1);

      engine.dispose();
      await controller.close();
    });

    test('does not trigger sync when no useful connectivity', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => controller.stream);
      when(
        () => mockOutboxApi.getPending(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);

      engine.start();
      controller.add([ConnectivityResult.none]);
      await Future.delayed(Duration.zero);

      verifyNever(() => mockOutboxApi.getPending(limit: any(named: 'limit')));

      engine.dispose();
      await controller.close();
    });
  });

  group('triggerSync isProcessing', () {
    test('ignores concurrent calls when already processing', () async {
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) async => true);
      when(
        () => mockOutboxApi.getPending(limit: any(named: 'limit')),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return [];
      });

      engine.triggerSync();
      engine.triggerSync(); // should be skipped
      await Future.delayed(const Duration(milliseconds: 150));

      verify(() => mockOutboxApi.getPending(limit: 50)).called(1);
    });
  });

  group('dispose', () {
    test('取消订阅和定时器', () {
      final controller = StreamController<List<ConnectivityResult>>();
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => controller.stream);

      engine.start();
      expect(controller.hasListener, isTrue);

      engine.dispose();
      expect(controller.hasListener, isFalse);
    });
  });
}
