import 'dart:io';
import 'dart:isolate';

import 'package:database_planbook_api/task/task_occurrence_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

void main() {
  final day = Jiffy.parse('2026-10-17');
  TaskOccurrenceSchedule schedule({
    String id = 'series',
    RecurrenceRule rule = const RecurrenceRule(
      frequency: RecurrenceFrequency.daily,
    ),
    Jiffy? startAt,
  }) => (
    taskId: id,
    startAt: startAt ?? day,
    endAt: null,
    dueAt: null,
    rule: rule,
  );

  test('真实 worker 可连续处理不同窗口，释放后可重新启动', () async {
    final generator = TaskOccurrenceGenerator();
    addTearDown(generator.close);
    for (var i = 1; i <= 2; i++) {
      final rows = await generator.generate(
        schedules: [schedule()],
        rangeStart: day,
        rangeEnd: day.add(days: i),
      );
      expect(rows, hasLength(i + 1));
    }
    await generator.close();
    final rows = await generator.generate(
      schedules: [schedule()],
      rangeStart: day,
      rangeEnd: day.add(days: 3),
    );
    expect(rows, hasLength(4));
  });

  test('worker 计算错误会返回失败，下一请求仍能正常完成', () async {
    final generator = TaskOccurrenceGenerator();
    addTearDown(generator.close);
    await expectLater(
      generator.generate(
        schedules: [
          schedule(
            rule: const RecurrenceRule(
              frequency: RecurrenceFrequency.daily,
              interval: 0,
            ),
          ),
        ],
        rangeStart: day,
        rangeEnd: day,
      ),
      throwsA(isA<RemoteError>()),
    );
    expect(
      await generator.generate(
        schedules: [schedule()],
        rangeStart: day,
        rangeEnd: day,
      ),
      hasLength(1),
    );
  });

  test('每日子窗口复用纯计算，规则和时间变更仍会重新计算', () async {
    var calls = 0;
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        calls++;
        return generateTaskOccurrenceBatch(input);
      },
    );
    addTearDown(generator.close);
    await generator.generate(
      schedules: [schedule()],
      rangeStart: day,
      rangeEnd: day.add(days: 4),
    );
    final slice = await generator.generate(
      schedules: [schedule()],
      rangeStart: day.add(days: 1),
      rangeEnd: day.add(days: 3),
    );
    expect(slice.map((o) => o.occurrenceAt.value), [
      day.add(days: 1),
      day.add(days: 2),
      day.add(days: 3),
    ]);
    expect(calls, 1);
    await generator.generate(
      schedules: [schedule(startAt: day.add(hours: 16))],
      rangeStart: day,
      rangeEnd: day.add(days: 4),
    );
    await generator.generate(
      schedules: [
        schedule(
          rule: const RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 2,
          ),
        ),
      ],
      rangeStart: day,
      rangeEnd: day.add(days: 4),
    );
    expect(calls, 3);
  });

  test('周规则保留原计算器的窗口语义，不把不同窗口当作同一结果', () async {
    var calls = 0;
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        calls++;
        return generateTaskOccurrenceBatch(input);
      },
    );
    addTearDown(generator.close);
    final schedules = [
      schedule(
        rule: const RecurrenceRule(frequency: RecurrenceFrequency.weekly),
      ),
    ];
    await generator.generate(
      schedules: schedules,
      rangeStart: day,
      rangeEnd: day.add(days: 21),
    );
    final input = (
      schedules: schedules,
      rangeStart: day.add(days: 1),
      rangeEnd: day.add(days: 15),
    );
    final actual = await generator.generate(
      schedules: schedules,
      rangeStart: input.rangeStart,
      rangeEnd: input.rangeEnd,
    );
    final expected = generateTaskOccurrenceBatch(input);
    expect(
      actual.map((o) => o.occurrenceAt.value),
      expected.map((o) => o.occurrenceAt.value),
    );
    expect(calls, 2);
  });

  for (final boundary in ['2026-03-09', '2026-11-02']) {
    test('夏令时边界 $boundary 的缓存结果必须与原窗口一致', () async {
      if (Platform.environment['TZ'] == 'America/New_York') {
        expect(DateTime(2026, 2).timeZoneOffset, const Duration(hours: -5));
        expect(DateTime(2026, 4).timeZoneOffset, const Duration(hours: -4));
      }
      final generator = TaskOccurrenceGenerator(
        computeBatch: (input) async => generateTaskOccurrenceBatch(input),
      );
      addTearDown(generator.close);
      final from = Jiffy.parse(boundary);
      final start = boundary.contains('03-09')
          ? Jiffy.parse('2026-02-23')
          : Jiffy.parse('2026-10-19');
      final schedules = [
        schedule(
          startAt: start,
          rule: RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            interval: 2,
            daysOfWeek: [RecurrenceDayOfWeek.day(Weekday.monday)],
          ),
        ),
      ];
      for (var i = 0; i < 3; i++) {
        final input = (
          schedules: schedules,
          rangeStart: from.add(days: i),
          rangeEnd: from.add(days: i).add(months: 3),
        );
        final rows = await generator.generate(
          schedules: schedules,
          rangeStart: input.rangeStart,
          rangeEnd: input.rangeEnd,
        );
        expect(
          rows.map((r) => (r.occurrenceAt.value, r.startAt.value)),
          generateTaskOccurrenceBatch(
            input,
          ).map((r) => (r.occurrenceAt.value, r.startAt.value)),
        );
      }
    });
  }

  for (final boundary in ['2026-03-09', '2026-11-02']) {
    test('每日规则在夏令时边界 $boundary 不截取跨时差的旧缓存', () async {
      final generator = TaskOccurrenceGenerator(
        computeBatch: (input) async => generateTaskOccurrenceBatch(input),
      );
      addTearDown(generator.close);
      final from = Jiffy.parse(boundary);
      final start = boundary.contains('03-09')
          ? Jiffy.parse('2026-02-23')
          : Jiffy.parse('2026-10-19');
      final schedules = [
        schedule(
          startAt: start,
          rule: const RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 2,
          ),
        ),
      ];
      final end = from.add(months: 3).endOf(Unit.month).startOf(Unit.day);
      await generator.generate(
        schedules: schedules,
        rangeStart: from.startOf(Unit.month),
        rangeEnd: end,
      );
      final rows = await generator.generate(
        schedules: schedules,
        rangeStart: from,
        rangeEnd: end,
      );
      final expected = generateTaskOccurrenceBatch((
        schedules: schedules,
        rangeStart: from,
        rangeEnd: end,
      ));
      expect(
        rows.map((r) => (r.occurrenceAt.value, r.startAt.value)),
        expected.map((r) => (r.occurrenceAt.value, r.startAt.value)),
      );
    });
  }

  final calendarRules = <String, RecurrenceRule>{
    '指定星期的隔周规则': RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      interval: 2,
      daysOfWeek: [
        RecurrenceDayOfWeek.day(Weekday.monday),
        RecurrenceDayOfWeek.day(Weekday.thursday),
      ],
    ),
    '隔月指定日期及次数限制': RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      interval: 2,
      daysOfMonth: const [1, 15, 31],
      recurrenceEnd: RecurrenceEnd.fromOccurrenceCount(5),
    ),
    '每月最后一个周五': RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      weeksOfMonth: const [-1],
      daysOfWeek: [RecurrenceDayOfWeek.dayWithWeekNumber(Weekday.friday, -1)],
    ),
    '每月默认逐日规则': const RecurrenceRule(frequency: RecurrenceFrequency.monthly),
    '每年指定日期': const RecurrenceRule(
      frequency: RecurrenceFrequency.yearly,
      daysOfYear: [101, 229, 1019, 1231],
    ),
    '每年默认逐日规则': const RecurrenceRule(frequency: RecurrenceFrequency.yearly),
    '明确结束日期': RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      recurrenceEnd: RecurrenceEnd.fromEndAt(day.add(days: 12)),
    ),
  };
  for (final entry in calendarRules.entries) {
    test('${entry.key}切天复用纯计算，返回仍严格匹配原窗口', () async {
      // 本组断言固定时差下的缓存次数；跨夏令时的精确回退另有对照测试。
      final day = Jiffy.parse('2026-06-13');
      var calls = 0;
      final generator = TaskOccurrenceGenerator(
        computeBatch: (input) async {
          calls++;
          return generateTaskOccurrenceBatch(input);
        },
      );
      addTearDown(generator.close);
      final inputSchedule = schedule(
        rule: entry.value,
        startAt: day.subtract(months: 2),
      );
      for (final offset in [0, 1, 3, -1, 10]) {
        final from = day.add(days: offset);
        final to = from.add(months: 3);
        final input = (
          schedules: [inputSchedule],
          rangeStart: from,
          rangeEnd: to,
        );
        final actual = await generator.generate(
          schedules: input.schedules,
          rangeStart: from,
          rangeEnd: to,
        );
        final expected = generateTaskOccurrenceBatch(input);
        List<Object?> values(List<TaskOccurrencesCompanion> rows) => [
          for (final row in rows)
            (
              row.taskId.value,
              row.occurrenceAt.value,
              row.startAt.value,
              row.endAt.value,
              row.dueAt.value,
            ),
        ];
        expect(values(actual), values(expected));
        expect(
          generator.expectedDates(
            schedule: inputSchedule,
            rangeStart: from,
            rangeEnd: to,
          ),
          expected.map(
            (r) => r.occurrenceAt.value.dateTime.microsecondsSinceEpoch,
          ),
        );
      }
      expect(calls, 1);
      // 跨月后建立新缓存窗口，不把未计算区间标成已覆盖。
      final from = day.add(months: 1);
      await generator.generate(
        schedules: [inputSchedule],
        rangeStart: from,
        rangeEnd: from.add(months: 3),
      );
      expect(calls, 2);
    });
  }

  for (final boundary in ['2024-02-27', '2025-12-30', '2026-01-30']) {
    test('闰日/月末/跨年边界 $boundary 与未缓存计算器等价', () async {
      final generator = TaskOccurrenceGenerator(
        computeBatch: (input) async => generateTaskOccurrenceBatch(input),
      );
      addTearDown(generator.close);
      final base = Jiffy.parse(boundary);
      final rules = [
        RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
          daysOfWeek: [
            RecurrenceDayOfWeek.day(Weekday.monday),
            RecurrenceDayOfWeek.day(Weekday.thursday),
          ],
          recurrenceEnd: RecurrenceEnd.fromOccurrenceCount(3),
        ),
        const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [29, 31],
        ),
        const RecurrenceRule(
          frequency: RecurrenceFrequency.yearly,
          daysOfYear: [101, 229, 1231],
        ),
        RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: const [1, 29, 31],
          recurrenceEnd: RecurrenceEnd.fromEndAt(base.add(days: 2)),
        ),
      ];
      for (var i = 0; i < rules.length; i++) {
        final inputSchedule = schedule(
          id: 'boundary-$i',
          rule: rules[i],
          startAt: base.subtract(days: 9),
        );
        for (final offset in [-2, 0, 1, 2, 5]) {
          final from = base.add(days: offset);
          final input = (
            schedules: [inputSchedule],
            rangeStart: from,
            rangeEnd: from.add(months: 3),
          );
          final actual = await generator.generate(
            schedules: input.schedules,
            rangeStart: input.rangeStart,
            rangeEnd: input.rangeEnd,
          );
          final expected = generateTaskOccurrenceBatch(input);
          expect(
            actual.map(
              (r) => (r.taskId.value, r.occurrenceAt.value, r.startAt.value),
            ),
            expected.map(
              (r) => (r.taskId.value, r.occurrenceAt.value, r.startAt.value),
            ),
          );
        }
      }
    });
  }

  test('混合规则分组计算保持返回顺序，规则或时间变化不复用旧缓存', () async {
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async => generateTaskOccurrenceBatch(input),
    );
    addTearDown(generator.close);
    final schedules = [
      schedule(
        id: 'month',
        rule: const RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [20],
        ),
      ),
      schedule(id: 'day'),
      schedule(
        id: 'year',
        rule: const RecurrenceRule(
          frequency: RecurrenceFrequency.yearly,
          daysOfYear: [1021],
        ),
      ),
    ];
    for (final list in [
      schedules,
      [
        schedule(
          id: 'month',
          rule: const RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            daysOfMonth: [21],
          ),
          startAt: day.add(hours: 2),
        ),
      ],
    ]) {
      final input = (
        schedules: list,
        rangeStart: day,
        rangeEnd: day.add(months: 3),
      );
      final rows = await generator.generate(
        schedules: list,
        rangeStart: input.rangeStart,
        rangeEnd: input.rangeEnd,
      );
      expect(
        rows.map(
          (r) => (r.taskId.value, r.occurrenceAt.value, r.startAt.value),
        ),
        generateTaskOccurrenceBatch(
          input,
        ).map((r) => (r.taskId.value, r.occurrenceAt.value, r.startAt.value)),
      );
    }
  });

  test('空结果的日期摘要也有容量上限，外部无法修改缓存摘要', () async {
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async => [],
    );
    addTearDown(generator.close);
    final schedules = [for (var i = 0; i < 1025; i++) schedule(id: '$i')];
    await generator.generate(
      schedules: schedules,
      rangeStart: day,
      rangeEnd: day,
    );
    expect(
      generator.expectedDates(
        schedule: schedules.first,
        rangeStart: day,
        rangeEnd: day,
      ),
      isNull,
    );
    final dates = generator.expectedDates(
      schedule: schedules.last,
      rangeStart: day,
      rangeEnd: day,
    )!;
    expect(dates, isEmpty);
    expect(() => dates.add(1), throwsUnsupportedError);
  });
}
