import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:planbook_api/planbook_api.dart';

/// 调用方必须持有任务/笔记的写事务；按主键批量比较，避免全量同步反复通知订阅。
/// 关联记录本身的未上传修改也优先保留，不能只检查父任务的 Outbox。
Future<Set<String>> mergeRemoteRows<T extends Table, D extends DataClass>({
  required AppDatabase db,
  required TableInfo<T, D> table,
  required GeneratedColumn<String> idColumn,
  required List<D> rows,
  List<String> Function(D row)? relatedIds,
  Future<Set<String>> Function(Set<String>)? protectedIds,
}) async {
  final accepted = <String>{};
  for (var offset = 0; offset < rows.length; offset += 400) {
    final part = rows.skip(offset).take(400);
    final incoming = {
      for (final row in part) row.toJson()['id'] as String: row,
    };
    final existing = await (db.select(
      table,
    )..where((_) => idColumn.isIn(incoming.keys))).get();
    final previous = {
      for (final row in existing)
        row.toJson()['id'] as String: jsonEncode(row.toJson()),
    };
    final pending =
        await (db.selectOnly(db.syncOutbox)
              ..addColumns([db.syncOutbox.recordId])
              ..where(
                db.syncOutbox.syncedAt.isNull() &
                    db.syncOutbox.recordId.isIn({
                      ...incoming.keys,
                      for (final row in incoming.values)
                        ...?relatedIds?.call(row),
                    }),
              ))
            .get();
    final pendingIds = pending
        .map((r) => r.read(db.syncOutbox.recordId))
        .toSet();
    if (protectedIds != null) {
      pendingIds.addAll(
        await protectedIds({
          ...incoming.keys,
          for (final row in incoming.values) ...?relatedIds?.call(row),
        }),
      );
    }
    final allowed = incoming.entries
        .where(
          (entry) =>
              !pendingIds.contains(entry.key) &&
              !(relatedIds?.call(entry.value).any(pendingIds.contains) ??
                  false),
        )
        .toList();
    accepted.addAll(allowed.map((e) => e.key));
    final changed = allowed.where(
      (entry) =>
          !pendingIds.contains(entry.key) &&
          previous[entry.key] != jsonEncode(entry.value.toJson()),
    );
    if (changed.isEmpty) continue;
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        table,
        changed.map((e) => e.value as Insertable<D>),
      );
    });
  }
  return accepted;
}
