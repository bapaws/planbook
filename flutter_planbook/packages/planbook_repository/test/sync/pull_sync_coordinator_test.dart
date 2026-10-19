import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:planbook_repository/sync/pull_sync_coordinator.dart';

void main() {
  test('合并进行中的完整同步，直到落库完成才完成 Future', () async {
    final coordinator = PullSyncCoordinator();
    final started = Completer<void>();
    final done = Completer<void>();
    var calls = 0;
    Future<void> action({required bool force}) async {
      calls++;
      started.complete();
      await done.future;
    }

    final a = coordinator.run(userId: 'u', force: false, action: action);
    await started.future;
    final b = coordinator.run(userId: 'u', force: false, action: action);
    expect(identical(a, b), isTrue);
    expect(calls, 1);
    done.complete();
    await Future.wait([a, b]);
  });

  test('普通请求之后的强制请求排队一次，不被节流或后续请求吞掉', () async {
    final coordinator = PullSyncCoordinator();
    final entered = Completer<void>();
    final resume = Completer<void>();
    final calls = <bool>[];
    Future<void> action({required bool force}) async {
      calls.add(force);
      if (!force) {
        entered.complete();
        await resume.future;
      }
    }

    final normal = coordinator.run(userId: 'u', force: false, action: action);
    await entered.future;
    final forced = coordinator.run(userId: 'u', force: true, action: action);
    final forcedAgain = coordinator.run(
      userId: 'u',
      force: true,
      action: action,
    );
    expect(identical(forced, forcedAgain), isTrue);
    expect(calls, [false]);
    resume.complete();
    await Future.wait([normal, forced]);
    expect(calls, [false, true]);
  });

  test('失败不进入成功节流，立即重试；账号互不合并', () async {
    final coordinator = PullSyncCoordinator();
    var calls = 0;
    Future<void> action({required bool force}) async {
      if (++calls == 1) throw StateError('落库失败');
    }

    await expectLater(
      coordinator.run(userId: 'a', force: false, action: action),
      throwsStateError,
    );
    await coordinator.run(userId: 'a', force: false, action: action);
    await coordinator.run(userId: 'a', force: false, action: action);
    await coordinator.run(userId: 'b', force: false, action: action);
    expect(calls, 3);
  });

  test('普通失败不阻断已排队的强制请求', () async {
    final coordinator = PullSyncCoordinator();
    final entered = Completer<void>();
    final resume = Completer<void>();
    Future<void> action({required bool force}) async {
      if (!force) {
        entered.complete();
        await resume.future;
        throw StateError('失败');
      }
    }

    final normal = coordinator.run(userId: 'u', force: false, action: action);
    final failure = expectLater(normal, throwsStateError);
    await entered.future;
    final forced = coordinator.run(userId: 'u', force: true, action: action);
    resume.complete();
    await failure;
    await forced;
  });
}
