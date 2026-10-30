// 明确覆盖 force 的两种语义。
// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_planbook_api/sync/remote_table_pull.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences sp;
  late List<Map<String, dynamic>> source;
  late List<(String, String, String?, List<String>?)> calls;
  Future<List<Map<String, dynamic>>> page(
    String table,
    String projection,
    String? after,
    List<String>? ids,
  ) async {
    calls.add((table, projection, after, ids));
    final rows =
        source
            .where(
              (row) =>
                  (after == null ||
                      (row['id']! as String).compareTo(after) > 0) &&
                  (ids == null || ids.contains(row['id'])),
            )
            .toList()
          ..sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));
    return rows
        .take(2)
        .map(
          (row) => projection == 'id'
              ? <String, dynamic>{'id': row['id']}
              : projection.startsWith('id,')
              ? <String, dynamic>{
                  'id': row['id'],
                  '_sync_version': row['_sync_version'],
                }
              : Map<String, dynamic>.from(row),
        )
        .toList();
  }

  RemoteTablePull pull([String account = 'a']) =>
      RemoteTablePull(sp: sp, account: account, page: page);
  Future<void> commit(RemoteTableBatch batch) async {
    batch.accept(batch.rows.map((r) => r['id']! as String));
    await batch.commit();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sp = await SharedPreferences.getInstance();
    calls = [];
    source = List.generate(
      7,
      (i) => {
        'id': 'id$i',
        '_sync_version': '1',
        'user_id': 'a',
        'created_at': '2000-01-01',
        'title': 'old',
      },
    );
  });

  test('短页继续到空页，正文按 id 分页；无变化只扫描轻量清单', () async {
    final batch = await pull().pull('tasks', force: false);
    expect(batch.rows, hasLength(7));
    expect(calls.where((c) => c.$2.startsWith('id,')), hasLength(5));
    await commit(batch);
    calls.clear();
    expect((await pull().pull('tasks', force: false)).rows, isEmpty);
    expect(calls.every((c) => c.$2.startsWith('id,')), isTrue);
  });

  test('超过 1000 条和正文 id 分批边界不漏记录', () async {
    source = List.generate(
      1005,
      (i) => {
        'id': i.toString().padLeft(5, '0'),
        '_sync_version': '7',
      },
    );
    final batch = await pull().pull('task_activities', force: false);
    expect(batch.rows.map((r) => r['id']).toSet(), hasLength(1005));
    expect(
      calls.where((c) => c.$4 != null).every((c) => c.$4!.length <= 100),
      isTrue,
    );
  });

  for (final table in [
    'tasks',
    'notes',
    'tags',
    'task_tags',
    'note_tags',
    'task_activities',
  ]) {
    test('$table 独立变更、旧时间戳、事务号回绕仍按版本差异增量', () async {
      await commit(await pull().pull(table, force: false));
      source[3] = {...source[3], '_sync_version': '0', 'title': 'new'};
      final batch = await pull().pull(table, force: false);
      expect(batch.rows.map((r) => r['id']), ['id3']);
    });
  }

  test('失败未提交、部分记录因 Outbox 跳过都在下一轮重拉', () async {
    final first = await pull().pull('notes', force: false);
    expect((await pull().pull('notes', force: false)).rows, hasLength(7));
    first.accept(['id1']);
    await first.commit();
    final again = await pull().pull('notes', force: false);
    expect(again.rows.map((r) => r['id']), isNot(contains('id1')));
    expect(again.rows, hasLength(6));
  });

  test('正文版本不同于清单时保存实际提交版本，后续更新仍可检测', () async {
    final remote = RemoteTablePull(
      sp: sp,
      account: 'a',
      page: (t, p, a, ids) async {
        if (ids != null) {
          source[0]['_sync_version'] = '2';
        }
        return page(t, p, a, ids);
      },
    );
    await commit(await remote.pull('tasks', force: false));
    expect((await pull().pull('tasks', force: false)).rows, isEmpty);
    source[0]['_sync_version'] = '3';
    expect((await pull().pull('tasks', force: false)).rows, hasLength(1));
  });

  test('清单翻页后插入已扫描范围不推进全局水位，下一轮可补到', () async {
    var added = false;
    final remote = RemoteTablePull(
      sp: sp,
      account: 'a',
      page: (t, p, a, ids) async {
        if (!added && a != null && ids == null) {
          added = true;
          source.add({'id': 'aa', '_sync_version': '9'});
        }
        return page(t, p, a, ids);
      },
    );
    await commit(await remote.pull('tasks', force: false));
    expect(
      (await pull().pull('tasks', force: false)).rows.map((r) => r['id']),
      ['aa'],
    );
  });

  test('主动强刷、换号、业务库代次改变分别重新建立完整基线', () async {
    await commit(await pull().pull('tasks', force: false));
    expect((await pull().pull('tasks', force: true)).rows, hasLength(7));
    expect((await pull('b').pull('tasks', force: false)).rows, hasLength(7));
    await sp.setString(RemoteTablePull.generationKey, 'new-db');
    expect((await pull().pull('tasks', force: false)).rows, hasLength(7));
  });

  test('清单取得后换库拒绝提交旧版本', () async {
    final batch = await pull().pull('tasks', force: false);
    batch.accept(['id0']);
    await sp.setString(RemoteTablePull.generationKey, 'new');
    await expectLater(batch.commit(), throwsStateError);
  });

  test('不支持 xmin 时明确回退分页全量，鉴权失败不能回退为成功', () async {
    final remote = RemoteTablePull(
      sp: sp,
      account: 'a',
      page: (t, p, a, ids) async {
        if (p.contains('xmin')) {
          throw const PostgrestException(message: 'column', code: '42703');
        }
        return page(t, p, a, ids);
      },
    );
    expect((await remote.pull('tasks', force: false)).rows, hasLength(7));
    final denied = RemoteTablePull(
      sp: sp,
      account: 'a',
      page: (t, p, a, ids) async {
        throw const PostgrestException(message: 'denied', code: '42501');
      },
    );
    await expectLater(
      denied.pull('tasks', force: false),
      throwsA(isA<PostgrestException>()),
    );
  });

  test('重复分页主键拒绝完成清单，缺失关联需按 id 二次确认', () async {
    final broken = RemoteTablePull(
      sp: sp,
      account: 'a',
      page: (t, p, a, ids) async => [source[0]],
    );
    await expectLater(broken.pull('tasks', force: false), throwsStateError);
    final batch = await pull().pull('task_tags', force: false);
    source.add({'id': 'late', '_sync_version': '2'});
    expect(await batch.confirmMissing(['late', 'gone']), {'gone'});
  });

  test('消失的行从版本清单移除，相同 id 重建后会重新下载', () async {
    await commit(await pull().pull('tasks', force: false));
    source.removeWhere((row) => row['id'] == 'id3');
    final gone = await pull().pull('tasks', force: false);
    expect(gone.rows, isEmpty);
    await commit(gone);
    source.add({
      'id': 'id3',
      '_sync_version': '1',
      'user_id': 'a',
      'created_at': '2000-01-01',
      'title': 'old',
    });
    expect(
      (await pull().pull('tasks', force: false)).rows.map((row) => row['id']),
      ['id3'],
    );
  });

  test('暂缓删除的关联跨批次保留基线，解除暂缓后移除且重建可重拉', () async {
    await commit(await pull().pull('task_tags', force: false));
    source.removeWhere((row) => row['id'] == 'id3' || row['id'] == 'id4');
    final deferred = await pull().pull('task_tags', force: false);
    deferred.retainMissing(['id3', 'local-new']);
    await commit(deferred);
    final retry = await pull().pull('task_tags', force: true);
    expect(retry.knownIds, contains('id3'));
    expect(retry.knownIds, isNot(contains('id4')));
    expect(retry.knownIds, isNot(contains('local-new')));
    await commit(retry);
    expect(
      (await pull().pull('task_tags', force: false)).knownIds,
      isNot(contains('id3')),
    );
    source.add({'id': 'id3', '_sync_version': '1'});
    expect(
      (await pull().pull('task_tags', force: false)).rows.map((r) => r['id']),
      ['id3'],
    );
  });

  test('版本清单过大时分片保存，缺一片则下次全量', () async {
    source = List.generate(
      1501,
      (i) => {
        'id': 'id${i.toString().padLeft(5, '0')}',
        '_sync_version': '1',
        'user_id': 'a',
        'created_at': '2000-01-01',
        'title': 'old',
      },
    );
    await commit(await pull().pull('tasks', force: false));
    final shards = sp
        .getKeys()
        .where((key) => key.contains('#shard#'))
        .toList();
    expect(shards, hasLength(2));
    expect(
      sp.getInt(shards.first.replaceFirst(RegExp(r'#shard#\d+$'), '#shards')),
      2,
    );
    await sp.remove(shards.first);
    expect((await pull().pull('tasks', force: false)).rows, hasLength(1501));
  });
}
