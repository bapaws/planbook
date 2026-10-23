import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:database_planbook_api/task/recurrence_rule_calculator.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

/// 只描述日期展开，不携带数据库连接、任务正文或实例的删除状态。
typedef TaskOccurrenceSchedule = ({
  String taskId,
  Jiffy? startAt,
  Jiffy? endAt,
  Jiffy? dueAt,
  RecurrenceRule? rule,
});

typedef TaskOccurrenceBatch = ({
  List<TaskOccurrenceSchedule> schedules,
  Jiffy rangeStart,
  Jiffy rangeEnd,
});

typedef OccurrenceBatchComputer =
    Future<List<TaskOccurrencesCompanion>> Function(TaskOccurrenceBatch);

TaskOccurrenceSchedule occurrenceScheduleOf(Task task) => (
  taskId: task.id,
  startAt: task.startAt,
  endAt: task.endAt,
  dueAt: task.dueAt,
  rule: task.recurrenceRule,
);

/// 同批规则共享一次时区窗口检查，避免逐任务重复扫描日历日期。
typedef TaskOccurrenceCacheWindow = ({
  Jiffy start,
  Jiffy end,
  bool reusable,
});

typedef _CacheKey = (TaskOccurrenceSchedule, DateTime, DateTime, String);

/// 有界缓存只保存纯计算结果；是否需要写入始终重新查询数据库。
class TaskOccurrenceGenerator {
  TaskOccurrenceGenerator({OccurrenceBatchComputer? computeBatch})
    : _computeBatch = computeBatch;

  static final shared = TaskOccurrenceGenerator();
  static const _maxEntries = 128;
  static const _maxRows = 1024;
  static const _maxDateEntries = 1024;
  static const _maxDates = 65536;
  static const _batchSize = 32;
  static const _deliveryRowsPerTurn = 512;
  static const _deliveryCompletionsPerTurn = 4;

  final OccurrenceBatchComputer? _computeBatch;
  final _worker = _OccurrenceWorker();
  final _cache = <_CacheKey, List<TaskOccurrencesCompanion>>{};
  final _dates = <_CacheKey, List<int>>{};
  // 进行中结果独立于有界缓存；即使整批结果超出缓存预算，后续等价请求也不重算。
  final _inFlight = <_CacheKey, Completer<List<TaskOccurrencesCompanion>>>{};
  var _cachedRows = 0;
  var _cachedDates = 0;
  Future<void> _tail = Future.value();
  final _deliveries = Queue<_OccurrenceDelivery>();
  Completer<void>? _resultsIdle;
  var _pendingResults = 0;

  _CacheKey _key(TaskOccurrenceSchedule schedule, Jiffy start, Jiffy end) {
    final from = start.startOf(Unit.day).dateTime;
    final to = end.startOf(Unit.day).dateTime;
    final zone =
        '${from.timeZoneName}/${from.timeZoneOffset}/${to.timeZoneOffset}/'
        '${schedule.startAt?.dateTime}/${schedule.startAt?.dateTime.timeZoneOffset}/'
        '${schedule.endAt?.dateTime}/${schedule.endAt?.dateTime.timeZoneOffset}/'
        '${schedule.dueAt?.dateTime}/${schedule.dueAt?.dateTime.timeZoneOffset}/'
        '${schedule.rule?.recurrenceEnd?.endAt?.dateTime}/'
        '${schedule.rule?.recurrenceEnd?.endAt?.dateTime.timeZoneOffset}';
    return (schedule, from, to, zone);
  }

  /// 当前日期库按固定 24 小时推进。扩大窗口跨过时差变化时，
  /// 原窗口和扩大窗口可能生成不同星期/日期，必须回退原精确窗口。
  TaskOccurrenceCacheWindow cacheWindowFor({
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
  }) {
    final start = rangeStart.startOf(Unit.month);
    final end = rangeEnd.endOf(Unit.month).startOf(Unit.day);
    return (
      start: start,
      end: end,
      reusable:
          !rangeEnd.isBefore(rangeStart, unit: Unit.day) &&
          _hasConstantOffset(start.dateTime, end.dateTime),
    );
  }

  bool _hasConstantOffset(DateTime start, DateTime end) {
    if (start.isUtc != end.isUtc || end.isBefore(start)) return false;
    if (start.isUtc) return true;
    final offset = start.timeZoneOffset;
    var date = start;
    var days = 0;
    while (!date.isAfter(end)) {
      // 限制主 isolate 的检查成本；超长窗口使用原算法。
      if (++days > 366 ||
          date.hour != 0 ||
          date.minute != 0 ||
          date.second != 0 ||
          date.timeZoneOffset != offset) {
        return false;
      }
      final next = DateTime(date.year, date.month, date.day + 1);
      if (!next.isAfter(date)) return false;
      date = next;
    }
    return end.timeZoneOffset == offset;
  }

  /// 固定时差窗口中的月/年规则及明确星期的周规则可按日截取。
  /// 只扩大纯计算缓存范围，返回/写库仍严格截取原三个月业务窗口。
  /// 未指定星期的周规则以查询起点推进，必须保留原窗口，不能套用此优化。
  (Jiffy, Jiffy) _calculationRange(
    TaskOccurrenceSchedule schedule,
    Jiffy start,
    Jiffy end,
    TaskOccurrenceCacheWindow window,
  ) {
    final rule = schedule.rule;
    final stable =
        rule != null &&
        (rule.frequency == RecurrenceFrequency.monthly ||
            rule.frequency == RecurrenceFrequency.yearly ||
            (rule.frequency == RecurrenceFrequency.weekly &&
                (rule.daysOfWeek?.isNotEmpty ?? false)));
    if (stable && window.reusable) return (window.start, window.end);
    return (start, end);
  }

  /// 日期摘要不持有整批 Jiffy/实例对象；调用方仍须核对数据库行是否存在。
  List<int>? expectedDates({
    required TaskOccurrenceSchedule schedule,
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
    TaskOccurrenceCacheWindow? cacheWindow,
  }) {
    final window =
        cacheWindow ??
        cacheWindowFor(rangeStart: rangeStart, rangeEnd: rangeEnd);
    final (start, end) = _calculationRange(
      schedule,
      rangeStart,
      rangeEnd,
      window,
    );
    final key = _key(schedule, start, end);
    final dates = _dates.remove(key);
    if (dates == null) return null;
    _dates[key] = dates;
    final from = rangeStart.startOf(Unit.day).dateTime.microsecondsSinceEpoch;
    final to = rangeEnd.startOf(Unit.day).dateTime.microsecondsSinceEpoch;
    return List<int>.unmodifiable(
      dates.where((date) => date >= from && date <= to),
    );
  }

  /// 入队前固定规则快照，防止调用方修改列表导致缓存键或排队计算发生变化。
  TaskOccurrenceSchedule _snapshot(TaskOccurrenceSchedule schedule) {
    final rule = schedule.rule;
    // 保留旧月份字段，避免快照改写存量规则。
    // ignore: deprecated_member_use
    final legacyMonths = rule?.monthsOfYear;
    return (
      taskId: schedule.taskId,
      startAt: schedule.startAt,
      endAt: schedule.endAt,
      dueAt: schedule.dueAt,
      rule: rule?.copyWith(
        daysOfWeek: rule.daysOfWeek == null
            ? null
            : List.unmodifiable(rule.daysOfWeek!),
        daysOfMonth: rule.daysOfMonth == null
            ? null
            : List.unmodifiable(rule.daysOfMonth!),
        weeksOfMonth: rule.weeksOfMonth == null
            ? null
            : List.unmodifiable(rule.weeksOfMonth!),
        monthsOfYear: legacyMonths == null
            ? null
            : List.unmodifiable(legacyMonths),
        daysOfYear: rule.daysOfYear == null
            ? null
            : List.unmodifiable(rule.daysOfYear!),
      ),
    );
  }

  Future<List<TaskOccurrencesCompanion>> generate({
    required List<TaskOccurrenceSchedule> schedules,
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
  }) {
    final from = rangeStart.startOf(Unit.day);
    final to = rangeEnd.startOf(Unit.day);
    final window = cacheWindowFor(rangeStart: from, rangeEnd: to);
    final requests = <Future<List<TaskOccurrencesCompanion>>>[];
    final missing = <(Jiffy, Jiffy), List<_CacheKey>>{};
    for (final input in schedules) {
      final schedule = _snapshot(input);
      final (start, end) = _calculationRange(schedule, from, to, window);
      final key = _key(schedule, start, end);
      final cached = _cached(key, from, to);
      if (cached != null) {
        requests.add(Future.value(cached));
        continue;
      }
      var pending = _inFlight[key];
      if (pending == null) {
        pending = Completer<List<TaskOccurrencesCompanion>>();
        _inFlight[key] = pending;
        (missing[(start, end)] ??= []).add(key);
      }
      requests.add(pending.future);
    }
    for (final entry in missing.entries) {
      var batch = <_CacheKey>[];
      final ids = <String>{};
      for (final key in entry.value) {
        // worker 按任务 ID 分组返回；同 ID 的不同版本必须分批，不能混合结果。
        if (batch.length == _batchSize || ids.contains(key.$1.taskId)) {
          _enqueue(batch, entry.key);
          batch = [];
          ids.clear();
        }
        batch.add(key);
        ids.add(key.$1.taskId);
      }
      if (batch.isNotEmpty) _enqueue(batch, entry.key);
    }
    // 只收集共享结果引用；裁剪、拼接和完成通知由同一有界队列分批处理。
    _pendingResults++;
    _resultsIdle ??= Completer<void>();
    return Future.wait(
      requests,
    ).then((parts) => _deliver(parts, from, to)).whenComplete(() {
      if (--_pendingResults == 0) {
        final idle = _resultsIdle!;
        _resultsIdle = null;
        idle.complete();
      }
    });
  }

  Future<List<TaskOccurrencesCompanion>> _deliver(
    List<List<TaskOccurrencesCompanion>> parts,
    Jiffy from,
    Jiffy to,
  ) {
    final delivery = _OccurrenceDelivery(parts, from.dateTime, to.dateTime);
    final wasEmpty = _deliveries.isEmpty;
    _deliveries.add(delivery);
    if (wasEmpty) Timer.run(_drainDeliveries);
    return delivery.completer.future;
  }

  void _drainDeliveries() {
    final watch = Stopwatch()..start();
    var processed = 0;
    var completed = 0;
    // 全部日期共享每轮预算，避免每个 Future 各自让出后同时恢复形成微任务长链。
    while (_deliveries.isNotEmpty &&
        processed < _deliveryRowsPerTurn &&
        completed < _deliveryCompletionsPerTurn &&
        watch.elapsedMicroseconds < 2000) {
      final delivery = _deliveries.removeFirst();
      try {
        processed += delivery.advance(_batchSize);
        if (delivery.isDone) {
          completed++;
          delivery.completer.complete(delivery.result);
        } else {
          _deliveries.add(delivery);
        }
      } on Object catch (error, stack) {
        completed++;
        delivery.completer.completeError(error, stack);
      }
    }
    if (_deliveries.isNotEmpty) Timer.run(_drainDeliveries);
  }

  List<TaskOccurrencesCompanion>? _cached(
    _CacheKey key,
    Jiffy rangeStart,
    Jiffy rangeEnd,
  ) {
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    if (key.$1.rule?.frequency == RecurrenceFrequency.daily) {
      // 保留原每日子窗口复用规则；跨时差或不包含原窗口时不复用。
      for (final entry in _cache.entries.toList().reversed) {
        final (input, start, end, zone) = entry.key;
        if (input == key.$1 &&
            zone == key.$4 &&
            !start.isAfter(rangeStart.dateTime) &&
            !end.isBefore(rangeEnd.dateTime) &&
            _hasConstantOffset(start, end)) {
          _cache.remove(entry.key);
          _cache[entry.key] = entry.value;
          return entry.value;
        }
      }
    }
    return null;
  }

  void _enqueue(List<_CacheKey> keys, (Jiffy, Jiffy) range) {
    // 单 worker 串行、每批至多 32 个规则；队列只等待纯计算，不等待写事务。
    _tail = _tail.then((_) => _compute(keys, range));
  }

  Future<void> _compute(List<_CacheKey> keys, (Jiffy, Jiffy) range) async {
    try {
      final generated = await (_computeBatch ?? _worker.compute)(
        (
          schedules: keys.map((key) => key.$1).toList(),
          rangeStart: range.$1,
          rangeEnd: range.$2,
        ),
      );
      final byTask = <String, List<TaskOccurrencesCompanion>>{};
      for (final row in generated) {
        (byTask[row.taskId.value!] ??= []).add(row);
      }
      final results = <_CacheKey, List<TaskOccurrencesCompanion>>{};
      for (final key in keys) {
        final rows = List<TaskOccurrencesCompanion>.unmodifiable(
          byTask[key.$1.taskId] ?? const [],
        );
        results[key] = rows;
        _cachedRows -= _cache.remove(key)?.length ?? 0;
        _cache[key] = rows;
        _cachedRows += rows.length;
        final dates = List<int>.unmodifiable(
          rows.map(
            (row) => row.occurrenceAt.value.dateTime.microsecondsSinceEpoch,
          ),
        );
        _cachedDates -= _dates.remove(key)?.length ?? 0;
        _dates[key] = dates;
        _cachedDates += dates.length;
      }
      _trimCaches();
      for (final key in keys) {
        _inFlight.remove(key)!.complete(results[key]!);
      }
    } on Object catch (error, stack) {
      // 失败通知所有共享者并移除占位，不能污染后续重试或阻塞队列。
      for (final key in keys) {
        _inFlight.remove(key)?.completeError(error, stack);
      }
    }
    // 批次之间让出事件循环，避免大量完成回调连续挤占首屏动画。
    await Future<void>.delayed(Duration.zero);
  }

  void _trimCaches() {
    while (_cache.length > _maxEntries || _cachedRows > _maxRows) {
      _cachedRows -= _cache.remove(_cache.keys.first)!.length;
    }
    while (_dates.length > _maxDateEntries || _cachedDates > _maxDates) {
      _cachedDates -= _dates.remove(_dates.keys.first)!.length;
    }
  }

  /// 释放闲置 worker；正常运行时 worker 也会在空闲后自动退出。
  Future<void> close() async {
    // 完成回调可能追加重试；等到队列稳定后再释放 worker。
    while (true) {
      final tail = _tail;
      await tail;
      await _resultsIdle?.future;
      // 结果回调也可能追加计算或缓存命中的分发，待其入队后再检查收尾。
      await Future<void>.delayed(Duration.zero);
      if (identical(tail, _tail) && _resultsIdle == null) break;
    }
    _worker.close();
    _cache.clear();
    _dates.clear();
    _cachedRows = 0;
    _cachedDates = 0;
  }
}

/// 每个请求独立持有原窗口、游标和结果；纯缓存行仍保持只读且不代表库内覆盖。
class _OccurrenceDelivery {
  _OccurrenceDelivery(this.parts, this.from, this.to);

  final List<List<TaskOccurrencesCompanion>> parts;
  final DateTime from;
  final DateTime to;
  final result = <TaskOccurrencesCompanion>[];
  final completer = Completer<List<TaskOccurrencesCompanion>>();
  int _part = 0;
  int _row = 0;

  bool get isDone => _part == parts.length;

  int advance(int limit) {
    var processed = 0;
    while (!isDone && processed < limit) {
      processed++;
      final rows = parts[_part];
      if (_row == rows.length) {
        _part++;
        _row = 0;
        continue;
      }
      final row = rows[_row++];
      // 窗口边界只转换一次，避免原实现逐行重复创建起止 DateTime。
      final date = row.occurrenceAt.value.dateTime;
      if (!date.isBefore(from) && !date.isAfter(to)) result.add(row);
    }
    return processed;
  }
}

class _OccurrenceWorker {
  Isolate? _isolate;
  ReceivePort? _responses;
  SendPort? _commands;
  Completer<SendPort>? _ready;
  Completer<List<TaskOccurrencesCompanion>>? _pending;
  Timer? _idle;

  Future<List<TaskOccurrencesCompanion>> compute(
    TaskOccurrenceBatch batch,
  ) async {
    if (kIsWeb) return generateTaskOccurrenceBatch(batch);
    _idle?.cancel();
    if (_commands == null) {
      final responses = _responses = ReceivePort();
      final ready = _ready = Completer<SendPort>();
      responses.listen(_onMessage);
      try {
        _isolate = await Isolate.spawn(
          _runOccurrenceWorker,
          responses.sendPort,
          debugName: 'task-occurrences',
          onError: responses.sendPort,
          onExit: responses.sendPort,
        );
        _commands = await ready.future;
      } on Object {
        close();
        rethrow;
      }
    }
    final pending = _pending = Completer<List<TaskOccurrencesCompanion>>();
    try {
      _commands!.send(batch);
      return await pending.future;
    } finally {
      _pending = null;
      if (_isolate != null) _idle = Timer(const Duration(seconds: 10), close);
    }
  }

  void _onMessage(dynamic message) {
    if (message is SendPort) {
      _ready!.complete(message);
    } else if (message case (
      final List<TaskOccurrencesCompanion>? rows,
      final String? error,
      final String? stack,
    )) {
      final pending = _pending;
      if (pending == null || pending.isCompleted) return;
      if (error != null) {
        pending.completeError(RemoteError(error, stack ?? ''));
      } else {
        pending.complete(rows!);
      }
    } else {
      final error = RemoteError('实例计算 worker 意外退出：$message', '');
      if (_ready case final ready? when !ready.isCompleted) {
        ready.completeError(error);
      }
      if (_pending case final pending? when !pending.isCompleted) {
        pending.completeError(error);
      }
      close();
    }
  }

  void close() {
    _idle?.cancel();
    _isolate?.kill(priority: Isolate.immediate);
    _responses?.close();
    _isolate = null;
    _responses = null;
    _commands = null;
    _ready = null;
  }
}

void _runOccurrenceWorker(SendPort responses) {
  final commands = ReceivePort();
  responses.send(commands.sendPort);
  commands.listen((dynamic message) {
    try {
      responses.send((
        generateTaskOccurrenceBatch(message as TaskOccurrenceBatch),
        null,
        null,
      ));
    } on Object catch (error, stack) {
      responses.send((null, error.toString(), stack.toString()));
    }
  });
}

/// 纯计算入口，也用于计算结果等价性测试。
List<TaskOccurrencesCompanion> generateTaskOccurrenceBatch(
  TaskOccurrenceBatch input,
) {
  return [
    for (final schedule in input.schedules)
      ..._generateScheduledOccurrences(
        schedule: schedule,
        rangeStart: input.rangeStart,
        rangeEnd: input.rangeEnd,
      ),
  ];
}

List<TaskOccurrencesCompanion> _generateScheduledOccurrences({
  required TaskOccurrenceSchedule schedule,
  required Jiffy rangeStart,
  required Jiffy rangeEnd,
}) {
  final startDate = schedule.startAt ?? schedule.dueAt;
  final rule = schedule.rule;
  if (startDate == null || rule == null) return [];
  final dates = RecurrenceRuleCalculator.generateOccurrences(
    rule: rule,
    startDate: startDate,
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
  );
  return dates.map((date) {
    // 按日历日偏移，避免带时分的起点被 24h 截断少算一天。
    final daysDiff = date
        .startOf(Unit.day)
        .diff(startDate.startOf(Unit.day), unit: Unit.day)
        .toInt();
    return TaskOccurrencesCompanion.insert(
      taskId: Value(schedule.taskId),
      occurrenceAt: date.startOf(Unit.day),
      startAt: Value(schedule.startAt?.add(days: daysDiff)),
      endAt: Value(schedule.endAt?.add(days: daysDiff)),
      dueAt: Value(schedule.dueAt?.add(days: daysDiff)),
    );
  }).toList();
}
