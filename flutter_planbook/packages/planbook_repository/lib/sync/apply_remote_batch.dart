import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_repository/sync/merge_remote_rows.dart';
import 'package:planbook_repository/sync/pull_write_fence.dart';
import 'package:supabase_planbook_api/sync/remote_table_pull.dart';

/// 独立合并关联数据，不依赖父记录时间戳或嵌套查询的数量上限。
Future<void> applyRemoteBatch({
  required AppDatabase db,
  required RemoteTableBatch batch,
  required String account,
  required void Function() validateAccount,
  PullWriteFence? fence,
}) async {
  for (final row in batch.rows) {
    if (row['user_id'] != account) throw StateError('远程关联不属于请求账号');
  }
  for (var offset = 0; offset < batch.rows.length; offset += 200) {
    final rows = batch.rows.skip(offset).take(200).toList();
    final accepted = await db.transaction(() async {
      validateAccount();
      final Set<String> result;
      switch (batch.table) {
        case 'tags':
          result = await mergeRemoteRows(
            db: db,
            protectedIds: fence?.blocked,
            table: db.tags,
            idColumn: db.tags.id,
            rows: rows.map(Tag.fromJson).toList(),
          );
        case 'task_tags':
          result = await mergeRemoteRows(
            db: db,
            protectedIds: fence?.blocked,
            table: db.taskTags,
            idColumn: db.taskTags.id,
            rows: rows.map(TaskTag.fromJson).toList(),
            relatedIds: (row) => [row.taskId, row.tagId],
          );
        case 'task_activities':
          result = await mergeRemoteRows(
            db: db,
            protectedIds: fence?.blocked,
            table: db.taskActivities,
            idColumn: db.taskActivities.id,
            rows: rows.map(TaskActivity.fromJson).toList(),
            relatedIds: (row) => [if (row.taskId != null) row.taskId!],
          );
        case 'note_tags':
          result = await mergeRemoteRows(
            db: db,
            protectedIds: fence?.blocked,
            table: db.noteTags,
            idColumn: db.noteTags.id,
            rows: rows.map(NoteTag.fromJson).toList(),
            relatedIds: (row) => [row.noteId, row.tagId],
          );
        default:
          throw StateError('不支持的关联表 ${batch.table}');
      }
      validateAccount();
      return result;
    });
    batch.accept(accepted);
  }

  // 旧 API 会物理替换标签关联。完整清单之后再按 id 二次核实，
  // 避免分页期间新插入或清单缺页被误当成删除；本地仅打软删除标记。
  if (batch.table == 'task_tags' || batch.table == 'note_tags') {
    final List<Map<String, dynamic>> local;
    if (batch.table == 'task_tags') {
      final table = db.taskTags;
      final rows =
          await (db.selectOnly(table)
                ..addColumns([table.id, table.taskId, table.tagId])
                ..where(
                  table.userId.equals(account) & table.deletedAt.isNull(),
                ))
              .get();
      local = rows
          .map(
            (r) => <String, dynamic>{
              'id': r.read(table.id),
              'parent_id': r.read(table.taskId),
              'tag_id': r.read(table.tagId),
            },
          )
          .toList();
    } else {
      final table = db.noteTags;
      final rows =
          await (db.selectOnly(table)
                ..addColumns([table.id, table.noteId, table.tagId])
                ..where(
                  table.userId.equals(account) & table.deletedAt.isNull(),
                ))
              .get();
      local = rows
          .map(
            (r) => <String, dynamic>{
              'id': r.read(table.id),
              'parent_id': r.read(table.noteId),
              'tag_id': r.read(table.tagId),
            },
          )
          .toList();
    }
    final inventory = batch.inventory ?? batch.rows.map((r) => r['id']).toSet();
    final known = batch.knownIds;
    final candidates = local
        .where((r) => !inventory.contains(r['id']))
        .toList();
    for (var offset = 0; offset < candidates.length; offset += 100) {
      final part = candidates.skip(offset).take(100).toList();
      final missing = await batch.confirmMissing(
        part.map((r) => r['id']! as String).toList(),
      );
      validateAccount();
      await db.transaction(() async {
        validateAccount();
        final ids = <String>{};
        for (final row in part.where((r) => missing.contains(r['id']))) {
          // 清单已有基线时，只删除曾经同步过的关联。本地新建、尚未入账的关联留下。
          if (known.isNotEmpty && !known.contains(row['id'])) continue;
          final related = <String>{
            row['id']! as String,
            row['parent_id']! as String,
            row['tag_id']! as String,
          };
          final pending =
              await (db.select(db.syncOutbox)..where(
                    (o) => o.syncedAt.isNull() & o.recordId.isIn(related),
                  ))
                  .get();
          if (pending.isEmpty &&
              (fence == null || (await fence.blocked(related)).isEmpty)) {
            ids.add(row['id']! as String);
          }
        }
        if (ids.isEmpty) return;
        final now = Jiffy.now();
        if (batch.table == 'task_tags') {
          await (db.update(db.taskTags)..where(
                (r) => r.userId.equals(account) & r.id.isIn(ids),
              ))
              .write(TaskTagsCompanion(deletedAt: Value(now)));
        } else {
          await (db.update(db.noteTags)..where(
                (r) => r.userId.equals(account) & r.id.isIn(ids),
              ))
              .write(NoteTagsCompanion(deletedAt: Value(now)));
        }
        validateAccount();
      });
    }
  }
  validateAccount();
  await batch.commit();
}
