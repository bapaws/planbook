import 'package:drift/drift.dart';
import 'package:planbook_api/planbook_api.dart';

/// 拉取开始时仍待上传、或拉取期间新写入的记录，本轮始终保留本地版本。
/// 即使 Outbox 已被并行上传标记成功，也不能让较早的远端快照覆盖它。
class PullWriteFence {
  PullWriteFence._(this.db, this.lastId, this.pending);
  final AppDatabase db;
  final int lastId;
  final Set<String> pending;

  static Future<PullWriteFence> capture(AppDatabase db) =>
      db.transaction(() async {
        final maximum = db.syncOutbox.id.max();
        final last = await (db.selectOnly(
          db.syncOutbox,
        )..addColumns([maximum])).getSingle();
        final rows = await (db.select(
          db.syncOutbox,
        )..where((o) => o.syncedAt.isNull())).get();
        return PullWriteFence._(
          db,
          last.read(maximum) ?? 0,
          rows.map((r) => r.recordId).toSet(),
        );
      });

  Future<Set<String>> blocked(Set<String> ids) async {
    final rows =
        await (db.select(db.syncOutbox)..where(
              (o) => o.id.isBiggerThanValue(lastId) & o.recordId.isIn(ids),
            ))
            .get();
    return {...pending.intersection(ids), ...rows.map((r) => r.recordId)};
  }

  Future<bool> protects(String id) async => (await blocked({id})).isNotEmpty;
}
