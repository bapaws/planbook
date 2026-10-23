import 'dart:async';

import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:database_planbook_api/task/task_occurrence_generator.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class _Computer {
  final entered = Completer<void>();
  final resume = Completer<void>();
  int calls = 0;
  bool failFirst = false;

  Future<List<TaskOccurrencesCompanion>> call(TaskOccurrenceBatch input) async {
    if (++calls == 1) {
      entered.complete();
      await resume.future;
      if (failFirst) throw StateError('模拟共享计算失败');
    }
    return generateTaskOccurrenceBatch(input);
  }
}

class _ObservedGenerator extends TaskOccurrenceGenerator {
  _ObservedGenerator({required super.computeBatch});

  int requests = 0;
  final _waiters = <int, Completer<void>>{};

  Future<void> waitForRequests(int count) {
    if (requests >= count) return Future.value();
    return (_waiters[count] ??= Completer<void>()).future.timeout(
      const Duration(seconds: 5),
    );
  }

  @override
  Future<List<TaskOccurrencesCompanion>> generate({
    required List<TaskOccurrenceSchedule> schedules,
    required Jiffy rangeStart,
    required Jiffy rangeEnd,
  }) {
    final result = super.generate(
      schedules: schedules,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    requests++;
    for (final count in _waiters.keys.toList()) {
      if (requests >= count) _waiters.remove(count)!.complete();
    }
    return result;
  }
}

void main() {
  final date = Jiffy.parse('2026-06-13');
  late AppDatabase db;
  late _Computer computer;
  late _ObservedGenerator generator;
  late DatabaseTaskApi first;
  late DatabaseTaskApi second;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    computer = _Computer();
    generator = _ObservedGenerator(computeBatch: computer.call);
    final outbox = OutboxApi(db: db);
    final tags = DatabaseTagApi(db: db, outboxApi: outbox);
    DatabaseTaskApi api() => DatabaseTaskApi(
      db: db,
      tagApi: tags,
      outboxApi: outbox,
      occurrenceGenerator: generator,
    );
    first = api();
    second = api();
  });

  tearDown(() async {
    if (!computer.resume.isCompleted) computer.resume.complete();
    await generator.close();
    await db.close();
  });

  Future<Task> insert(String id, {Jiffy? start}) async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: Value(id),
            title: id,
            startAt: Value(start ?? date.add(hours: 9)),
            endAt: Value((start ?? date.add(hours: 9)).add(hours: 1)),
            dueAt: Value((start ?? date.add(hours: 9)).add(hours: 2)),
            recurrenceRule: const Value(
              RecurrenceRule(
                frequency: RecurrenceFrequency.monthly,
              ),
            ),
          ),
        );
    return (await first.getTaskById(id))!;
  }

  test('两个 API 快速切换六天共享大批计算，各日仍独立补齐精确窗口且实例唯一', () async {
    final tasks = [for (var i = 0; i < 40; i++) await insert('series-$i')];
    final dates = [for (var i = 0; i < 6; i++) date.add(days: i)];
    final requests = [
      for (var i = 0; i < dates.length; i++)
        (i.isEven ? first : second).preGenerateTaskOccurrences(
          fromDate: dates[i],
        ),
    ];
    await computer.entered.future;
    await pumpEventQueue(times: 30);
    expect(computer.calls, 1);
    // 计算没有持有写事务，首页仍可查询和修改普通任务。
    expect(await db.select(db.tasks).get(), hasLength(40));
    computer.resume.complete();
    await Future.wait(requests).timeout(const Duration(seconds: 10));
    final expected = {
      for (final from in dates)
        for (final row in generateTaskOccurrenceBatch((
          schedules: tasks.map(occurrenceScheduleOf).toList(),
          rangeStart: from,
          rangeEnd: from.add(months: 3),
        )))
          (
            row.taskId.value,
            row.occurrenceAt.value,
            row.startAt.value,
            row.endAt.value,
            row.dueAt.value,
          ),
    };
    final rows = await db.select(db.taskOccurrences).get();
    expect(
      rows.map((o) => (o.taskId, o.occurrenceAt, o.startAt, o.endAt, o.dueAt)),
      unorderedEquals(expected),
    );
    expect(
      rows.map((o) => (o.taskId, o.occurrenceAt)).toSet(),
      hasLength(rows.length),
    );
    expect(computer.calls, 2);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('并发请求保留各日候选条件，未来才开始的任务不会漏生成', () async {
    await insert('existing');
    final futureDate = date.add(days: 2);
    final future = await insert('future', start: futureDate.add(hours: 11));
    final earlier = first.preGenerateTaskOccurrences(fromDate: date);
    await computer.entered.future;
    final later = second.preGenerateTaskOccurrences(fromDate: futureDate);
    await pumpEventQueue();
    computer.resume.complete();
    await Future.wait([earlier, later]);
    final rows =
        await (db.select(db.taskOccurrences)..where(
              (o) => o.taskId.equals('future'),
            ))
            .get();
    final expected = generateTaskOccurrenceBatch((
      schedules: [occurrenceScheduleOf(future)],
      rangeStart: futureDate,
      rangeEnd: futureDate.add(months: 3),
    ));
    expect(
      rows.map((o) => (o.occurrenceAt, o.startAt)),
      unorderedEquals(
        expected.map((o) => (o.occurrenceAt.value, o.startAt.value)),
      ),
    );
  });

  test('共享旧计算期间修改规则和删除任务，提交时重验且不复活隐藏实例', () async {
    await insert('changed');
    await insert('deleted');
    final dates = [date, date.add(days: 1), date.add(days: 2)];
    final requests = [
      for (final from in dates)
        first.preGenerateTaskOccurrences(fromDate: from),
    ];
    await computer.entered.future;
    await pumpEventQueue();
    expect(computer.calls, 1);
    final rule = RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      daysOfMonth: const [15, 20],
      recurrenceEnd: RecurrenceEnd.fromOccurrenceCount(8),
    );
    await (db.update(db.tasks)..where((t) => t.id.equals('changed'))).write(
      TasksCompanion(
        startAt: Value(date.add(hours: 16)),
        recurrenceRule: Value(rule),
      ),
    );
    await (db.update(db.tasks)..where((t) => t.id.equals('deleted'))).write(
      TasksCompanion(deletedAt: Value(date)),
    );
    final hiddenDate = Jiffy.parse('2026-06-20');
    await db
        .into(db.taskOccurrences)
        .insert(
          TaskOccurrencesCompanion.insert(
            id: const Value('hidden'),
            taskId: const Value('changed'),
            occurrenceAt: hiddenDate,
            deletedAt: Value(date),
          ),
        );
    computer.resume.complete();
    await Future.wait(requests).timeout(const Duration(seconds: 10));
    final latest = (await first.getTaskById('changed'))!;
    final expected = {
      for (final from in dates)
        for (final row in generateTaskOccurrenceBatch((
          schedules: [occurrenceScheduleOf(latest)],
          rangeStart: from,
          rangeEnd: from.add(months: 3),
        )))
          if (row.occurrenceAt.value != hiddenDate)
            (
              row.occurrenceAt.value,
              row.startAt.value,
              row.endAt.value,
              row.dueAt.value,
            ),
    };
    final rows = await db.select(db.taskOccurrences).get();
    expect(rows.singleWhere((o) => o.id == 'hidden').deletedAt, date);
    expect(rows.every((o) => o.taskId == 'changed'), isTrue);
    expect(
      rows
          .where((o) => o.deletedAt == null)
          .map((o) => (o.occurrenceAt, o.startAt, o.endAt, o.dueAt)),
      unorderedEquals(expected),
    );
    expect(
      rows.map((o) => (o.taskId, o.occurrenceAt)).toSet(),
      hasLength(rows.length),
    );
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('共享计算失败后各日期可重试，命中摘要仍修复缺行并保留隐藏行', () async {
    await insert('retry');
    computer.failFirst = true;
    final dates = [date, date.add(days: 1), date.add(days: 2)];
    final requests = [
      for (final from in dates)
        first
            .preGenerateTaskOccurrences(fromDate: from)
            .then<Object?>((_) => null, onError: (Object error) => error),
    ];
    await computer.entered.future;
    await pumpEventQueue();
    computer.resume.complete();
    expect((await Future.wait(requests)).every((r) => r is StateError), isTrue);
    expect(await db.select(db.taskOccurrences).get(), isEmpty);
    await Future.wait([
      for (final from in dates)
        first.preGenerateTaskOccurrences(fromDate: from),
    ]);
    final before = await db.select(db.taskOccurrences).get();
    final missing = before[3];
    final hidden = before[5];
    await (db.delete(
      db.taskOccurrences,
    )..where((o) => o.id.equals(missing.id))).go();
    await (db.update(
      db.taskOccurrences,
    )..where((o) => o.id.equals(hidden.id))).write(
      TaskOccurrencesCompanion(deletedAt: Value(date)),
    );
    final repairFrom = date.add(days: 3);
    await second.preGenerateTaskOccurrences(fromDate: repairFrom);
    final after = await db.select(db.taskOccurrences).get();
    expect(after.any((o) => o.occurrenceAt == missing.occurrenceAt), isTrue);
    expect(after.singleWhere((o) => o.id == hidden.id).deletedAt, date);
    expect(
      after.map((o) => (o.taskId, o.occurrenceAt)).toSet(),
      hasLength(after.length),
    );
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('六个日期的 A→B→A 规则交错不漏生成，迟到 B 计算不覆盖隐藏、分离和完成记录', () async {
    final original = await insert('aba');
    final dates = [for (var i = 0; i < 6; i++) date.add(days: i)];
    final requests = [
      for (final from in dates.take(3))
        first.preGenerateTaskOccurrences(fromDate: from),
    ];
    await computer.entered.future;
    await generator.waitForRequests(3);
    await first.insertOrUpdate(
      task: original.copyWith(
        startAt: Value(date.add(hours: 16)),
        recurrenceRule: const Value(
          RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            daysOfMonth: [15, 20],
          ),
        ),
      ),
    );
    requests.addAll([
      for (final from in dates.skip(3))
        second.preGenerateTaskOccurrences(fromDate: from),
    ]);
    await generator.waitForRequests(6);
    await first.insertOrUpdate(task: original);
    final hiddenAt = Jiffy.parse('2026-06-20');
    final detachedAt = hiddenAt.add(days: 1);
    await db.batch((batch) {
      batch
        ..insertAll(db.taskOccurrences, [
          for (final day in [hiddenAt, detachedAt])
            TaskOccurrencesCompanion.insert(
              id: Value('hidden-${day.date}'),
              taskId: const Value('aba'),
              occurrenceAt: day,
              deletedAt: Value(date),
            ),
        ])
        ..insert(
          db.tasks,
          TasksCompanion.insert(
            id: const Value('detached'),
            title: '分离实例',
            startAt: Value(detachedAt.add(hours: 16)),
            detachedFromTaskId: const Value('aba'),
            detachedRecurrenceAt: Value(detachedAt),
          ),
        )
        ..insert(
          db.taskActivities,
          TaskActivitiesCompanion.insert(
            id: const Value('completed'),
            taskId: const Value('aba'),
            occurrenceAt: Value(hiddenAt.add(days: 2)),
            completedAt: Value(date),
          ),
        );
    });
    computer.resume.complete();
    await Future.wait(requests).timeout(const Duration(seconds: 10));
    final expected = {
      for (final from in dates)
        for (final row in generateTaskOccurrenceBatch((
          schedules: [occurrenceScheduleOf(original)],
          rangeStart: from,
          rangeEnd: from.add(months: 3),
        )))
          if (![hiddenAt, detachedAt].contains(row.occurrenceAt.value))
            (
              row.occurrenceAt.value,
              row.startAt.value,
              row.endAt.value,
              row.dueAt.value,
            ),
    };
    final rows = await db.select(db.taskOccurrences).get();
    expect(
      rows
          .where((o) => o.deletedAt == null)
          .map((o) => (o.occurrenceAt, o.startAt, o.endAt, o.dueAt)),
      unorderedEquals(expected),
    );
    for (final at in [hiddenAt, detachedAt]) {
      final hidden = rows.singleWhere((o) => o.occurrenceAt == at);
      expect(hidden.id, 'hidden-${at.date}');
      expect(hidden.deletedAt, date);
    }
    expect(rows.every((o) => o.taskId == 'aba'), isTrue);
    expect(
      (await first.getTaskById('detached'))!.detachedRecurrenceAt,
      detachedAt,
    );
    expect((await db.select(db.taskActivities).get()).single.id, 'completed');
    expect(computer.calls, 2);
  });

  test('共享结果返回前任务被物理删除、取消规则或变为子任务、分离实例时不补写', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('parent'),
            title: '父任务',
          ),
        );
    for (final id in ['removed', 'cancelled', 'child', 'detached']) {
      await insert(id);
    }
    final requests = [
      for (var i = 0; i < 3; i++)
        first.preGenerateTaskOccurrences(fromDate: date.add(days: i)),
    ];
    await computer.entered.future;
    await generator.waitForRequests(3);
    await (db.delete(db.tasks)..where((t) => t.id.equals('removed'))).go();
    await (db.update(db.tasks)..where((t) => t.id.equals('cancelled'))).write(
      const TasksCompanion(recurrenceRule: Value(null)),
    );
    await (db.update(db.tasks)..where((t) => t.id.equals('child'))).write(
      const TasksCompanion(parentId: Value('parent')),
    );
    await (db.update(db.tasks)..where((t) => t.id.equals('detached'))).write(
      TasksCompanion(
        detachedFromTaskId: const Value('parent'),
        detachedRecurrenceAt: Value(date),
      ),
    );
    computer.resume.complete();
    await Future.wait(requests).timeout(const Duration(seconds: 10));
    expect(await db.select(db.taskOccurrences).get(), isEmpty);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('两个库共享纯计算仍分别核验实例，隐藏状态不串库且缺行照常补齐', () async {
    final original = await insert('same-id');
    final task = original.copyWith(
      recurrenceRule: const Value(
        RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [20],
        ),
      ),
    );
    await (db.update(db.tasks)..where((t) => t.id.equals(task.id))).write(
      task.toCompanion(false),
    );
    // 两个独立内存库刻意共存，只共享纯计算器，不共享 SQLite 连接。
    final warn = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(
      () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = warn,
    );
    final otherDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(otherDb.close);
    final otherOutbox = OutboxApi(db: otherDb);
    final other = DatabaseTaskApi(
      db: otherDb,
      tagApi: DatabaseTagApi(db: otherDb, outboxApi: otherOutbox),
      outboxApi: otherOutbox,
      occurrenceGenerator: generator,
    );
    await otherDb.into(otherDb.tasks).insert(task.toCompanion(false));
    final hiddenAt = Jiffy.parse('2026-06-20');
    await db
        .into(db.taskOccurrences)
        .insert(
          TaskOccurrencesCompanion.insert(
            id: const Value('hidden-in-first'),
            taskId: Value(task.id),
            occurrenceAt: hiddenAt,
            deletedAt: Value(date),
          ),
        );
    final firstRequest = first.preGenerateTaskOccurrences(fromDate: date);
    await computer.entered.future;
    final otherRequest = other.preGenerateTaskOccurrences(fromDate: date);
    await generator.waitForRequests(2);
    computer.resume.complete();
    await Future.wait([firstRequest, otherRequest]);
    expect(computer.calls, 1);
    final inFirst = await db.select(db.taskOccurrences).get();
    final inOther = await otherDb.select(otherDb.taskOccurrences).get();
    expect(
      inFirst.singleWhere((o) => o.occurrenceAt == hiddenAt).deletedAt,
      date,
    );
    expect(
      inOther.singleWhere((o) => o.occurrenceAt == hiddenAt).deletedAt,
      isNull,
    );
    final missing = inOther.firstWhere((o) => o.occurrenceAt != hiddenAt);
    await (otherDb.delete(otherDb.taskOccurrences)..where(
          (o) => o.id.equals(missing.id),
        ))
        .go();
    await other.preGenerateTaskOccurrences(fromDate: date.add(days: 1));
    expect(
      (await otherDb.select(otherDb.taskOccurrences).get()).any(
        (o) => o.occurrenceAt == missing.occurrenceAt,
      ),
      isTrue,
    );
    expect(
      (await db.select(db.taskOccurrences).get())
          .singleWhere((o) => o.occurrenceAt == hiddenAt)
          .deletedAt,
      date,
    );
  });

  test('事务回滚后不把共享计算当作数据库覆盖，外部准备无死锁并补齐自己范围', () async {
    await insert('rollback');
    final inside = db
        .transaction(() async {
          await first.preGenerateTaskOccurrences(fromDate: date);
          throw StateError('模拟业务事务回滚');
        })
        .then<Object?>((_) => null, onError: (Object error) => error);
    await computer.entered.future;
    final from = date.add(days: 1);
    final outside = second.preGenerateTaskOccurrences(fromDate: from);
    computer.resume.complete();
    final failure = await inside.timeout(const Duration(seconds: 10));
    expect(failure, isA<StateError>());
    await outside.timeout(const Duration(seconds: 10));
    final task = (await first.getTaskById('rollback'))!;
    final expected = generateTaskOccurrenceBatch((
      schedules: [occurrenceScheduleOf(task)],
      rangeStart: from,
      rangeEnd: from.add(months: 3),
    ));
    final rows = await db.select(db.taskOccurrences).get();
    expect(
      rows.map((o) => (o.occurrenceAt, o.startAt)),
      unorderedEquals(
        expected.map((o) => (o.occurrenceAt.value, o.startAt.value)),
      ),
    );
    expect(rows.any((o) => o.occurrenceAt == date), isFalse);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });
}
