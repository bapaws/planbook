import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 只用作相等性比较的服务端行版本，不比较事务号大小或客户端时间。
/// 每轮重新扫描轻量清单，分页期间落在已扫描范围的新记录留待下一轮。
class RemoteTablePull {
  RemoteTablePull({
    required this.sp,
    required this.account,
    required this.page,
  });

  factory RemoteTablePull.supabase({
    required SharedPreferences sp,
    required SupabaseClient client,
    required String account,
    void Function()? validateAccount,
  }) {
    void validate() {
      if (validateAccount != null) {
        validateAccount();
      } else if (client.auth.currentUser?.id != account) {
        throw StateError('分页同步账号已变化');
      }
    }

    return RemoteTablePull(
      sp: sp,
      account: account,
      page: (table, projection, after, ids) async {
        validate();
        var query = client
            .from(table)
            .select(projection)
            .eq('user_id', account);
        if (after != null) query = query.gt('id', after);
        if (ids != null) query = query.inFilter('id', ids);
        final rows = await query.order('id', ascending: true).limit(pageSize);
        validate();
        return rows;
      },
    );
  }

  static const statePrefix = 'remote_row_versions_v1__';
  static const generationKey = 'remote_database_generation_v1';
  static const pageSize = 200;
  final SharedPreferences sp;
  final String account;
  final RemotePage page;

  Future<List<Map<String, dynamic>>> _all(
    String table,
    String projection, {
    List<String>? ids,
  }) async {
    final result = <Map<String, dynamic>>[];
    final seen = <String>{};
    String? after;
    while (true) {
      final rows = await page(table, projection, after, ids);
      if (rows.isEmpty) break;
      for (final row in rows) {
        final id = row['id'];
        if (id is! String || !seen.add(id)) {
          throw StateError('远程 $table 分页主键重复或缺失，停止提交清单');
        }
      }
      result.addAll(rows);
      after = rows.last['id']! as String;
      // 不能根据短页结束：服务端的行数上限可能低于 pageSize。
    }
    return result;
  }

  Future<RemoteTableBatch> pull(String table, {required bool force}) async {
    final generation = sp.getString(generationKey) ?? 'existing';
    final key = '$statePrefix${generation}__${account}__$table';
    final raw = sp.getString(key);
    final previous = raw == null
        ? <String, String>{}
        : raw.length > 65536
        ? await compute(_decodeVersions, raw)
        : _decodeVersions(raw);
    List<Map<String, dynamic>> inventory;
    try {
      inventory = await _all(table, 'id,_sync_version:xmin::text');
      if (inventory.any((r) => r['_sync_version'] is! String)) {
        throw StateError('服务端未返回行版本');
      }
    } on PostgrestException catch (error) {
      // 仅能力不支持才降级；网络、鉴权、权限错误不能伪装成成功空集。
      if (!{'42703', 'PGRST204'}.contains(error.code)) rethrow;
      debugPrint('同步 $table 不支持 xmin，回退分页全量: ${error.code}');
      return RemoteTableBatch(
        table: table,
        rows: await _all(table, '*'),
        inventory: null,
        confirmMissing: (ids) async => ids.toSet()
          ..removeAll(
            (await _all(table, 'id', ids: ids)).map((r) => r['id']! as String),
          ),
        previous: const {},
        save: (_) async {},
      );
    }
    final versions = {
      for (final row in inventory)
        row['id']! as String: row['_sync_version']! as String,
    };
    final changed = versions.keys
        .where((id) => force || previous[id] != versions[id])
        .toList();
    final rows = <Map<String, dynamic>>[];
    for (var offset = 0; offset < changed.length; offset += 100) {
      rows.addAll(
        await _all(
          table,
          '*,_sync_version:xmin::text',
          ids: changed.skip(offset).take(100).toList(),
        ),
      );
    }
    return RemoteTableBatch(
      table: table,
      rows: rows,
      inventory: versions.keys.toSet(),
      confirmMissing: (ids) async => ids.toSet()
        ..removeAll(
          (await _all(table, 'id', ids: ids)).map((r) => r['id']! as String),
        ),
      previous: previous,
      save: (value) async {
        if ((sp.getString(generationKey) ?? 'existing') != generation) {
          throw StateError('业务库已变化，停止提交同步清单');
        }
        final encoded = value.length > 1000
            ? await compute(_encodeVersions, value)
            : _encodeVersions(value);
        if ((sp.getString(generationKey) ?? 'existing') != generation) {
          throw StateError('业务库已变化，停止提交同步清单');
        }
        if (!await sp.setString(key, encoded)) {
          throw StateError('同步清单保存失败');
        }
      },
    );
  }
}

typedef RemotePage =
    Future<List<Map<String, dynamic>>> Function(
      String table,
      String projection,
      String? after,
      List<String>? ids,
    );

/// 只确认已落入本地事务的版本。Outbox 跳过项保留旧版本，下次仍会重拉。
class RemoteTableBatch {
  RemoteTableBatch({
    required this.table,
    required this.rows,
    required this.inventory,
    required this.confirmMissing,
    required Map<String, String> previous,
    required Future<void> Function(Map<String, String>) save,
  }) : _previous = previous,
       _save = save;

  final String table;
  final List<Map<String, dynamic>> rows;
  final Set<String>? inventory;
  final Future<Set<String>> Function(List<String>) confirmMissing;
  final Map<String, String> _previous;
  final Future<void> Function(Map<String, String>) _save;
  final _accepted = <String>{};

  void accept(Iterable<String> ids) => _accepted.addAll(ids);

  Future<void> commit() async {
    final next = Map<String, String>.from(_previous);
    for (final row in rows) {
      if (_accepted.contains(row['id']) && row['_sync_version'] is String) {
        next[row['id']! as String] = row['_sync_version']! as String;
      }
    }
    if (_accepted.isEmpty) return;
    // 不清除消失项：如果远程重建相同 id，仍然有旧版本可供比较。
    await _save(next);
  }
}

/// 保留已有 API 的列表接口，同时让 Repository 接收独立的关联表批次。
class RemoteSyncRows extends UnmodifiableListView<Map<String, dynamic>> {
  RemoteSyncRows(this.batches, String root) : super(batches[root]!.rows);
  final Map<String, RemoteTableBatch> batches;
}

Map<String, String> _decodeVersions(String raw) =>
    Map<String, String>.from(jsonDecode(raw) as Map);

String _encodeVersions(Map<String, String> versions) => jsonEncode(versions);
