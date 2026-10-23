// 测试显式区分普通增量和强制全量入口。
// ignore_for_file: avoid_redundant_argument_values
import 'dart:async';

import 'package:flutter_planbook/app/startup/startup_sync_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences sp;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sp = await SharedPreferences.getInstance();
  });
  test('首次登录全量、成功后同账号冷启动增量；重复资料通知不重复拉取', () async {
    final modes = <bool>[];
    Future<void> sync({required bool force}) async => modes.add(force);
    final policy = StartupSyncPolicy(sp);
    await policy.onAccount('a', sync);
    await policy.onAccount('a', sync);
    await StartupSyncPolicy(sp).onAccount('a', sync);
    expect(modes, [true, false]);
  });
  test('换号、注销后重登和注销后的下次启动都保留全量', () async {
    await sp.setString(StartupSyncPolicy.accountKey, 'a');
    final modes = <bool>[];
    Future<void> sync({required bool force}) async => modes.add(force);
    final policy = StartupSyncPolicy(sp);
    await policy.onAccount('a', sync);
    await policy.onAccount('b', sync);
    await policy.onAccount(null, sync);
    await policy.onAccount('b', sync);
    await policy.onAccount(null, sync);
    await StartupSyncPolicy(sp).onAccount('b', sync);
    expect(modes, [false, true, true, true]);
  });
  test('同步失败不标记完成，下次冷启动仍全量', () async {
    await expectLater(
      StartupSyncPolicy(sp).onAccount('a', ({required force}) async {
        throw StateError('local merge failed');
      }),
      throwsStateError,
    );
    await StartupSyncPolicy(sp).onAccount('a', ({required force}) async {
      expect(force, isTrue);
    });
  });
  test('A→B→A 后旧请求晚完成不能覆盖最近一次已完成账号', () async {
    final pending = Completer<void>();
    final policy = StartupSyncPolicy(sp);
    final old = policy.onAccount('a', ({required force}) => pending.future);
    await policy.onAccount('b', ({required force}) async {});
    final current = Completer<void>();
    final again = policy.onAccount('a', ({required force}) => current.future);
    pending.complete();
    await old;
    expect(sp.getString(StartupSyncPolicy.accountKey), 'b');
    current.complete();
    await again;
    expect(sp.getString(StartupSyncPolicy.accountKey), 'a');
  });

  test('同一实例同步失败后可以重试，且仍为全量', () async {
    final policy = StartupSyncPolicy(sp);
    var calls = 0;
    await expectLater(
      policy.onAccount('a', ({required bool force}) async {
        calls++;
        expect(force, isTrue);
        throw StateError('fail');
      }),
      throwsStateError,
    );
    expect(sp.getString(StartupSyncPolicy.accountKey), isNull);
    await policy.onAccount('a', ({required bool force}) async {
      calls++;
      expect(force, isTrue);
    });
    expect(calls, 2);
    expect(sp.getString(StartupSyncPolicy.accountKey), 'a');
  });
}
