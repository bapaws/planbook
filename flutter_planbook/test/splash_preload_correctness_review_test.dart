import 'dart:async';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_repository/task/alarm_notification_service.dart';

class _ReviewApi extends DatabaseTaskTodayApi {
  _ReviewApi({
    required super.db,
    required super.tagApi,
    required super.outboxApi,
  });
  int builds = 0;
  Future<void> Function()? beforePreparation;

  @override
  Future<List<TaskEntity>> assembleTaskEntities(
    List<TypedResult> rows, {
    bool yieldBetweenBatches = false,
    Map<String, List<TagEntity>>? currentTags,
    TaskPreparationBudget? preparationBudget,
  }) async {
    builds++;
    if (preparationBudget != null) await beforePreparation?.call();
    return super.assembleTaskEntities(
      rows,
      yieldBetweenBatches: yieldBetweenBatches,
      currentTags: currentTags,
      preparationBudget: preparationBudget,
    );
  }
}

void main() {
  final day = Jiffy.parse('2026-10-19');
  late AppDatabase db;
  late _ReviewApi api;

  _ReviewApi createApi() {
    final outbox = OutboxApi(db: db);
    return _ReviewApi(
      db: db,
      outboxApi: outbox,
      tagApi: DatabaseTagApi(db: db, outboxApi: outbox),
    );
  }

  List<(String, String, int, String)> plans(Task task) => buildAlarmPlans((
    tasks: [task.toJson()],
    now: day.add(hours: 7).dateTime.millisecondsSinceEpoch,
    zone: 'Asia/Shanghai',
  )).map((p) => (p.key, p.title, p.at, p.payload)).toList();

  Future<void> insertSeries(RecurrenceRule rule) => db
      .into(db.tasks)
      .insert(
        TasksCompanion.insert(
          id: const Value('series'),
          title: '重复任务',
          userId: const Value('a'),
          startAt: Value(day.add(hours: 9)),
          endAt: Value(day.add(hours: 10)),
          recurrenceRule: Value(rule),
          alarms: Value([
            EventAlarm.relative(15),
            EventAlarm.relative(15),
            EventAlarm.absolute(day.add(hours: 8)),
            EventAlarm.scheduled(dayOffset: 0, hour: 8, minute: 30),
          ]),
        ),
      )
      .then((_) {});

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    api = createApi();
  });
  tearDown(() => db.close());

  final rules = [
    RecurrenceRule(
      frequency: RecurrenceFrequency.daily,
      interval: 2,
      recurrenceEnd: RecurrenceEnd.fromOccurrenceCount(8),
    ),
    RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      interval: 2,
      recurrenceEnd: RecurrenceEnd.fromEndAt(day.add(months: 2)),
      daysOfWeek: [RecurrenceDayOfWeek.day(Weekday.monday)],
    ),
    RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      interval: 2,
      recurrenceEnd: RecurrenceEnd.fromOccurrenceCount(8),
      daysOfMonth: const [19],
    ),
    RecurrenceRule(
      frequency: RecurrenceFrequency.yearly,
      interval: 2,
      recurrenceEnd: RecurrenceEnd.fromEndAt(day.add(years: 8)),
      daysOfYear: const [1019],
    ),
  ];

  for (final rule in rules) {
    test('缓存冻结完整保留 ${rule.frequency.name} 的间隔、结束条件和四条提醒业务键', () async {
      await insertSeries(rule);
      final baselineApi = createApi();
      await baselineApi.preGenerateTaskOccurrences(fromDate: day);
      final baseline =
          (await baselineApi.getTaskEntities(date: day, userId: 'a').first)
              .single;
      final expectedPlans = plans(baseline.task);
      expect(expectedPlans, isNotEmpty);
      expect(await api.prepareHomeTaskEntities(date: day, userId: 'a'), 1);
      final builds = api.builds;
      final cached =
          (await api.getTaskEntities(date: day, userId: 'a').first).single;
      expect(api.builds, builds);
      expect(cached.toJson(), baseline.toJson());
      expect(cached.recurrenceRule!.toJson(), rule.toJson());
      expect(cached.alarms, hasLength(4));
      expect(plans(cached.task), expectedPlans);
      // 工作副本仍可修改，原缓存和数据库数据不受影响。
      final editedAlarms = [...cached.alarms]..removeAt(0);
      expect(editedAlarms, hasLength(3));
      final source = (await db.select(db.tasks).get()).single;
      expect(source.toJson(), cached.task.toJson());
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    });
  }

  test('缓存冻结保留非重复任务的空规则和空提醒', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('plain'),
            title: '单次任务',
            userId: const Value('a'),
            startAt: Value(day.add(hours: 9)),
          ),
        );
    expect(await api.prepareHomeTaskEntities(date: day, userId: 'a'), 1);
    final cached =
        (await api.getTaskEntities(date: day, userId: 'a').first).single;
    expect(cached.recurrenceRule, isNull);
    expect(cached.alarms, isEmpty);
    expect(plans(cached.task), isEmpty);
    expect(
      cached.task.toJson(),
      (await db.select(db.tasks).get()).single.toJson(),
    );
  });

  test('实例生成后取消预组装，不回滚有效实例、不复活隐藏记录、不改变提醒数据', () async {
    await insertSeries(
      const RecurrenceRule(frequency: RecurrenceFrequency.daily),
    );
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('plain'),
            title: '单次任务',
            userId: const Value('a'),
            startAt: Value(day.add(hours: 9)),
          ),
        );
    await api.preGenerateTaskOccurrences(fromDate: day);
    final tomorrow = day.add(days: 1);
    await (db.update(db.taskOccurrences)..where(
          (o) =>
              o.taskId.equals('series') & o.occurrenceAt.equals(day.dateTime),
        ))
        .write(TaskOccurrencesCompanion(deletedAt: Value(day)));
    await db
        .into(db.taskActivities)
        .insert(
          TaskActivity(
            id: 'done-tomorrow',
            taskId: 'series',
            occurrenceAt: tomorrow,
            completedAt: tomorrow,
            createdAt: day,
          ),
        );
    final tasks = [
      for (final row in await db.select(db.tasks).get()) row.toJson(),
    ];
    final occurrences = [
      for (final row in await db.select(db.taskOccurrences).get()) row.toJson(),
    ];
    final activities = [
      for (final row in await db.select(db.taskActivities).get()) row.toJson(),
    ];
    final entered = Completer<void>();
    final release = Completer<void>();
    api.beforePreparation = () {
      entered.complete();
      return release.future;
    };
    final pending = api.prepareHomeTaskEntities(date: day, userId: 'a');
    await entered.future;
    expect(
      (await api.getTaskEntities(date: day, userId: 'a').first).single.id,
      'plain',
    );
    release.complete();
    expect(await pending, 0);
    expect([
      for (final row in await db.select(db.tasks).get()) row.toJson(),
    ], tasks);
    expect([
      for (final row in await db.select(db.taskOccurrences).get()) row.toJson(),
    ], occurrences);
    expect([
      for (final row in await db.select(db.taskActivities).get()) row.toJson(),
    ], activities);
    final next =
        (await api.getTaskEntities(date: tomorrow, userId: 'a').first).single;
    expect(next.id, 'series');
    expect(next.isCompleted, isTrue);
    expect(next.alarms, hasLength(4));
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('重复任务标签组超限不会丢失提醒或标签，也不影响其他分组缓存', () async {
    await insertSeries(
      const RecurrenceRule(frequency: RecurrenceFrequency.daily),
    );
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('plain'),
            title: '单次任务',
            userId: const Value('a'),
            startAt: Value(day.add(hours: 9)),
          ),
        );
    await db.batch((b) {
      for (var i = 0; i < 300; i++) {
        b
          ..insert(
            db.tags,
            TagsCompanion.insert(
              id: Value('tag-$i'),
              name: '标签$i',
              userId: const Value('a'),
              order: Value(i),
            ),
          )
          ..insert(
            db.taskTags,
            TaskTagsCompanion.insert(
              id: Value('link-$i'),
              taskId: 'series',
              tagId: 'tag-$i',
              userId: const Value('a'),
            ),
          );
      }
    });
    final source = (await db.select(db.tasks).get()).singleWhere(
      (t) => t.id == 'series',
    );
    final expectedPlans = plans(source);
    expect(await api.prepareHomeTaskEntities(date: day, userId: 'a'), 1);
    final builds = api.builds;
    expect(
      (await api.getTaskEntities(date: day, userId: 'a').first).single.id,
      'plain',
    );
    expect(api.builds, builds);
    final series =
        (await api
                .getTaskEntities(date: day, userId: 'a', tagId: 'tag-0')
                .first)
            .single;
    expect(api.builds, builds + 1);
    expect(series.id, 'series');
    expect(series.tags, hasLength(300));
    expect(series.occurrence, isNotNull);
    expect(series.task.toJson(), source.toJson());
    expect(plans(series.task), expectedPlans);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });
}
