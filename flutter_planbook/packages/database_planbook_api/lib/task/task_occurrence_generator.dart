import 'dart:async';
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

  final OccurrenceBatchComputer? _computeBatch;
  final _worker = _OccurrenceWorker();
  final _cache = <_CacheKey, List<TaskOccurrencesCompanion>>{};
  final _dates = <_CacheKey, List<int>>{};
  var _cachedRows = 0;
  var _cachedDates = 0;
  Future<void> _tail = Future.value();

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

  List<TaskOccurrencesCompanion> _within(
    List<TaskOccurrencesCompanion> rows,
    Jiffy start,
    Jiffy end,
  ) => rows.where((row) {
    final date = row.occurrenceAt.value.dateTime;
    return !date.isBefore(start.dateTime) && !date.isAfter(end.dateTime);
  }).toList();

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

  Future<List<TaskOccurrencesCompanion>> generate({
    required List<TaskOccurrenceSchedule> schedules,
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
  }) {
    // 串行复用一个 worker，排队期间也可以命中前一个请求产生的缓存。
    final request = _tail.then(
      (_) => _generate(
        schedules: schedules,
        rangeStart: rangeStart.startOf(Unit.day),
        rangeEnd: rangeEnd.startOf(Unit.day),
      ),
    );
    _tail = request.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return request;
  }

  Future<List<TaskOccurrencesCompanion>> _generate({
    required List<TaskOccurrenceSchedule> schedules,
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
  }) async {
    // 同批规则共享检查；时差发生变化的范围不扩大纯计算窗口。
    final window = cacheWindowFor(rangeStart: rangeStart, rangeEnd: rangeEnd);
    final results = <TaskOccurrencesCompanion>[];
    final missing = <TaskOccurrenceSchedule>[];
    for (final schedule in schedules) {
      final (start, end) = _calculationRange(
        schedule,
        rangeStart,
        rangeEnd,
        window,
      );
      final key = _key(schedule, start, end);
      final zone = key.$4;
      var cached = _cache.remove(key);
      if (cached != null) {
        _cache[key] = cached;
      } else if (schedule.rule?.frequency == RecurrenceFrequency.daily) {
        // 每日规则的子窗口可直接截取；其他规则保留原计算器的窗口语义。
        for (final entry in _cache.entries.toList().reversed) {
          final (input, start, end, cachedZone) = entry.key;
          if (input == schedule &&
              cachedZone == zone &&
              !start.isAfter(rangeStart.dateTime) &&
              !end.isBefore(rangeEnd.dateTime) &&
              _hasConstantOffset(start, end)) {
            cached = entry.value
                .where(
                  (o) =>
                      !o.occurrenceAt.value.isBefore(
                        rangeStart,
                        unit: Unit.day,
                      ) &&
                      !o.occurrenceAt.value.isAfter(rangeEnd, unit: Unit.day),
                )
                .toList();
            _cache.remove(entry.key);
            _cache[entry.key] = entry.value;
            break;
          }
        }
      }
      if (cached != null) {
        results.addAll(_within(cached, rangeStart, rangeEnd));
      } else {
        missing.add(schedule);
      }
    }
    if (missing.isEmpty) return results;

    final groups = <(Jiffy, Jiffy), List<TaskOccurrenceSchedule>>{};
    for (final schedule in missing) {
      final range = _calculationRange(schedule, rangeStart, rangeEnd, window);
      (groups[range] ??= []).add(schedule);
    }
    final calculated =
        <TaskOccurrenceSchedule, List<TaskOccurrencesCompanion>>{};
    for (final entry in groups.entries) {
      final (start, end) = entry.key;
      final generated = await (_computeBatch ?? _worker.compute)(
        (schedules: entry.value, rangeStart: start, rangeEnd: end),
      );
      final byTask = <String, List<TaskOccurrencesCompanion>>{};
      for (final row in generated) {
        (byTask[row.taskId.value!] ??= []).add(row);
      }
      for (final schedule in entry.value) {
        final rows =
            byTask[schedule.taskId] ?? const <TaskOccurrencesCompanion>[];
        calculated[schedule] = rows;
        final key = _key(schedule, start, end);
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
      // 后续分组失败也不能留下超过预算的纯计算缓存。
      _trimCaches();
    }
    // 分组计算不能改变原输入顺序；窗口外的纯缓存数据不交给写库层。
    for (final schedule in missing) {
      results.addAll(_within(calculated[schedule]!, rangeStart, rangeEnd));
    }
    return results;
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
    await _tail;
    _worker.close();
    _cache.clear();
    _dates.clear();
    _cachedRows = 0;
    _cachedDates = 0;
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
