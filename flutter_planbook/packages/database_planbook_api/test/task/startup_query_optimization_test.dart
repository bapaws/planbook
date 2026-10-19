import 'dart:async';

import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:database_planbook_api/task/database_task_today_api.dart';
import 'package:database_planbook_api/task/recurrence_rule_calculator.dart';
import 'package:database_planbook_api/task/task_occurrence_generator.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class _Queries extends QueryInterceptor {
  final selects = <String>[];
  bool failNextSelect = false;
  int occurrenceBatches = 0;
  int? failOccurrenceBatch;
  Future<void> Function()? beforeNextSelect;
  Future<void> Function()? beforeNextOccurrenceBatch;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    selects.add(statement);
    if (failNextSelect) {
      failNextSelect = false;
      throw StateError('模拟查询失败');
    }
    final before = beforeNextSelect;
    beforeNextSelect = null;
    await before?.call();
    return executor.runSelect(statement, args);
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) async {
    if (statements.statements.any((sql) => sql.contains('task_occurrences'))) {
      occurrenceBatches++;
      if (occurrenceBatches == failOccurrenceBatch) {
        throw StateError('模拟第二批写入失败');
      }
      final before = beforeNextOccurrenceBatch;
      beforeNextOccurrenceBatch = null;
      await before?.call();
    }
    return executor.runBatched(statements);
  }
}

class _ControlledComputer {
  final entered = Completer<void>();
  final resume = Completer<void>();
  bool pauseNext = true;
  int calls = 0;

  Future<List<TaskOccurrencesCompanion>> call(TaskOccurrenceBatch input) async {
    calls++;
    if (pauseNext) {
      pauseNext = false;
      entered.complete();
      await resume.future;
    }
    return generateTaskOccurrenceBatch(input);
  }
}

void main() {
  late AppDatabase db;
  late _Queries queries;
  late DatabaseTagApi tags;
  late DatabaseTaskApi tasks;
  late OutboxApi outbox;
  late TaskOccurrenceGenerator generator;
  final date = Jiffy.parse('2026-10-17');

  setUp(() async {
    queries = _Queries();
    db = AppDatabase.forTesting(
      NativeDatabase.memory().interceptWith(queries),
    );
    outbox = OutboxApi(db: db);
    tags = DatabaseTagApi(db: db, outboxApi: outbox);
    generator = TaskOccurrenceGenerator();
    tasks = DatabaseTaskApi(
      db: db,
      tagApi: tags,
      outboxApi: outbox,
      occurrenceGenerator: generator,
    );
    await db.customSelect('SELECT 1').get();
    queries.selects.clear();
  });

  tearDown(() async {
    await generator.close();
    await db.close();
  });

  DatabaseTaskApi controlledApi(_ControlledComputer computer) {
    final generator = TaskOccurrenceGenerator(computeBatch: computer.call);
    addTearDown(() async {
      if (!computer.resume.isCompleted) computer.resume.complete();
      await generator.close();
    });
    return DatabaseTaskApi(
      db: db,
      tagApi: tags,
      outboxApi: outbox,
      occurrenceGenerator: generator,
    );
  }

  test('连续切天复用明确星期的日期摘要，不扩大写库范围，缺行与隐藏标记仍正确', () async {
    var calls = 0;
    final computer = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        calls++;
        return generateTaskOccurrenceBatch(input);
      },
    );
    addTearDown(computer.close);
    final api = DatabaseTaskApi(
      db: db,
      tagApi: tags,
      outboxApi: outbox,
      occurrenceGenerator: computer,
    );
    final rule = RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      daysOfWeek: [RecurrenceDayOfWeek.day(Weekday.thursday)],
    );
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('weekly'),
            title: '每周四',
            startAt: Value(date),
            recurrenceRule: Value(rule),
          ),
        );
    await api.preGenerateTaskOccurrences(fromDate: date);
    expect(calls, 1);
    final before = await db.select(db.taskOccurrences).get();
    expect(before, isNotEmpty);
    expect(
      before.every(
        (o) =>
            !o.occurrenceAt.isBefore(date, unit: Unit.day) &&
            !o.occurrenceAt.isAfter(date.add(months: 3), unit: Unit.day),
      ),
      isTrue,
    );
    await api.preGenerateTaskOccurrences(fromDate: date.add(days: 1));
    expect(calls, 1);
    expect(
      (await db.select(db.taskOccurrences).get()).map((o) => o.id),
      before.map((o) => o.id),
    );
    final missing = before.first;
    final hidden = before.last;
    await (db.delete(
      db.taskOccurrences,
    )..where((o) => o.id.equals(missing.id))).go();
    await (db.update(db.taskOccurrences)..where((o) => o.id.equals(hidden.id)))
        .write(TaskOccurrencesCompanion(deletedAt: Value(date)));
    await api.preGenerateTaskOccurrences(fromDate: date.add(days: 2));
    final after = await db.select(db.taskOccurrences).get();
    expect(after.any((o) => o.occurrenceAt == missing.occurrenceAt), isTrue);
    expect(after.singleWhere((o) => o.id == hidden.id).deletedAt, date);
    expect(calls, 1);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('独立旧实例修复不回写有 Outbox 的本地任务，清理取消规则并保留隐藏标记', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('legacy'),
            title: '旧规则任务',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    await tasks.preGenerateTaskOccurrences(fromDate: date);
    await (db.update(db.taskOccurrences)..where(
          (o) => o.occurrenceAt.equals(date.dateTime),
        ))
        .write(TaskOccurrencesCompanion(deletedAt: Value(date)));
    await (db.update(db.tasks)..where((t) => t.id.equals('legacy'))).write(
      const TasksCompanion(title: Value('本地取消重复'), recurrenceRule: Value(null)),
    );
    await outbox.enqueue(
      tableName: 'tasks',
      recordId: 'legacy',
      operation: 'update',
      payload: '{}',
    );
    final before = (await db.select(db.tasks).get()).single.toJson();
    await tasks.repairLegacyOccurrences(userId: null, validateAccount: () {});
    expect((await db.select(db.tasks).get()).single.toJson(), before);
    final occurrences = await db.select(db.taskOccurrences).get();
    expect(occurrences, hasLength(1));
    expect(occurrences.single.deletedAt, date);
    expect(await outbox.hasPending('legacy'), isTrue);
    final count = queries.occurrenceBatches;
    await tasks.repairLegacyOccurrences(userId: null, validateAccount: () {});
    expect(queries.occurrenceBatches, count);
  });

  test('独立修复计算期间可查首页，规则发生变化时重算，不能覆盖新任务', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('legacy'),
            title: '本地任务',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    await tasks.preGenerateTaskOccurrences(fromDate: date);
    final computer = _ControlledComputer();
    final api = controlledApi(computer);
    final repairing = api.repairLegacyOccurrences(
      userId: null,
      validateAccount: () {},
    );
    await computer.entered.future;
    expect(
      await db.select(db.tasks).get().timeout(const Duration(seconds: 2)),
      hasLength(1),
    );
    await (db.update(db.tasks)..where((t) => t.id.equals('legacy'))).write(
      const TasksCompanion(title: Value('计算期间取消'), recurrenceRule: Value(null)),
    );
    await outbox.enqueue(
      tableName: 'tasks',
      recordId: 'legacy',
      operation: 'update',
      payload: '{}',
    );
    computer.resume.complete();
    await repairing;
    expect((await db.select(db.tasks).get()).single.title, '计算期间取消');
    expect(await db.select(db.taskOccurrences).get(), isEmpty);
    expect(await outbox.hasPending('legacy'), isTrue);
  });

  test('同步计算不占事务，首页可查询；期间本地 Outbox 修改不能被覆盖', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('remote'),
            title: '原任务',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    await tasks.preGenerateTaskOccurrences(fromDate: date);
    final original = (await db.select(db.tasks).get()).single;
    final computer = _ControlledComputer();
    final api = controlledApi(computer);
    var relatedWrites = 0;
    final pending = api.applySyncedTask(
      task: original.copyWith(title: '远端旧修改'),
      refreshOccurrences: true,
      validateAccount: () {},
      writeRelated: () async {
        relatedWrites++;
      },
    );
    await computer.entered.future;
    expect(
      (await db.select(db.tasks).get().timeout(const Duration(seconds: 2)))
          .single
          .title,
      '原任务',
    );
    await (db.update(db.tasks)..where((t) => t.id.equals('remote'))).write(
      const TasksCompanion(title: Value('本地新修改')),
    );
    await outbox.enqueue(
      tableName: 'tasks',
      recordId: 'remote',
      operation: 'update',
      payload: '{}',
    );
    computer.resume.complete();
    expect(await pending, isFalse);
    expect((await db.select(db.tasks).get()).single.title, '本地新修改');
    expect(relatedWrites, 0);
  });

  test('同步提交前隐藏标记变化时重读实例，不复活单次删除', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('remote'),
            title: '重复任务',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    await tasks.preGenerateTaskOccurrences(fromDate: date);
    final original = (await db.select(db.tasks).get()).single;
    final computer = _ControlledComputer();
    final api = controlledApi(computer);
    final pending = api.applySyncedTask(
      task: original.copyWith(title: '远端修改'),
      refreshOccurrences: true,
      validateAccount: () {},
      writeRelated: () async {},
    );
    await computer.entered.future;
    final hiddenDay = date.add(days: 1);
    await (db.update(db.taskOccurrences)..where(
          (o) =>
              o.taskId.equals('remote') &
              o.occurrenceAt.equals(hiddenDay.dateTime),
        ))
        .write(TaskOccurrencesCompanion(deletedAt: Value(date)));
    computer.resume.complete();
    expect(await pending, isTrue);
    final hidden =
        await (db.select(db.taskOccurrences)..where(
              (o) =>
                  o.taskId.equals('remote') &
                  o.occurrenceAt.equals(hiddenDay.dateTime),
            ))
            .getSingle();
    expect(hidden.deletedAt, isNotNull);
    expect((await db.select(db.tasks).get()).single.title, '远端修改');
  });

  test('强制同步仍核验缓存，但内容正确时不删除重写实例', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('remote'),
            title: '任务',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    await tasks.preGenerateTaskOccurrences(fromDate: date);
    final original = (await db.select(db.tasks).get()).single;
    final old = await db.select(db.taskOccurrences).get();
    final batches = queries.occurrenceBatches;
    expect(
      await tasks.applySyncedTask(
        task: original,
        refreshOccurrences: true,
        validateAccount: () {},
        writeRelated: () async {},
      ),
      isTrue,
    );
    expect(queries.occurrenceBatches, batches);
    expect(await db.select(db.taskOccurrences).get(), old);
  });

  test('同步关联失败时该任务与实例回滚，原缓存仍可用', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('remote'),
            title: '原任务',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    await tasks.preGenerateTaskOccurrences(fromDate: date);
    final original = (await db.select(db.tasks).get()).single;
    final old = await db.select(db.taskOccurrences).get();
    await expectLater(
      tasks.applySyncedTask(
        task: original.copyWith(title: '远端修改'),
        refreshOccurrences: true,
        validateAccount: () {},
        writeRelated: () async {
          throw StateError('关联提交失败');
        },
      ),
      throwsStateError,
    );
    expect((await db.select(db.tasks).get()).single.title, '原任务');
    expect(await db.select(db.taskOccurrences).get(), old);
  });

  test('批量标签保持关联用户、软删除、父链和创建顺序', () async {
    await db.batch((batch) {
      batch
        ..insertAll(db.tags, [
          TagsCompanion.insert(id: const Value('parent'), name: '父标签'),
          TagsCompanion.insert(
            id: const Value('child'),
            name: '子标签',
            parentId: const Value('parent'),
          ),
          TagsCompanion.insert(id: const Value('other'), name: '另一标签'),
          TagsCompanion.insert(
            id: const Value('deleted'),
            name: '已删除',
            deletedAt: Value(date),
          ),
        ])
        ..insertAll(db.taskTags, [
          TaskTagsCompanion.insert(
            taskId: 'a',
            tagId: 'child',
            userId: const Value('u'),
            createdAt: Value(date.add(hours: 2)),
          ),
          TaskTagsCompanion.insert(
            taskId: 'a',
            tagId: 'other',
            userId: const Value('u'),
            createdAt: Value(date),
          ),
          TaskTagsCompanion.insert(
            taskId: 'a',
            tagId: 'parent',
            userId: const Value('u'),
            linkedTagId: const Value('child'),
          ),
          TaskTagsCompanion.insert(
            taskId: 'a',
            tagId: 'other',
            userId: const Value('wrong-user'),
          ),
          TaskTagsCompanion.insert(
            taskId: 'a',
            tagId: 'other',
            userId: const Value('u'),
            deletedAt: Value(date),
          ),
          TaskTagsCompanion.insert(
            taskId: 'a',
            tagId: 'deleted',
            userId: const Value('u'),
          ),
          TaskTagsCompanion.insert(taskId: 'guest', tagId: 'child'),
        ]);
    });

    final result = await tags.getTagEntitiesByTaskIds({
      'a': 'u',
      'guest': null,
      'empty': 'u',
    });
    expect(result['a']!.map((tag) => tag.id), ['other', 'child']);
    expect(result['a']!.last.parent!.id, 'parent');
    expect(result['guest']!.single.id, 'child');
    expect(result['empty'], isNull);
  });

  test('超过单批参数数的任务仍只按批次查询标签', () async {
    await db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(
            id: const Value('shared'),
            name: '共享标签',
          ),
        );
    await db.batch((batch) {
      batch.insertAll(db.taskTags, [
        for (var i = 0; i < 805; i++)
          TaskTagsCompanion.insert(taskId: 't$i', tagId: 'shared'),
      ]);
    });
    queries.selects.clear();
    final result = await tags.getTagEntitiesByTaskIds({
      for (var i = 0; i < 805; i++) 't$i': null,
    });
    expect(result, hasLength(805));
    expect(queries.selects, hasLength(4));
  });

  test('不同 API 的并发生成共享请求并复查，完成后新任务仍可生成', () async {
    final otherApi = DatabaseTaskTodayApi(
      db: db,
      tagApi: tags,
      outboxApi: outbox,
    );
    final first = tasks.preGenerateTaskOccurrences(fromDate: date);
    final second = otherApi.preGenerateTaskOccurrences(fromDate: date);
    expect(identical(first, second), isTrue);
    await Future.wait([first, second]);
    expect(queries.selects, hasLength(2));

    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('new-series'),
            title: '新重复任务',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    await tasks.preGenerateTaskOccurrences(fromDate: date);
    expect(await db.select(db.taskOccurrences).get(), isNotEmpty);
  });

  test('生成失败后清除进行中请求，下一次可以重试', () async {
    queries.failNextSelect = true;
    await expectLater(
      tasks.preGenerateTaskOccurrences(fromDate: date),
      throwsStateError,
    );
    await tasks.preGenerateTaskOccurrences(fromDate: date);
    expect(queries.selects, hasLength(2));
  });

  test('准备中首页复用同一请求，完成后的查询直接使用已有实例', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            title: '每日任务',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    final entered = Completer<void>();
    final resume = Completer<void>();
    queries.beforeNextSelect = () {
      entered.complete();
      return resume.future;
    };
    final first = tasks.preGenerateTaskOccurrences(fromDate: date);
    await entered.future;
    final home = DatabaseTaskTodayApi(db: db, tagApi: tags, outboxApi: outbox);
    final fromHome = home.preGenerateTaskOccurrences(fromDate: date);
    expect(identical(first, fromHome), isTrue);
    resume.complete();
    await first;
    expect(queries.occurrenceBatches, 1);

    expect(await home.getTodayTaskCount(date: date).first, 1);
    // 等待首页原有预生成入口收尾；当天实例已有时无需再次计算、写入。
    await home.preGenerateTaskOccurrences(fromDate: date);
    expect(queries.occurrenceBatches, 1);
  });

  test('后台分批展开与原规则计算一致，保留起止与截止时间', () async {
    final rules = [
      RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 2,
        recurrenceEnd: RecurrenceEnd.fromOccurrenceCount(60),
      ),
      RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        daysOfWeek: [RecurrenceDayOfWeek.day(Weekday.monday)],
      ),
      RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        daysOfMonth: const [1, 17, 28],
        recurrenceEnd: RecurrenceEnd.fromEndAt(date.add(months: 2)),
      ),
      const RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        monthsOfYear: [10, 11],
      ),
    ];
    await db.batch((batch) {
      batch.insertAll(db.tasks, [
        for (var i = 0; i < 65; i++)
          TasksCompanion.insert(
            id: Value('series-$i'),
            title: '重复任务 $i',
            startAt: i.isEven
                ? Value(date.add(hours: 15))
                : const Value.absent(),
            endAt: i.isEven ? Value(date.add(hours: 17)) : const Value.absent(),
            dueAt: Value(date.add(hours: 20)),
            recurrenceRule: Value(rules[i % rules.length]),
          ),
      ]);
    });

    await tasks.preGenerateTaskOccurrences(fromDate: date);
    expect(queries.occurrenceBatches, 3);
    final occurrences = await db.select(db.taskOccurrences).get();
    for (var i = 0; i < 65; i++) {
      final start = date.add(hours: i.isEven ? 15 : 20);
      final expected = RecurrenceRuleCalculator.generateOccurrences(
        rule: rules[i % rules.length],
        startDate: start,
        rangeStart: date,
        rangeEnd: date.add(months: 3),
      );
      final actual = occurrences.where((o) => o.taskId == 'series-$i').toList()
        ..sort(
          (a, b) => a.occurrenceAt.dateTime.compareTo(b.occurrenceAt.dateTime),
        );
      expect(actual.map((o) => o.occurrenceAt), expected, reason: 'series-$i');
      for (final occurrence in actual) {
        final offset = occurrence.occurrenceAt
            .diff(date, unit: Unit.day)
            .toInt();
        expect(occurrence.startAt, i.isEven ? start.add(days: offset) : isNull);
        expect(
          occurrence.endAt,
          i.isEven ? date.add(days: offset, hours: 17) : isNull,
        );
        expect(occurrence.dueAt, date.add(days: offset, hours: 20));
      }
    }
  });

  test('分批失败保留已提交的有效实例，重试补齐缺失批次', () async {
    await db.batch((batch) {
      batch.insertAll(db.tasks, [
        for (var i = 0; i < 33; i++)
          TasksCompanion.insert(
            id: Value('rollback-$i'),
            title: '分批任务 $i',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
      ]);
    });
    queries.failOccurrenceBatch = 2;
    await expectLater(
      tasks.preGenerateTaskOccurrences(fromDate: date),
      throwsStateError,
    );
    final committed = await db.select(db.taskOccurrences).get();
    expect(committed.map((o) => o.taskId).toSet(), hasLength(32));
    queries.failOccurrenceBatch = null;
    await tasks.preGenerateTaskOccurrences(fromDate: date);
    final occurrences = await db.select(db.taskOccurrences).get();
    expect(occurrences.map((o) => o.taskId).toSet(), hasLength(33));
  });

  test('准备计算期间规则更新无需等待，旧结果丢弃并按新规则生成', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('changing-series'),
            title: '修改中的重复任务',
            startAt: Value(date.add(hours: 9)),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    final original = (await tasks.getTaskById('changing-series'))!;
    final computer = _ControlledComputer();
    final preparation = controlledApi(
      computer,
    ).preGenerateTaskOccurrences(fromDate: date);
    await computer.entered.future;
    final updated = tasks.insertOrUpdate(
      task: original.copyWith(
        startAt: Value(date.add(hours: 16)),
        recurrenceRule: Value(
          RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 2,
            recurrenceEnd: RecurrenceEnd.fromOccurrenceCount(3),
          ),
        ),
      ),
    );
    await updated;
    computer.resume.complete();
    await preparation;
    final occurrences = await db.select(db.taskOccurrences).get();
    expect(
      occurrences.map((o) => o.occurrenceAt.dateTime),
      unorderedEquals([
        date.dateTime,
        date.add(days: 2).dateTime,
        date.add(days: 4).dateTime,
      ]),
    );
    expect(occurrences.every((o) => o.startAt!.hour == 16), isTrue);
  });

  test('准备不复活单次删除或分离实例留下的隐藏标记', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('hidden-series'),
            title: '保留隐藏实例',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    final hiddenDate = date.add(days: 1);
    await db
        .into(db.taskOccurrences)
        .insert(
          TaskOccurrencesCompanion.insert(
            id: const Value('hidden-occurrence'),
            taskId: const Value('hidden-series'),
            occurrenceAt: hiddenDate,
            deletedAt: Value(date),
          ),
        );
    await tasks.preGenerateTaskOccurrences(fromDate: date);
    await tasks.preGenerateTaskOccurrences(fromDate: hiddenDate);
    final hidden =
        await (db.select(db.taskOccurrences)..where(
              (o) =>
                  o.taskId.equals('hidden-series') &
                  o.occurrenceAt.equals(hiddenDate.dateTime),
            ))
            .get();
    expect(hidden, hasLength(1));
    expect(hidden.single.id, 'hidden-occurrence');
    expect(hidden.single.deletedAt, date);
  });

  test('当天不执行的系列复用纯计算结果，不重复写入实例', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('weekly-series'),
            title: '明天执行的周任务',
            startAt: Value(date.subtract(days: 7)),
            recurrenceRule: Value(
              RecurrenceRule(
                frequency: RecurrenceFrequency.weekly,
                daysOfWeek: [
                  RecurrenceDayOfWeek.day(
                    Weekday.fromDateTimeWeekday(
                      date.add(days: 1).dateTime.weekday,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    await tasks.preGenerateTaskOccurrences(fromDate: date);
    final first = await db.select(db.taskOccurrences).get();
    expect(first, isNotEmpty);
    await tasks.preGenerateTaskOccurrences(fromDate: date);
    expect(queries.occurrenceBatches, 1);
    final second = await db.select(db.taskOccurrences).get();
    expect(second.map((o) => o.id), unorderedEquals(first.map((o) => o.id)));
  });

  test('准备计算期间普通首页查询立即可用，不等待实例生成', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            title: '计算不占连接',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    final computer = _ControlledComputer();
    final preparation = controlledApi(
      computer,
    ).preGenerateTaskOccurrences(fromDate: date);
    await computer.entered.future;
    final count = await tasks
        .getTotalCount(userId: null)
        .timeout(const Duration(seconds: 2));
    expect(count, 1);
    computer.resume.complete();
    await preparation;
  });

  for (final change in ['delete', 'child', 'detach', 'future', 'no-rule']) {
    test('计算期间任务状态变为 $change 时不会写入旧实例', () async {
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: const Value('invalidated'),
              title: '变化中的任务',
              startAt: Value(date),
              recurrenceRule: const Value(
                RecurrenceRule(frequency: RecurrenceFrequency.daily),
              ),
            ),
          );
      final computer = _ControlledComputer();
      final preparation = controlledApi(
        computer,
      ).preGenerateTaskOccurrences(fromDate: date);
      await computer.entered.future;
      await (db.update(
        db.tasks,
      )..where((t) => t.id.equals('invalidated'))).write(
        switch (change) {
          'delete' => TasksCompanion(deletedAt: Value(date)),
          'child' => const TasksCompanion(parentId: Value('parent')),
          'detach' => const TasksCompanion(detachedFromTaskId: Value('parent')),
          'future' => TasksCompanion(startAt: Value(date.add(days: 1))),
          _ => const TasksCompanion(recurrenceRule: Value(null)),
        },
      );
      computer.resume.complete();
      await preparation;
      expect(await db.select(db.taskOccurrences).get(), isEmpty);
    });
  }

  test('计算期间落库的新增系列也会在准备完成前补齐', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('initial'),
            title: '初始系列',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    final computer = _ControlledComputer();
    final preparation = controlledApi(
      computer,
    ).preGenerateTaskOccurrences(fromDate: date);
    await computer.entered.future;
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('arrived'),
            title: '同步新到达的系列',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    computer.resume.complete();
    await preparation;
    final rows = await db.select(db.taskOccurrences).get();
    expect(rows.map((o) => o.taskId).toSet(), {'initial', 'arrived'});
  });

  test('纯计算缓存命中后实例表被清空仍会补齐，删除标记也会保留', () async {
    final computer = _ControlledComputer()..pauseNext = false;
    final api = controlledApi(computer);
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('repair'),
            title: '修复缺失缓存',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    await api.preGenerateTaskOccurrences(fromDate: date);
    final expectedCount = (await db.select(db.taskOccurrences).get()).length;
    await db.delete(db.taskOccurrences).go();
    await db
        .into(db.taskOccurrences)
        .insert(
          TaskOccurrencesCompanion.insert(
            taskId: const Value('repair'),
            occurrenceAt: date,
            deletedAt: Value(date),
          ),
        );
    await api.preGenerateTaskOccurrences(fromDate: date);
    final rows = await db.select(db.taskOccurrences).get();
    expect(rows, hasLength(expectedCount));
    expect(rows.where((o) => o.occurrenceAt == date).single.deletedAt, date);
    expect(computer.calls, 1);
  });

  test('完整实例对象缓存淘汰后，日期摘要仍能避免重新计算和写入', () async {
    final computer = _ControlledComputer()..pauseNext = false;
    final api = controlledApi(computer);
    await db.batch(
      (batch) => batch.insertAll(db.tasks, [
        for (var i = 0; i < 65; i++)
          TasksCompanion.insert(
            title: '次日开始的间隔任务 $i',
            startAt: Value(date.subtract(days: 1)),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily, interval: 2),
            ),
          ),
      ]),
    );
    await api.preGenerateTaskOccurrences(fromDate: date);
    final computations = computer.calls;
    final writes = queries.occurrenceBatches;
    await api.preGenerateTaskOccurrences(fromDate: date);
    expect(computer.calls, computations);
    expect(queries.occurrenceBatches, writes);
  });

  test('计算期间新插入的单次隐藏标记在提交时仍受保护', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('hide-during-compute'),
            title: '计算期间隐藏',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    final computer = _ControlledComputer();
    final preparation = controlledApi(
      computer,
    ).preGenerateTaskOccurrences(fromDate: date);
    await computer.entered.future;
    await db
        .into(db.taskOccurrences)
        .insert(
          TaskOccurrencesCompanion.insert(
            taskId: const Value('hide-during-compute'),
            occurrenceAt: date,
            deletedAt: Value(date),
          ),
        );
    computer.resume.complete();
    await preparation;
    final rows =
        await (db.select(db.taskOccurrences)..where(
              (o) => o.occurrenceAt.equals(date.dateTime),
            ))
            .get();
    expect(rows, hasLength(1));
    expect(rows.single.deletedAt, date);
  });

  test('准备填充缓存后，即使规则没变强制刷新仍会重新展开并写入', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('force-series'),
            title: '强制刷新重复任务',
            startAt: Value(date),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    final task = (await tasks.getTaskById('force-series'))!;
    await tasks.insertOrUpdate(task: task, refreshOccurrences: true);
    expect(queries.occurrenceBatches, 0);

    await tasks.preGenerateTaskOccurrences(fromDate: date);
    expect(queries.occurrenceBatches, 1);
    final count = (await db.select(db.taskOccurrences).get()).length;

    await tasks.insertOrUpdate(task: task, refreshOccurrences: true);
    expect(queries.occurrenceBatches, 2);
    expect(await db.select(db.taskOccurrences).get(), hasLength(count));
  });

  test('强制刷新事务与准备共用计算队列不会互相等待，最终采用新时间', () async {
    final start = date.subtract(days: 3);
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('shared-worker'),
            title: '共用计算器',
            startAt: Value(start.add(hours: 9)),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    await db
        .into(db.taskOccurrences)
        .insert(
          TaskOccurrencesCompanion.insert(
            taskId: const Value('shared-worker'),
            occurrenceAt: date.subtract(days: 1),
            startAt: Value(date.subtract(days: 1).add(hours: 9)),
          ),
        );
    final original = (await tasks.getTaskById('shared-worker'))!;
    final computer = _ControlledComputer();
    final api = controlledApi(computer);
    final preparation = api.preGenerateTaskOccurrences(fromDate: date);
    await computer.entered.future;
    final refresh = api.insertOrUpdate(
      task: original.copyWith(
        startAt: Value(start.add(hours: 16)),
      ),
      refreshOccurrences: true,
    );
    await pumpEventQueue();
    computer.resume.complete();
    await Future.wait([
      preparation,
      refresh,
    ]).timeout(const Duration(seconds: 5));
    final rows = await db.select(db.taskOccurrences).get();
    expect(rows, isNotEmpty);
    expect(rows.every((o) => o.startAt!.hour == 16), isTrue);
  });

  test('事务内生成不等待排在该事务之后的外部生成', () async {
    final entered = Completer<void>();
    final continueTransaction = Completer<void>();
    final transaction = db.transaction(() async {
      entered.complete();
      await continueTransaction.future;
      await tasks.preGenerateTaskOccurrences(fromDate: date);
    });
    await entered.future;
    final outside = tasks.preGenerateTaskOccurrences(fromDate: date);
    continueTransaction.complete();
    await Future.wait([
      transaction,
      outside,
    ]).timeout(const Duration(seconds: 5));
  });
}
