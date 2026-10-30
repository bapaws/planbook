// 测试显式区分普通增量和强制全量入口。
// ignore_for_file: avoid_redundant_argument_values
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_planbook_api/sync/remote_table_pull.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final initiallyValid in [true, false]) {
    test('分页账号变化立即停止（请求前有效：$initiallyValid）', () async {
      SharedPreferences.setMockInitialValues({});
      var valid = initiallyValid;
      var requests = 0;
      final client = SupabaseClient(
        'https://example.invalid',
        'key',
        httpClient: MockClient((request) async {
          requests++;
          valid = false;
          return http.Response(
            '[{"id":"a","_sync_version":"1"}]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final pull = RemoteTablePull.supabase(
        sp: await SharedPreferences.getInstance(),
        client: client,
        account: 'a',
        validateAccount: () {
          if (!valid) throw StateError('account changed');
        },
      );
      await expectLater(pull.pull('tasks', force: false), throwsStateError);
      expect(requests, initiallyValid ? 1 : 0);
    });
  }
  test('真实 PostgREST builder 带账号过滤、主键翻页、版本投影和正文 id 过滤', () async {
    SharedPreferences.setMockInitialValues({});
    final requests = <Uri>[];
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request.url);
        final params = request.url.queryParameters;
        expect(params['user_id'], 'eq.account-a');
        expect(params['order'], startsWith('id.asc'));
        expect(params['limit'], '200');
        final after = params['id']?.startsWith('gt.') ?? false;
        final ids = request.url.queryParametersAll['id'] ?? [];
        final isBody = params['select']!.startsWith('*,');
        if (isBody) expect(ids.any((v) => v.startsWith('in.')), isTrue);
        final rows = after || ids.any((v) => v.startsWith('gt.'))
            ? <Map<String, dynamic>>[]
            : [
                <String, dynamic>{
                  'id': 'a',
                  '_sync_version': '42',
                  if (isBody) 'title': 'task',
                },
              ];
        return http.Response(
          jsonEncode(rows),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final batch = await RemoteTablePull.supabase(
      sp: await SharedPreferences.getInstance(),
      client: client,
      account: 'account-a',
      validateAccount: () {},
    ).pull('tasks', force: false);
    expect(batch.rows.single['title'], 'task');
    expect(
      requests.first.queryParameters['select'],
      'id,_sync_version:xmin::text',
    );
    expect(requests, hasLength(4));
  });
}
