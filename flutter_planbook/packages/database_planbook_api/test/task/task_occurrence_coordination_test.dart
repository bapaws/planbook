import 'dart:async';
import 'dart:io';

import 'package:database_planbook_api/task/task_occurrence_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

TaskOccurrenceSchedule _schedule({
  String id = 'series',
  RecurrenceRule rule = const RecurrenceRule(
    frequency: RecurrenceFrequency.monthly,
  ),
  Jiffy? start,
  Jiffy? end,
  Jiffy? due,
}) => (
  taskId: id,
  startAt: start ?? Jiffy.parse('2026-05-01 09:00'),
  endAt: end,
  dueAt: due,
  rule: rule,
);

List<Object?> _values(List<TaskOccurrencesCompanion> rows) => [
  for (final row in rows)
    (
      row.taskId.value,
      row.occurrenceAt.value,
      row.startAt.value,
      row.endAt.value,
      row.dueAt.value,
    ),
];

Future<List<List<TaskOccurrencesCompanion>>> _expectSpread(
  Future<List<TaskOccurrencesCompanion>> Function(int) request,
) async {
  var turn = 0;
  var running = true;
  Timer? timer;
  void tick() {
    turn++;
    if (running) timer = Timer(Duration.zero, tick);
  }

  timer = Timer(Duration.zero, tick);
  final completions = <int, int>{};
  try {
    final results = await Future.wait([
      for (var i = 0; i < 28; i++)
        request(i).then((rows) {
          completions.update(turn, (value) => value + 1, ifAbsent: () => 1);
          return rows;
        }),
    ]);
    expect(completions.length, greaterThan(1));
    expect(completions.values.every((count) => count <= 4), isTrue);
    expect(completions.containsKey(0), isFalse);
    return results;
  } finally {
    running = false;
    timer?.cancel();
  }
}

void main() {
  final day = Jiffy.parse('2026-06-13');

  test('快速切换十八个日期共享超缓存容量的进行中计算，且保持各自范围和顺序', () async {
    var calls = 0;
    var active = 0;
    var peak = 0;
    final batchSizes = <int>[];
    final entered = Completer<void>();
    final resume = Completer<void>();
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        calls++;
        active++;
        if (active > peak) peak = active;
        batchSizes.add(input.schedules.length);
        if (calls == 1) {
          entered.complete();
          await resume.future;
        }
        final rows = generateTaskOccurrenceBatch(input);
        active--;
        return rows;
      },
    );
    addTearDown(generator.close);
    final schedules = [for (var i = 0; i < 40; i++) _schedule(id: 'task-$i')];
    final inputs = [
      for (var i = 0; i < 18; i++)
        (
          schedules: i.isEven
              ? schedules
              : schedules.reversed.take(35).toList(),
          rangeStart: day.add(days: i),
          rangeEnd: day.add(days: i).add(months: 3),
        ),
    ];
    final requests = [
      for (final input in inputs)
        generator.generate(
          schedules: input.schedules,
          rangeStart: input.rangeStart,
          rangeEnd: input.rangeEnd,
        ),
    ];
    await entered.future;
    expect(calls, 1);
    resume.complete();
    final results = await Future.wait(requests);
    for (var i = 0; i < inputs.length; i++) {
      expect(
        _values(results[i]),
        _values(generateTaskOccurrenceBatch(inputs[i])),
      );
    }
    expect(results.first.length, greaterThan(1024));
    expect(calls, 2);
    expect(peak, 1);
    expect(batchSizes, [32, 8]);
    results.first.clear();
    expect(results.last, isNotEmpty);
  });

  test('大批共享结果裁剪和分发跨事件循环执行，每轮最多完成四个日期请求', () async {
    var calls = 0;
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        calls++;
        return generateTaskOccurrenceBatch(input);
      },
    );
    addTearDown(generator.close);
    final from = Jiffy.parse('2026-06-01');
    final schedules = [for (var i = 0; i < 32; i++) _schedule(id: 'spread-$i')];
    final results = await _expectSpread(
      (i) => generator.generate(
        schedules: schedules,
        rangeStart: from.add(days: i),
        rangeEnd: from.add(days: i).add(months: 3),
      ),
    );
    expect(calls, 1);
    for (final i in [0, 27]) {
      expect(
        _values(results[i]),
        _values(
          generateTaskOccurrenceBatch((
            schedules: schedules,
            rangeStart: from.add(days: i),
            rangeEnd: from.add(days: i).add(months: 3),
          )),
        ),
      );
    }
    results.first.clear();
    expect(results.last, isNotEmpty);
  });

  test('全部命中缓存的日期也分批裁剪返回，不形成同步完成长链', () async {
    var calls = 0;
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        calls++;
        return generateTaskOccurrenceBatch(input);
      },
    );
    addTearDown(generator.close);
    final schedules = [_schedule()];
    await generator.generate(
      schedules: schedules,
      rangeStart: day,
      rangeEnd: day.add(months: 3),
    );
    final results = await _expectSpread(
      (_) => generator.generate(
        schedules: schedules,
        rangeStart: day,
        rangeEnd: day.add(months: 3),
      ),
    );
    expect(calls, 1);
    expect(results.every((rows) => rows.isNotEmpty), isTrue);
  });

  test('空结果的完成通知也受共享预算限制，不漏回调或阻塞后续请求', () async {
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async => generateTaskOccurrenceBatch(input),
    );
    addTearDown(generator.close);
    final results = await _expectSpread(
      (_) => generator.generate(
        schedules: [],
        rangeStart: day,
        rangeEnd: day,
      ),
    );
    expect(results.every((rows) => rows.isEmpty), isTrue);
    final rows = await generator.generate(
      schedules: [_schedule()],
      rangeStart: day,
      rangeEnd: day.add(months: 3),
    );
    expect(rows, isNotEmpty);
  });

  test('关闭时等待缓存分发及完成回调追加的计算，之后仍可重新启动', () async {
    final generator = TaskOccurrenceGenerator();
    addTearDown(generator.close);
    final schedules = [_schedule()];
    await generator.generate(
      schedules: schedules,
      rangeStart: day,
      rangeEnd: day.add(months: 3),
    );
    var followupDone = false;
    Future<void>? followup;
    final requests = [
      for (var i = 0; i < 20; i++)
        generator
            .generate(
              schedules: schedules,
              rangeStart: day,
              rangeEnd: day.add(months: 3),
            )
            .then((rows) {
              if (i == 0) {
                followup = generator
                    .generate(
                      schedules: [_schedule(id: 'new')],
                      rangeStart: day,
                      rangeEnd: day.add(months: 3),
                    )
                    .then((rows) {
                      expect(rows, isNotEmpty);
                      followupDone = true;
                    });
              }
              return rows;
            }),
    ];
    await generator.close().timeout(const Duration(seconds: 10));
    expect(followupDone, isTrue);
    await followup;
    await Future.wait(requests);
    expect(
      await generator.generate(
        schedules: schedules,
        rangeStart: day,
        rangeEnd: day.add(months: 3),
      ),
      isNotEmpty,
    );
  });

  test('真实 worker 并发处理相同任务的不同规则版本，关闭时排空并允许重启', () async {
    final generator = TaskOccurrenceGenerator();
    addTearDown(generator.close);
    final inputs = [
      for (final offset in [0, 1, 2, 0, 1])
        (
          schedules: [
            _schedule(
              start: day.add(hours: 9 + offset),
              rule: RecurrenceRule(
                frequency: RecurrenceFrequency.monthly,
                daysOfMonth: [15 + offset],
              ),
            ),
          ],
          rangeStart: day.add(days: offset),
          rangeEnd: day.add(days: offset).add(months: 3),
        ),
    ];
    final requests = [
      for (final input in inputs)
        generator.generate(
          schedules: input.schedules,
          rangeStart: input.rangeStart,
          rangeEnd: input.rangeEnd,
        ),
    ];
    final close = generator.close();
    final results = await Future.wait(requests);
    await close;
    for (var i = 0; i < inputs.length; i++) {
      expect(
        _values(results[i]),
        _values(generateTaskOccurrenceBatch(inputs[i])),
      );
    }
    final input = inputs.first;
    final restarted = await generator.generate(
      schedules: input.schedules,
      rangeStart: input.rangeStart,
      rangeEnd: input.rangeEnd,
    );
    expect(_values(restarted), _values(generateTaskOccurrenceBatch(input)));
  });

  test('每日同窗口共享进行中结果，平移窗口继续按原起点独立计算', () async {
    var calls = 0;
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        calls++;
        return generateTaskOccurrenceBatch(input);
      },
    );
    addTearDown(generator.close);
    final schedules = [
      for (var i = 0; i < 16; i++)
        _schedule(
          id: 'daily-$i',
          rule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        ),
    ];
    final inputs = [
      for (final offset in [0, 0, 1, 1])
        (
          schedules: schedules,
          rangeStart: day.add(days: offset),
          rangeEnd: day.add(days: offset).add(months: 3),
        ),
    ];
    final results = await Future.wait([
      for (final input in inputs)
        generator.generate(
          schedules: input.schedules,
          rangeStart: input.rangeStart,
          rangeEnd: input.rangeEnd,
        ),
    ]);
    for (var i = 0; i < inputs.length; i++) {
      expect(
        _values(results[i]),
        _values(generateTaskOccurrenceBatch(inputs[i])),
      );
    }
    expect(calls, 2);
  });

  test('未指定星期的周规则不共享不同起点的计算', () async {
    var calls = 0;
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        calls++;
        return generateTaskOccurrenceBatch(input);
      },
    );
    addTearDown(generator.close);
    final schedules = [
      _schedule(
        rule: RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
          recurrenceEnd: RecurrenceEnd.fromOccurrenceCount(30),
        ),
      ),
    ];
    final inputs = [
      for (final offset in [0, 1, 0, 2, 1])
        (
          schedules: schedules,
          rangeStart: day.add(days: offset),
          rangeEnd: day.add(days: offset).add(months: 3),
        ),
    ];
    final results = await Future.wait([
      for (final input in inputs)
        generator.generate(
          schedules: input.schedules,
          rangeStart: input.rangeStart,
          rangeEnd: input.rangeEnd,
        ),
    ]);
    for (var i = 0; i < inputs.length; i++) {
      expect(
        _values(results[i]),
        _values(generateTaskOccurrenceBatch(inputs[i])),
      );
    }
    expect(calls, 3);
  });

  test('入队时深拷贝所有规则列表，后续修改不改变旧结果或污染缓存键', () async {
    final weekdays = [RecurrenceDayOfWeek.day(Weekday.monday)];
    final months = [1];
    final monthDays = [15];
    final weeks = [1];
    final yearDays = [101];
    final rule = RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      daysOfWeek: weekdays,
      daysOfMonth: monthDays,
      weeksOfMonth: weeks,
      monthsOfYear: months,
      daysOfYear: yearDays,
    );
    final seen = <RecurrenceRule>[];
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        seen.add(input.schedules.single.rule!);
        return generateTaskOccurrenceBatch(input);
      },
    );
    addTearDown(generator.close);
    final schedules = [_schedule(rule: rule)];
    final input = (
      schedules: schedules,
      rangeStart: day,
      rangeEnd: day.add(months: 3),
    );
    final expected = generateTaskOccurrenceBatch(input);
    final first = generator.generate(
      schedules: schedules,
      rangeStart: input.rangeStart,
      rangeEnd: input.rangeEnd,
    );
    schedules.clear();
    weekdays.add(RecurrenceDayOfWeek.day(Weekday.friday));
    months.add(6);
    monthDays.add(20);
    weeks.add(-1);
    yearDays.add(1231);
    final second = generator.generate(
      schedules: [_schedule(rule: rule)],
      rangeStart: input.rangeStart,
      rangeEnd: input.rangeEnd,
    );
    expect(_values(await first), _values(expected));
    expect(
      _values(await second),
      _values(
        generateTaskOccurrenceBatch((
          schedules: [_schedule(rule: rule)],
          rangeStart: input.rangeStart,
          rangeEnd: input.rangeEnd,
        )),
      ),
    );
    expect(seen, hasLength(2));
    final snapshot = seen.first;
    expect(snapshot.daysOfWeek, hasLength(1));
    expect(snapshot.daysOfMonth, [15]);
    expect(snapshot.weeksOfMonth, [1]);
    // 旧字段也必须维持深度隔离，不能在快照中丢失。
    // ignore: deprecated_member_use
    expect(snapshot.monthsOfYear, [1]);
    expect(snapshot.daysOfYear, [101]);
    expect(() => snapshot.daysOfMonth!.add(31), throwsUnsupportedError);
    await generator.generate(
      schedules: [_schedule(rule: snapshot)],
      rangeStart: input.rangeStart,
      rangeEnd: input.rangeEnd,
    );
    expect(seen, hasLength(2));
  });

  test('同一 ID 的不同规则和起止截止时间分别计算，混合缓存仍保持输入顺序', () async {
    final batches = <TaskOccurrenceBatch>[];
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        batches.add(input);
        return generateTaskOccurrenceBatch(input);
      },
    );
    addTearDown(generator.close);
    final schedules = [
      _schedule(
        rule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [15],
        ),
      ),
      _schedule(
        rule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [20],
        ),
        start: day.add(hours: 11),
        end: day.add(hours: 12),
        due: day.add(hours: 13),
      ),
      _schedule(end: day.add(hours: 15)),
      _schedule(due: day.add(hours: 16)),
    ];
    final input = (
      schedules: schedules,
      rangeStart: day,
      rangeEnd: day.add(months: 3),
    );
    expect(
      _values(
        await generator.generate(
          schedules: schedules,
          rangeStart: input.rangeStart,
          rangeEnd: input.rangeEnd,
        ),
      ),
      _values(generateTaskOccurrenceBatch(input)),
    );
    expect(batches, hasLength(4));
    final mixed = [schedules.first, _schedule(id: 'uncached'), schedules.last];
    expect(
      _values(
        await generator.generate(
          schedules: mixed,
          rangeStart: input.rangeStart,
          rangeEnd: input.rangeEnd,
        ),
      ),
      _values(
        generateTaskOccurrenceBatch((
          schedules: mixed,
          rangeStart: input.rangeStart,
          rangeEnd: input.rangeEnd,
        )),
      ),
    );
  });

  test('共享批次失败通知所有调用方，后续批次与重试仍正常执行', () async {
    var calls = 0;
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        if (++calls == 1) throw StateError('模拟共享计算失败');
        return generateTaskOccurrenceBatch(input);
      },
    );
    addTearDown(generator.close);
    final schedules = [for (var i = 0; i < 40; i++) _schedule(id: '$i')];
    final results = await Future.wait([
      for (var i = 0; i < 5; i++)
        generator
            .generate(
              schedules: schedules,
              rangeStart: day.add(days: i),
              rangeEnd: day.add(days: i).add(months: 3),
            )
            .then<Object?>((_) => null, onError: (Object error) => error),
    ]);
    expect(results.every((r) => r is StateError), isTrue);
    final input = (
      schedules: schedules,
      rangeStart: day,
      rangeEnd: day.add(months: 3),
    );
    final retry = await generator.generate(
      schedules: schedules,
      rangeStart: input.rangeStart,
      rangeEnd: input.rangeEnd,
    );
    expect(_values(retry), _values(generateTaskOccurrenceBatch(input)));
  });

  test('缓存命中不等待正在执行的无关慢计算', () async {
    final entered = Completer<void>();
    final resume = Completer<void>();
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        if (input.schedules.single.taskId == 'slow') {
          entered.complete();
          await resume.future;
        }
        return generateTaskOccurrenceBatch(input);
      },
    );
    addTearDown(generator.close);
    final schedule = _schedule();
    await generator.generate(
      schedules: [schedule],
      rangeStart: day,
      rangeEnd: day.add(months: 3),
    );
    final slow = generator.generate(
      schedules: [_schedule(id: 'slow')],
      rangeStart: day,
      rangeEnd: day.add(months: 3),
    );
    await entered.future;
    try {
      final cached = await generator
          .generate(
            schedules: [schedule],
            rangeStart: day,
            rangeEnd: day.add(months: 3),
          )
          .timeout(const Duration(seconds: 2));
      expect(cached, isNotEmpty);
    } finally {
      resume.complete();
      await slow;
    }
  });

  for (final boundary in ['2026-03-09', '2026-11-02']) {
    test('并发跨夏令时窗口 $boundary 保留精确计算结果', () async {
      if (Platform.environment['TZ'] == 'America/New_York') {
        expect(DateTime(2026, 2).timeZoneOffset, const Duration(hours: -5));
        expect(DateTime(2026, 4).timeZoneOffset, const Duration(hours: -4));
      }
      final generator = TaskOccurrenceGenerator(
        computeBatch: (input) async => generateTaskOccurrenceBatch(input),
      );
      addTearDown(generator.close);
      final from = Jiffy.parse(boundary);
      final schedules = [
        _schedule(
          start: from.subtract(days: 20),
          rule: RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            interval: 2,
            daysOfWeek: [RecurrenceDayOfWeek.day(Weekday.monday)],
          ),
        ),
        _schedule(
          id: 'daily',
          start: from.subtract(days: 20),
          rule: const RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 2,
          ),
        ),
      ];
      final inputs = [
        for (final offset in [-1, 0, 1, 0, -1])
          (
            schedules: schedules,
            rangeStart: from.add(days: offset),
            rangeEnd: from.add(days: offset).add(months: 3),
          ),
      ];
      final results = await Future.wait([
        for (final input in inputs)
          generator.generate(
            schedules: schedules,
            rangeStart: input.rangeStart,
            rangeEnd: input.rangeEnd,
          ),
      ]);
      for (var i = 0; i < inputs.length; i++) {
        expect(
          _values(results[i]),
          _values(generateTaskOccurrenceBatch(inputs[i])),
        );
      }
    });
  }
}
