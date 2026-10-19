import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_repository/task/alarm_notification_service.dart';
import 'package:planbook_repository/task/alarm_reservation_store.dart';

class _Store implements AlarmReservationStore {
  Map<String, dynamic>? state;
  int writes = 0;
  int? failAt;

  @override
  Future<Map<String, dynamic>?> read() async => state == null
      ? null
      : jsonDecode(jsonEncode(state)) as Map<String, dynamic>;

  @override
  Future<void> write(Map<String, dynamic> next) async {
    if (++writes == failAt) throw StateError('账本保存失败');
    state = jsonDecode(jsonEncode(next)) as Map<String, dynamic>;
  }
}

void main() {
  late _Store store;
  late Map<int, String?> pending;
  late Set<int> active;
  late List<int> scheduled;
  late List<int> canceled;
  late int cleared;
  late bool failSchedule;
  late bool failClear;
  late bool failCancel;
  late bool dropSchedule;
  late bool dropCancel;

  AlarmReservationReconciler engine() => AlarmReservationReconciler(
    store: store,
    now: () => 0,
    pending: () async => Map.of(pending),
    activeIds: () async => active,
    clearPending: () async {
      cleared++;
      if (failClear) throw StateError('原生清理失败');
      pending.clear();
    },
    cancel: (id) async {
      if (failCancel) throw StateError('原生取消失败');
      canceled.add(id);
      if (!dropCancel) pending.remove(id);
    },
    schedule: (id, plan) async {
      if (failSchedule) throw StateError('原生预约失败');
      scheduled.add(id);
      if (!dropSchedule) pending[id] = plan.payload;
    },
  );

  AlarmPlan plan(String key, {String scope = 'task', String? payload}) =>
      AlarmPlan(
        key: key,
        scope: scope,
        title: '提醒',
        at: 1,
        payload: payload ?? key,
      );

  Future<void> reconcile(
    List<AlarmPlan> plans, {
    bool full = true,
    Set<String> scopes = const {},
    void Function()? validate,
  }) => engine().reconcile(
    plans,
    full: full,
    scopes: scopes,
    validate: validate ?? () {},
  );

  setUp(() {
    store = _Store();
    pending = {};
    active = {};
    scheduled = [];
    canceled = [];
    cleared = 0;
    failSchedule = false;
    failClear = false;
    failCancel = false;
    dropSchedule = false;
    dropCancel = false;
  });

  test('旧预约仅清理待触发部分，重建成功后迁移完成', () async {
    pending[99] = null;
    active = {1, 2};
    await reconcile([plan('a'), plan('b')]);
    expect(cleared, 1);
    expect(active, {1, 2});
    expect(pending.keys, [3, 4]);
    expect(store.state!['phase'], 'complete');
  });

  test('独立引擎重启仍复用 ID，无变化时零取消、零新增', () async {
    await reconcile([plan('a'), plan('b')]);
    final initial = Map.of(pending);
    scheduled.clear();
    await reconcile([plan('a'), plan('b')]);
    expect(pending, initial);
    expect(scheduled, isEmpty);
    expect(canceled, isEmpty);
    expect(cleared, 1);
  });

  test('实际三条预约只取消三条，不遍历一千个 ID', () async {
    await reconcile([plan('a'), plan('b'), plan('c')]);
    await reconcile([], full: false, scopes: {'task'});
    expect(canceled, hasLength(3));
    expect(pending, isEmpty);
  });

  test('标题或时间变化更新同一 ID，局部取消不影响其他任务', () async {
    await reconcile([plan('a'), plan('b', scope: 'other')]);
    final first = pending.keys.first;
    scheduled.clear();
    await reconcile([plan('a', payload: 'new')], full: false, scopes: {'task'});
    expect(scheduled, [first]);
    expect(pending[first], 'new');
    await reconcile([], full: false, scopes: {'task'});
    expect(pending.values, ['b']);
  });

  test('系统丢失预约时补齐，账本相同不能掩盖原生缺失', () async {
    await reconcile([plan('a')]);
    final id = pending.keys.single;
    pending.clear();
    scheduled.clear();
    await reconcile([plan('a')]);
    expect(scheduled, [id]);
  });

  test('迁移中原生失败保留 building，重试不再次清理已成功预约', () async {
    failSchedule = true;
    await expectLater(reconcile([plan('a')]), throwsStateError);
    expect(store.state!['phase'], 'building');
    failSchedule = false;
    await reconcile([plan('a')]);
    expect(cleared, 1);
    expect(store.state!['phase'], 'complete');
    expect(pending, hasLength(1));
  });

  test('清理中断可重试，不把未完成迁移当作成功', () async {
    failClear = true;
    await expectLater(reconcile([plan('a')]), throwsStateError);
    expect(store.state!['phase'], 'clearing');
    failClear = false;
    await reconcile([plan('a')]);
    expect(cleared, 2);
    expect(store.state!['phase'], 'complete');
  });

  test('原生静默丢弃预约时不能把迁移标记为完成', () async {
    dropSchedule = true;
    await expectLater(reconcile([plan('a')]), throwsStateError);
    expect(store.state!['phase'], 'building');
    dropSchedule = false;
    await reconcile([plan('a')]);
    expect(store.state!['phase'], 'complete');
    expect(cleared, 1);
  });

  test('保存意图失败时不能发出原生预约', () async {
    await reconcile([]);
    store.failAt = store.writes + 1;
    await expectLater(reconcile([plan('a')]), throwsStateError);
    expect(scheduled, isEmpty);
  });

  test('原生成功但最终账本保存失败，重试通过 payload 校正而不重复预约', () async {
    await reconcile([]);
    store.failAt = store.writes + 2;
    await expectLater(reconcile([plan('a')]), throwsStateError);
    expect(scheduled, hasLength(1));
    store.failAt = null;
    await reconcile([plan('a')]);
    expect(scheduled, hasLength(1));
  });

  test('取消失败保留记录，下次继续取消', () async {
    await reconcile([plan('a')]);
    failCancel = true;
    await expectLater(reconcile([]), throwsStateError);
    expect(store.state!['entries'] as Map, hasLength(1));
    failCancel = false;
    await reconcile([]);
    expect(pending, isEmpty);
  });

  test('先取消失效预约，新预约失败也不能阻止旧预约取消', () async {
    await reconcile([plan('old')]);
    failSchedule = true;
    await expectLater(reconcile([plan('new')]), throwsStateError);
    expect(canceled, hasLength(1));
    expect(pending, isEmpty);
    expect((store.state!['entries'] as Map).containsKey('old'), isFalse);
  });

  test('原生静默取消失败时保留记录，避免留下无法追踪的预约', () async {
    await reconcile([plan('a')]);
    dropCancel = true;
    await expectLater(reconcile([]), throwsStateError);
    expect(store.state!['entries'] as Map, hasLength(1));
    dropCancel = false;
    await reconcile([]);
    expect(pending, isEmpty);
  });

  test('同任务待执行请求合并为最新意图，取消在旧预约之后执行', () async {
    final entered = Completer<void>();
    final resume = Completer<void>();
    final calls = <String>[];
    final queue = AlarmRequestQueue(onError: (error, stack) => fail('$error'));
    final first = queue.run('task', () async {
      calls.add('old');
      entered.complete();
      await resume.future;
    });
    await entered.future;
    final edit = queue.run('task', () async {
      calls.add('edit');
    });
    final cancel = queue.run('task', () async {
      calls.add('cancel');
    });
    expect(identical(edit, cancel), isTrue);
    expect(calls, ['old']);
    resume.complete();
    await Future.wait([first, edit, cancel]);
    expect(calls, ['old', 'cancel']);
  });

  test('队列失败被记录且释放等待者，不阻断下一个任务和重试', () async {
    final errors = <Object>[];
    final calls = <String>[];
    final queue = AlarmRequestQueue(
      onError: (error, stack) => errors.add(error),
    );
    final failed = queue.run('a', () async {
      throw StateError('原生失败');
    });
    final next = queue.run('b', () async {
      calls.add('b');
    });
    await Future.wait([failed, next]);
    await queue.run('a', () async {
      calls.add('retry');
    });
    expect(errors, hasLength(1));
    expect(calls, ['b', 'retry']);
  });

  test('账本版本未知或 ID 冲突时不清理原生数据', () async {
    store.state = {'version': 99};
    await expectLater(reconcile([]), throwsStateError);
    expect(cleared, 0);
    expect(canceled, isEmpty);
  });

  test('迁移必须覆盖全部任务，局部请求不能清空旧提醒', () async {
    await expectLater(reconcile([plan('a')], full: false), throwsStateError);
    expect(cleared, 0);
  });

  test('账号失效时停止后续原生操作，不能标记迁移完成', () async {
    var validations = 0;
    await expectLater(
      reconcile(
        [plan('a')],
        validate: () {
          if (++validations == 4) throw StateError('账号变化');
        },
      ),
      throwsStateError,
    );
    expect(scheduled, isEmpty);
    expect(store.state!['phase'], 'building');
  });

  test('文件账本原子更新且忽略未提交临时文件', () async {
    final directory = Directory.systemTemp.createTempSync('alarm-ledger-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/ledger.json');
    final storage = FileAlarmReservationStore(file);
    await storage.write({'version': 1});
    File('${file.path}.tmp').writeAsStringSync('{unfinished');
    expect(await storage.read(), {'version': 1});
    await storage.write({'version': 2});
    expect(await storage.read(), {'version': 2});
  });

  test('重复实例业务键跨日期滚动稳定，范围仍最多 50 个实例', () async {
    final start = Jiffy.parse('2026-10-18T09:00:00');
    final task = Task(
      id: 't',
      title: '任务',
      layer: 0,
      childCount: 0,
      order: 0,
      isAllDay: false,
      alarms: [EventAlarm.relative(0)],
      startAt: start,
      recurrenceRule: const RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
      ),
      createdAt: start,
    );
    final first = await compute(buildAlarmPlans, (
      tasks: [task.toJson()],
      now: start.subtract(hours: 1).dateTime.millisecondsSinceEpoch,
      zone: 'Asia/Shanghai',
    ));
    final second = buildAlarmPlans((
      tasks: [task.toJson()],
      now: start
          .add(days: 1)
          .subtract(hours: 1)
          .dateTime
          .millisecondsSinceEpoch,
      zone: 'Asia/Shanghai',
    ));
    expect(first, hasLength(50));
    expect(second, hasLength(50));
    expect(first[1].key, second.first.key);
  });

  test('单次全天提醒保留原触发口径，重复配置有不同业务键', () {
    final start = Jiffy.parse('2026-10-18T00:00:00');
    final alarm = EventAlarm.scheduled(dayOffset: 0);
    final task = Task(
      id: 't',
      title: '全天任务',
      layer: 0,
      childCount: 0,
      order: 0,
      isAllDay: true,
      alarms: [alarm, alarm],
      startAt: start,
      createdAt: start,
    );
    final plans = buildAlarmPlans((
      tasks: [task.toJson()],
      now: start.dateTime.millisecondsSinceEpoch,
      zone: 'Asia/Shanghai',
    ));
    expect(plans, hasLength(2));
    expect(plans.first.at, start.add(hours: 9).dateTime.millisecondsSinceEpoch);
    expect(plans.first.key, isNot(plans.last.key));
  });
}
