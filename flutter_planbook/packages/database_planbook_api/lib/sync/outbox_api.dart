import 'package:drift/drift.dart';
import 'package:planbook_api/planbook_api.dart';

/// Outbox 表的数据访问对象。
///
/// 负责将待同步的变更记录写入 `sync_outbox` 表。
/// 所有业务写操作通过 DatabaseApi 内部自动调用此 API，Repository 层无感知。
///
/// 注意：本 API 不接收事务参数。当在 db.transaction 回调内部调用 enqueue 时，
/// Drift 的嵌套事务机制会自动确保插入操作与外层事务处于同一原子事务中。
class OutboxApi {
  OutboxApi({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  /// 插入 Outbox 记录。
  ///
  /// 应在 db.transaction 回调内部调用，以确保与业务写入同事务。
  Future<void> enqueue({
    required String tableName,
    required String recordId,
    required String operation,
    required String payload,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db
        .into(_db.syncOutbox)
        .insert(
          SyncOutboxCompanion(
            targetTable: Value(tableName),
            recordId: Value(recordId),
            operation: Value(operation),
            payload: Value(payload),
            createdAt: Value(now),
          ),
        );
  }

  /// 检查指定记录是否存在未同步的 Outbox 记录。
  Future<bool> hasPending(String recordId) async {
    final result =
        await (_db.selectOnly(_db.syncOutbox)
              ..addColumns([_db.syncOutbox.id.count()])
              ..where(
                _db.syncOutbox.recordId.equals(recordId) &
                    _db.syncOutbox.syncedAt.isNull(),
              ))
            .getSingleOrNull();
    final count = result?.read(_db.syncOutbox.id.count()) ?? 0;
    return count > 0;
  }

  /// 获取待同步的记录（按创建时间排序，支持批量）
  Future<List<SyncOutboxData>> getPending({int limit = 50}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.select(_db.syncOutbox)
          ..where(
            (o) =>
                o.syncedAt.isNull() &
                (o.nextRetryAt.isNull() |
                    o.nextRetryAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(o) => OrderingTerm.asc(o.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 标记为同步成功
  Future<void> markSynced(int outboxId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(
      _db.syncOutbox,
    )..where((o) => o.id.equals(outboxId))).write(
      SyncOutboxCompanion(
        syncedAt: Value(now),
        retryCount: const Value(0),
        errorMessage: const Value(null),
        nextRetryAt: const Value(null),
      ),
    );
  }

  /// 标记同步失败，更新重试计数和下次重试时间（指数退避）
  Future<void> markFailed({
    required int outboxId,
    required String error,
    required int retryCount,
  }) async {
    final backoffSeconds = _backoffSeconds(retryCount);
    final nextRetry =
        DateTime.now().millisecondsSinceEpoch + backoffSeconds * 1000;
    await (_db.update(
      _db.syncOutbox,
    )..where((o) => o.id.equals(outboxId))).write(
      SyncOutboxCompanion(
        retryCount: Value(retryCount),
        errorMessage: Value(error),
        nextRetryAt: Value(nextRetry),
      ),
    );
  }

  /// 清理已同步且超过 [retainDays] 天的记录（防止 Outbox 无限膨胀）
  Future<int> cleanup({int retainDays = 7}) async {
    final threshold = DateTime.now()
        .subtract(Duration(days: retainDays))
        .millisecondsSinceEpoch;
    return (_db.delete(_db.syncOutbox)..where(
          (o) =>
              o.syncedAt.isNotNull() & o.syncedAt.isSmallerThanValue(threshold),
        ))
        .go();
  }

  static int _backoffSeconds(int retryCount) {
    // 指数退避：1s, 2s, 4s, 8s, 16s, 30s, 60s, 60s...
    if (retryCount <= 0) return 0;
    if (retryCount >= 6) return 60;
    return 1 << (retryCount - 1); // 2^(retryCount-1)
  }
}
