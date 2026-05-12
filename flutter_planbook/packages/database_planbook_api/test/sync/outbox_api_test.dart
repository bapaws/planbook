import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:planbook_api/planbook_api.dart';

import '../test_helper.dart';

void main() {
  group('OutboxApi', () {
    late AppDatabase db;
    late OutboxApi outboxApi;

    setUp(() {
      db = createTestDatabase();
      outboxApi = OutboxApi(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    group('enqueue', () {
      test('inserts a single outbox record', () async {
        await outboxApi.enqueue(
          tableName: 'tasks',
          recordId: 'task-1',
          operation: 'insert',
          payload: '{"id":"task-1"}',
        );

        final pending = await outboxApi.getPending();
        expect(pending, hasLength(1));
        expect(pending.first.targetTable, 'tasks');
        expect(pending.first.recordId, 'task-1');
        expect(pending.first.operation, 'insert');
        expect(pending.first.payload, '{"id":"task-1"}');
        expect(pending.first.retryCount, 0);
        expect(pending.first.syncedAt, isNull);
      });

      test('inserts multiple outbox records', () async {
        await outboxApi.enqueue(
          tableName: 'tasks',
          recordId: 'task-1',
          operation: 'insert',
          payload: '{"id":"task-1"}',
        );
        await outboxApi.enqueue(
          tableName: 'notes',
          recordId: 'note-1',
          operation: 'update',
          payload: '{"id":"note-1"}',
        );

        final pending = await outboxApi.getPending();
        expect(pending, hasLength(2));
      });

      test('sets createdAt to current time', () async {
        final before = DateTime.now().millisecondsSinceEpoch;
        await outboxApi.enqueue(
          tableName: 'tasks',
          recordId: 'task-1',
          operation: 'insert',
          payload: '{}',
        );
        final after = DateTime.now().millisecondsSinceEpoch;

        final pending = await outboxApi.getPending();
        expect(pending.first.createdAt, greaterThanOrEqualTo(before));
        expect(pending.first.createdAt, lessThanOrEqualTo(after));
      });
    });

    group('getPending', () {
      test('returns empty list when no records', () async {
        final pending = await outboxApi.getPending();
        expect(pending, isEmpty);
      });

      test('returns only unsynced records', () async {
        await outboxApi.enqueue(
          tableName: 'tasks',
          recordId: 'task-1',
          operation: 'insert',
          payload: '{}',
        );
        await outboxApi.enqueue(
          tableName: 'tasks',
          recordId: 'task-2',
          operation: 'insert',
          payload: '{}',
        );

        final allPending = await outboxApi.getPending();
        expect(allPending, hasLength(2));

        // Mark first as synced
        await outboxApi.markSynced(allPending.first.id);

        final remaining = await outboxApi.getPending();
        expect(remaining, hasLength(1));
        expect(remaining.first.recordId, 'task-2');
      });

      test('respects limit parameter', () async {
        for (var i = 0; i < 5; i++) {
          await outboxApi.enqueue(
            tableName: 'tasks',
            recordId: 'task-$i',
            operation: 'insert',
            payload: '{}',
          );
        }

        final pending = await outboxApi.getPending(limit: 3);
        expect(pending, hasLength(3));
      });

      test('excludes records with future nextRetryAt', () async {
        await outboxApi.enqueue(
          tableName: 'tasks',
          recordId: 'task-1',
          operation: 'insert',
          payload: '{}',
        );
        final pending = await outboxApi.getPending();
        final id = pending.first.id;

        // Mark as failed with retry in the future
        await outboxApi.markFailed(
          outboxId: id,
          error: 'network error',
          retryCount: 1,
        );

        final afterFail = await outboxApi.getPending();
        expect(afterFail, isEmpty);

        // Wait for retry time to pass
        await Future.delayed(const Duration(seconds: 2));

        final afterWait = await outboxApi.getPending();
        expect(afterWait, hasLength(1));
      });

      test('orders by createdAt ascending', () async {
        await outboxApi.enqueue(
          tableName: 'tasks',
          recordId: 'task-1',
          operation: 'insert',
          payload: '{}',
        );
        await Future.delayed(const Duration(milliseconds: 10));
        await outboxApi.enqueue(
          tableName: 'tasks',
          recordId: 'task-2',
          operation: 'insert',
          payload: '{}',
        );

        final pending = await outboxApi.getPending();
        expect(pending[0].recordId, 'task-1');
        expect(pending[1].recordId, 'task-2');
      });
    });

    group('markSynced', () {
      test('sets syncedAt and resets retry state', () async {
        await outboxApi.enqueue(
          tableName: 'tasks',
          recordId: 'task-1',
          operation: 'insert',
          payload: '{}',
        );
        final pending = await outboxApi.getPending();
        final id = pending.first.id;

        // Simulate failed state
        await outboxApi.markFailed(
          outboxId: id,
          error: 'error',
          retryCount: 2,
        );

        await outboxApi.markSynced(id);

        final afterSync = await db.select(db.syncOutbox).get();
        expect(afterSync.first.syncedAt, isNotNull);
        expect(afterSync.first.retryCount, 0);
        expect(afterSync.first.errorMessage, isNull);
        expect(afterSync.first.nextRetryAt, isNull);
      });
    });

    group('markFailed', () {
      test('increments retryCount and sets nextRetryAt', () async {
        await outboxApi.enqueue(
          tableName: 'tasks',
          recordId: 'task-1',
          operation: 'insert',
          payload: '{}',
        );
        final pending = await outboxApi.getPending();
        final id = pending.first.id;

        final before = DateTime.now().millisecondsSinceEpoch;
        await outboxApi.markFailed(
          outboxId: id,
          error: 'timeout',
          retryCount: 1,
        );
        final after = DateTime.now().millisecondsSinceEpoch + 2000;

        final record = await db.select(db.syncOutbox).getSingle();
        expect(record.retryCount, 1);
        expect(record.errorMessage, 'timeout');
        expect(record.nextRetryAt, greaterThanOrEqualTo(before));
        expect(record.nextRetryAt, lessThanOrEqualTo(after));
      });

      test('backoff increases with retryCount', () async {
        await outboxApi.enqueue(
          tableName: 'tasks',
          recordId: 'task-1',
          operation: 'insert',
          payload: '{}',
        );
        final id = (await outboxApi.getPending()).first.id;

        // retryCount=1 → 1s backoff
        await outboxApi.markFailed(
          outboxId: id,
          error: 'e',
          retryCount: 1,
        );
        final r1 = await db.select(db.syncOutbox).getSingle();
        final backoff1 = r1.nextRetryAt! - r1.createdAt;
        expect(backoff1, greaterThanOrEqualTo(900));
        expect(backoff1, lessThanOrEqualTo(2000));

        // retryCount=5 → 16s backoff
        await outboxApi.markFailed(
          outboxId: id,
          error: 'e',
          retryCount: 5,
        );
        final r5 = await db.select(db.syncOutbox).getSingle();
        final backoff5 = r5.nextRetryAt! - r5.createdAt;
        expect(backoff5, greaterThanOrEqualTo(15000));
        expect(backoff5, lessThanOrEqualTo(17000));

        // retryCount=6 → 60s backoff (capped)
        await outboxApi.markFailed(
          outboxId: id,
          error: 'e',
          retryCount: 6,
        );
        final r6 = await db.select(db.syncOutbox).getSingle();
        final backoff6 = r6.nextRetryAt! - r6.createdAt;
        expect(backoff6, greaterThanOrEqualTo(59000));
        expect(backoff6, lessThanOrEqualTo(61000));
      });
    });

    group('cleanup', () {
      test('removes synced records older than retainDays', () async {
        // Insert and sync an old record by manipulating createdAt directly
        final oldTime = DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch;
        await db.into(db.syncOutbox).insert(
              SyncOutboxCompanion(
                targetTable: const Value('tasks'),
                recordId: const Value('old-task'),
                operation: const Value('insert'),
                payload: const Value('{}'),
                createdAt: Value(oldTime),
                syncedAt: Value(oldTime + 1000),
              ),
            );

        // Insert a recent synced record
        final recentTime = DateTime.now().millisecondsSinceEpoch;
        await db.into(db.syncOutbox).insert(
              SyncOutboxCompanion(
                targetTable: const Value('tasks'),
                recordId: const Value('recent-task'),
                operation: const Value('insert'),
                payload: const Value('{}'),
                createdAt: Value(recentTime),
                syncedAt: Value(recentTime + 1000),
              ),
            );

        // Insert an unsynced old record
        await db.into(db.syncOutbox).insert(
              SyncOutboxCompanion(
                targetTable: const Value('tasks'),
                recordId: const Value('unsynced-old'),
                operation: const Value('insert'),
                payload: const Value('{}'),
                createdAt: Value(oldTime),
              ),
            );

        final deleted = await outboxApi.cleanup(retainDays: 7);
        expect(deleted, 1);

        final remaining = await db.select(db.syncOutbox).get();
        expect(remaining, hasLength(2));
        expect(remaining.map((r) => r.recordId), containsAll(['recent-task', 'unsynced-old']));
      });

      test('returns 0 when no records to clean', () async {
        final deleted = await outboxApi.cleanup();
        expect(deleted, 0);
      });
    });
  });
}
