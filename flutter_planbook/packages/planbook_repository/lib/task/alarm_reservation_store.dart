import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 独立设备账本，不进入业务 SQLite 或云端同步。
abstract interface class AlarmReservationStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> state);
}

class FileAlarmReservationStore implements AlarmReservationStore {
  FileAlarmReservationStore(this.file);
  final File file;

  @override
  Future<Map<String, dynamic>?> read() async {
    if (!file.existsSync()) return null;
    return compute(_decodeAlarmState, await file.readAsString());
  }

  @override
  Future<void> write(Map<String, dynamic> state) async {
    await file.parent.create(recursive: true);
    // 单写队列内同目录原子替换；崩溃前的旧账本始终可读，不先删除旧文件。
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      await compute(jsonEncode, state),
      flush: true,
    );
    await temporary.rename(file.path);
  }
}

Map<String, dynamic> _decodeAlarmState(String value) =>
    jsonDecode(value) as Map<String, dynamic>;

/// 原生调度和账本只有一个写者，待执行的同任务请求以最新意图合并。
class AlarmRequestQueue {
  AlarmRequestQueue({required this.onError});
  final void Function(Object error, StackTrace stack) onError;
  final _jobs = <String, _AlarmJob>{};
  bool _draining = false;

  Future<void> run(String key, Future<void> Function() action) {
    final pending = _jobs[key];
    if (pending != null) {
      pending.action = action;
      return pending.done.future;
    }
    final job = _AlarmJob(action);
    _jobs[key] = job;
    unawaited(_drain());
    return job.done.future;
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_jobs.isNotEmpty) {
        final job = _jobs.remove(_jobs.keys.first)!;
        try {
          await job.action();
        } on Object catch (error, stack) {
          onError(error, stack);
        } finally {
          job.done.complete();
        }
      }
    } finally {
      _draining = false;
    }
  }
}

class _AlarmJob {
  _AlarmJob(this.action);
  Future<void> Function() action;
  final done = Completer<void>();
}

class AlarmPlan {
  const AlarmPlan({
    required this.key,
    required this.scope,
    required this.title,
    required this.at,
    required this.payload,
  });
  final String key;
  final String scope;
  final String title;
  final int at;
  final String payload;
}

/// 原生成功与账本写入不构成一个事务；通过系统 payload 在重试时校正。
class AlarmReservationReconciler {
  AlarmReservationReconciler({
    required this.store,
    required this.pending,
    required this.activeIds,
    required this.clearPending,
    required this.cancel,
    required this.schedule,
    int Function()? now,
  }) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AlarmReservationStore store;
  final Future<Map<int, String?>> Function() pending;
  final Future<Set<int>> Function() activeIds;
  final Future<void> Function() clearPending;
  final Future<void> Function(int id) cancel;
  final Future<void> Function(int id, AlarmPlan plan) schedule;
  final int Function() _now;

  Future<Map<String, dynamic>> _read() async {
    final state =
        await store.read() ??
        <String, dynamic>{
          'version': 1,
          'phase': 'legacy',
          'nextId': 1,
          'entries': <String, dynamic>{},
        };
    if (state['version'] != 1 ||
        ![
          'legacy',
          'clearing',
          'building',
          'complete',
        ].contains(state['phase']) ||
        state['nextId'] is! int ||
        (state['nextId'] as int) <= 0 ||
        (state['nextId'] as int) > 0x80000000 ||
        state['entries'] is! Map) {
      throw StateError('提醒账本格式无法识别，保留现场，不清理系统预约');
    }
    final ids = <int>{};
    for (final value in (state['entries'] as Map).values) {
      final entry = value as Map;
      final id = entry['id'] as int;
      if (id <= 0 ||
          id > 0x7fffffff ||
          !ids.add(id) ||
          entry['scope'] is! String ||
          entry['payload'] is! String) {
        throw StateError('提醒账本记录无效，不清理系统预约');
      }
    }
    return state;
  }

  Future<bool> needsMigration() async => (await _read())['phase'] != 'complete';

  Future<void> reconcile(
    List<AlarmPlan> plans, {
    required bool full,
    required Set<String> scopes,
    required void Function() validate,
  }) async {
    validate();
    final state = await _read();
    var system = await pending();
    final reserved = {...system.keys, ...await activeIds()};
    validate();
    if (state['phase'] != 'complete' && !full) {
      throw StateError('提醒迁移必须读取全部单次和重复任务后执行');
    }
    if (state['phase'] == 'legacy' || state['phase'] == 'clearing') {
      state['phase'] = 'clearing';
      await store.write(state);
      validate();
      // 仅当前服务使用本地预约插件；此 API 保留已经展示的通知。
      await clearPending();
      state['phase'] = 'building';
      await store.write(state);
      system = {};
    }
    final entries = Map<String, dynamic>.from(state['entries'] as Map);
    state['entries'] = entries;
    reserved.addAll(entries.values.map((e) => (e as Map)['id'] as int));
    final wanted = {for (final plan in plans) plan.key: plan};
    for (final plan in plans) {
      final previous = entries[plan.key] as Map?;
      var nextId = state['nextId'] as int;
      if (previous == null) {
        while (reserved.contains(nextId)) {
          nextId++;
        }
        if (nextId > 0x7fffffff) throw StateError('提醒 ID 空间耗尽');
        reserved.add(nextId);
        state['nextId'] = nextId + 1;
      }
      entries[plan.key] = <String, dynamic>{
        'id': previous?['id'] ?? nextId,
        'scope': plan.scope,
        'payload': plan.payload,
      };
    }
    // 先持久化 ID 和意图，崩溃后不会重新分配并留下失联的系统预约。
    await store.write(state);
    var changed = false;
    final removed = <String, Map<dynamic, dynamic>>{};
    try {
      for (final key in entries.keys.toList()) {
        validate();
        final entry = entries[key] as Map;
        final id = entry['id'] as int;
        final plan = wanted[key];
        if (plan == null && (full || scopes.contains(entry['scope']))) {
          if (system.containsKey(id)) {
            await cancel(id);
            changed = true;
            removed[key] = entry;
          }
          entries.remove(key);
        }
      }
      // 先移除失效预约再补齐，避免系统容量限制阻止取消或导致迁移反复失败。
      for (final plan in plans) {
        validate();
        final id = (entries[plan.key] as Map)['id'] as int;
        if (plan.at > _now() && system[id] != plan.payload) {
          await schedule(id, plan);
          changed = true;
        }
      }
      if (changed) {
        final confirmed = await pending();
        var cancellationFailed = false;
        for (final entry in removed.entries) {
          if (confirmed.containsKey(entry.value['id'])) {
            entries[entry.key] = entry.value;
            cancellationFailed = true;
          }
        }
        if (cancellationFailed) throw StateError('系统未取消预约，保留记录重试');
        for (final plan in plans) {
          final id = (entries[plan.key] as Map)['id'] as int;
          if (plan.at > _now() && confirmed[id] != plan.payload) {
            throw StateError('系统未保留预约，保留重试状态，不标记迁移完成');
          }
        }
      }
      validate();
      if (full) state['phase'] = 'complete';
    } finally {
      // 原生失败则 phase 不完成，保留意图，下次用系统实际预约继续校正。
      await store.write(state);
    }
  }
}
