import 'dart:async';

import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:database_planbook_api/task/database_task_delay_api.dart';
import 'package:database_planbook_api/task/database_task_today_api.dart';
import 'package:database_planbook_api/task/database_task_update_api.dart';
import 'package:database_planbook_api/task/task_occurrence_generator.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class _Queries extends QueryInterceptor {
  bool failInvalidation = false;
  final invalidations = <String>[];

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (statement.contains('task_occurrences')) {
      invalidations.add(statement);
      if (failInvalidation) throw StateError('模拟缓存失效失败');
    }
    return executor.runDelete(statement, args);
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
  final day = Jiffy.parse('2026-06-13');
  final hiddenAt = Jiffy.parse('2026-06-20');
  late AppDatabase db;
  late _Queries queries;
  late DatabaseTaskUpdateApi editor;
  late DatabaseTaskTodayApi home;
  late DatabaseTaskDelayApi delay;
  late _ObservedGenerator generator;
  late Completer<void> entered;
  late Completer<void> resume;
  late bool pause;
  late int calls;

  setUp(() {
    queries = _Queries();
    db = AppDatabase.forTesting(NativeDatabase.memory().interceptWith(queries));
    final outbox = OutboxApi(db: db);
    final tags = DatabaseTagApi(db: db, outboxApi: outbox);
    pause = false;
    calls = 0;
    entered = Completer<void>();
    resume = Completer<void>();
    generator = _ObservedGenerator(
      computeBatch: (input) async {
        calls++;
        if (pause && !entered.isCompleted) {
          entered.complete();
          await resume.future;
        }
        return generateTaskOccurrenceBatch(input);
      },
    );
    editor = DatabaseTaskUpdateApi(
      db: db,
      tagApi: tags,
      outboxApi: outbox,
      occurrenceGenerator: generator,
    );
    home = DatabaseTaskTodayApi(db: db, tagApi: tags, outboxApi: outbox);
    delay = DatabaseTaskDelayApi(db: db, tagApi: tags);
  });

  tearDown(() async {
    if (!resume.isCompleted) resume.complete();
    await generator.close();
    await TaskOccurrenceGenerator.shared.close();
    await db.close();
  });

  Future<Task> seed() async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('series'),
            title: '重复任务',
            startAt: Value(day.add(hours: 9)),
            endAt: Value(day.add(hours: 10)),
            dueAt: Value(day.add(hours: 11)),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.monthly),
            ),
          ),
        );
    final task = (await editor.getTaskById('series'))!;
    await editor.preGenerateTaskOccurrences(fromDate: day);
    await db.transaction(
      () => delay.ensureSoftDeleteOccurrence(
        taskId: task.id,
        occurrenceAt: hiddenAt,
        task: task,
      ),
    );
    return task;
  }

  Future<TaskOccurrence> hidden() =>
      (db.select(db.taskOccurrences)..where(
            (o) =>
                o.taskId.equals('series') &
                o.occurrenceAt.equals(hiddenAt.dateTime),
          ))
          .getSingle();

  Future<void> settle(Task task) => editor.preGenerateTaskOccurrences(
    fromDate: task.startAt ?? task.dueAt ?? day,
  );

  test('真实编辑保存保留隐藏行、标签和完成活动，首页标签筛选不会复活实例', () async {
    final original = await seed();
    final before = await hidden();
    final completedAt = Jiffy.parse('2026-07-20');
    await db.batch((batch) {
      batch
        ..insert(
          db.tags,
          TagsCompanion.insert(id: const Value('tag'), name: '标签'),
        )
        ..insert(
          db.taskTags,
          TaskTagsCompanion.insert(
            id: const Value('link'),
            taskId: 'series',
            tagId: 'tag',
          ),
        )
        ..insert(
          db.taskActivities,
          TaskActivitiesCompanion.insert(
            id: const Value('activity'),
            taskId: const Value('series'),
            occurrenceAt: Value(completedAt),
            completedAt: Value(day),
          ),
        );
    });
    final updated = original.copyWith(
      recurrenceRule: const Value(
        RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [20],
        ),
      ),
    );
    final result = editor.prepareUpdate(
      entity: TaskEntity(task: original),
      updatedTask: updated,
      tags: null,
    );
    await editor.saveUpdateResult(result);
    await settle(updated);
    expect((await hidden()).toJson(), before.toJson());
    expect(
      await home.getTaskEntities(date: hiddenAt, tagId: 'tag').first,
      isEmpty,
    );
    final visible = await home
        .getTaskEntities(date: completedAt, tagId: 'tag', isCompleted: true)
        .first;
    expect(visible.single.task.id, 'series');
    expect(visible.single.tags.single.tag.id, 'tag');
    expect((await db.select(db.taskActivities).get()).single.id, 'activity');
    expect((await db.select(db.taskTags).get()).single.id, 'link');
    expect(queries.invalidations.single, contains('"deleted_at" IS NULL'));
    await home.preGenerateTaskOccurrences(fromDate: hiddenAt);
    await home.preGenerateTaskOccurrences(fromDate: completedAt);
  });

  test('移出规则日期、取消重复和恢复规则仍原样保留隐藏行', () async {
    final original = await seed();
    final before = await hidden();
    for (final rule in <RecurrenceRule?>[
      const RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        daysOfMonth: [15],
      ),
      null,
      const RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        daysOfMonth: [20],
      ),
    ]) {
      final updated = original.copyWith(recurrenceRule: Value(rule));
      await editor.update(task: updated);
      await settle(updated);
      expect((await hidden()).toJson(), before.toJson());
      if (rule == null) {
        expect(
          (await db.select(db.taskOccurrences).get()).every(
            (o) => o.deletedAt != null,
          ),
          isTrue,
        );
      }
    }
    expect(await home.getTaskEntities(date: hiddenAt).first, isEmpty);
    await home.preGenerateTaskOccurrences(fromDate: hiddenAt);
  });

  for (final field in ['start', 'end', 'due']) {
    test('修改 $field 时间不丢隐藏标记，其余实例使用最新时间', () async {
      final original = await seed();
      final before = await hidden();
      final updated = original.copyWith(
        startAt: Value(
          field == 'start' ? day.add(hours: 12) : original.startAt,
        ),
        endAt: Value(field == 'end' ? day.add(hours: 16) : original.endAt),
        dueAt: Value(field == 'due' ? day.add(hours: 17) : original.dueAt),
      );
      await editor.update(task: updated);
      await settle(updated);
      expect((await hidden()).toJson(), before.toJson());
      final expected = generateTaskOccurrenceBatch((
        schedules: [occurrenceScheduleOf(updated)],
        rangeStart: day,
        rangeEnd: day.add(months: 3),
      )).where((o) => o.occurrenceAt.value != hiddenAt);
      final rows = (await db.select(db.taskOccurrences).get()).where(
        (o) => o.deletedAt == null,
      );
      expect(
        rows.map((o) => (o.occurrenceAt, o.startAt, o.endAt, o.dueAt)),
        unorderedEquals(
          expected.map(
            (o) => (
              o.occurrenceAt.value,
              o.startAt.value,
              o.endAt.value,
              o.dueAt.value,
            ),
          ),
        ),
      );
    });
  }

  test('只编辑正文不失效实例，也不新增规则计算', () async {
    final original = await seed();
    final before = await db.select(db.taskOccurrences).get();
    final count = calls;
    await editor.update(task: original.copyWith(title: '新标题'));
    expect(await db.select(db.taskOccurrences).get(), unorderedEquals(before));
    expect(queries.invalidations, isEmpty);
    expect(calls, count);
  });

  test('失效操作失败时任务、Outbox 和全部实例一起回滚', () async {
    final original = await seed();
    final before = await db.select(db.taskOccurrences).get();
    queries.failInvalidation = true;
    await expectLater(
      editor.update(
        task: original.copyWith(
          recurrenceRule: const Value(
            RecurrenceRule(
              frequency: RecurrenceFrequency.monthly,
              daysOfMonth: [20],
            ),
          ),
        ),
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      (await editor.getTaskById(original.id))!.toJson(),
      original.toJson(),
    );
    expect(await db.select(db.syncOutbox).get(), isEmpty);
    expect(await db.select(db.taskOccurrences).get(), unorderedEquals(before));
  });

  test('快速翻天期间连续真实编辑和单次删除交错，迟到计算只补最新规则', () async {
    final original = await seed();
    final oldHidden = await hidden();
    final from = Jiffy.parse('2027-06-13');
    pause = true;
    final count = generator.requests;
    final requests = [
      for (var i = 0; i < 3; i++)
        editor.preGenerateTaskOccurrences(fromDate: from.add(days: i)),
    ];
    await entered.future;
    await generator.waitForRequests(count + 3);
    final intermediate = original.copyWith(
      startAt: Value(day.add(hours: 13)),
      recurrenceRule: const Value(
        RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [17],
        ),
      ),
    );
    await editor.update(task: intermediate);
    final latest = original.copyWith(
      startAt: Value(day.add(hours: 16)),
      recurrenceRule: const Value(
        RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          daysOfMonth: [15, 20],
        ),
      ),
    );
    await editor.update(task: latest);
    final hiddenFuture = Jiffy.parse('2027-06-20');
    await db.transaction(
      () => delay.ensureSoftDeleteOccurrence(
        taskId: latest.id,
        occurrenceAt: hiddenFuture,
        task: latest,
      ),
    );
    final marker =
        await (db.select(db.taskOccurrences)..where(
              (o) => o.occurrenceAt.equals(hiddenFuture.dateTime),
            ))
            .getSingle();
    resume.complete();
    await Future.wait([
      ...requests,
      settle(latest),
    ]).timeout(const Duration(seconds: 10));
    final rows = await db.select(db.taskOccurrences).get();
    expect((await hidden()).toJson(), oldHidden.toJson());
    expect(
      rows.singleWhere((o) => o.id == marker.id).deletedAt,
      marker.deletedAt,
    );
    final expected = {
      for (final start in [day, for (var i = 0; i < 3; i++) from.add(days: i)])
        for (final row in generateTaskOccurrenceBatch((
          schedules: [occurrenceScheduleOf(latest)],
          rangeStart: start,
          rangeEnd: start.add(months: 3),
        )))
          if (![hiddenAt, hiddenFuture].contains(row.occurrenceAt.value))
            (
              row.occurrenceAt.value,
              row.startAt.value,
              row.endAt.value,
              row.dueAt.value,
            ),
    };
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
  });
}
