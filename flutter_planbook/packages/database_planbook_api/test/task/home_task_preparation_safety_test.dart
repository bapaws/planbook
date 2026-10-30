import 'dart:async';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class _Reads extends QueryInterceptor {
  final reads = <(String, int)>[];
  Future<void> Function(String)? afterRead;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final rows = await executor.runSelect(statement, args);
    reads.add((statement, rows.length));
    await afterRead?.call(statement);
    return rows;
  }

  List<(String, int)> from(String table) =>
      reads.where((r) => r.$1.contains('FROM "$table"')).toList();
}

class _Tags extends DatabaseTagApi {
  _Tags({required super.db, required super.outboxApi});
  int preparationReads = 0;

  @override
  Future<Map<String, List<TagEntity>>> getTagEntitiesByTaskIds(
    Map<String, String?> taskUserIds, {
    TaskPreparationBudget? preparationBudget,
  }) {
    if (preparationBudget != null) preparationReads++;
    return super.getTagEntitiesByTaskIds(
      taskUserIds,
      preparationBudget: preparationBudget,
    );
  }
}

class _Api extends DatabaseTaskTodayApi {
  _Api({required super.db, required super.tagApi, required super.outboxApi});
  int builds = 0;
  List<TaskEntity> source = [];
  Future<void> Function()? beforePreparation;
  Future<void> Function()? afterPreparation;

  @override
  Future<List<TaskEntity>> assembleTaskEntities(
    List<TypedResult> rows, {
    bool yieldBetweenBatches = false,
    Map<String, List<TagEntity>>? currentTags,
    TaskPreparationBudget? preparationBudget,
  }) async {
    builds++;
    if (preparationBudget != null) await beforePreparation?.call();
    final entities = await super.assembleTaskEntities(
      rows,
      yieldBetweenBatches: yieldBetweenBatches,
      currentTags: currentTags,
      preparationBudget: preparationBudget,
    );
    if (preparationBudget != null) {
      source = entities;
      await afterPreparation?.call();
    }
    return entities;
  }
}

void main() {
  final day = Jiffy.parse('2026-10-19');
  late AppDatabase db;
  late _Reads reads;
  late _Tags tags;
  late _Api api;

  setUp(() async {
    reads = _Reads();
    db = AppDatabase.forTesting(NativeDatabase.memory().interceptWith(reads));
    final outbox = OutboxApi(db: db);
    tags = _Tags(db: db, outboxApi: outbox);
    api = _Api(db: db, tagApi: tags, outboxApi: outbox);
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('task'),
            title: '首屏任务',
            userId: const Value('a'),
            startAt: Value(day.add(hours: 9)),
            endAt: Value(day.add(hours: 10)),
          ),
        );
  });
  tearDown(() => db.close());

  Future<int> prepare() => api.prepareHomeTaskEntities(date: day, userId: 'a');
  Future<List<TaskEntity>> home({String? tagId}) =>
      api.getTaskEntities(date: day, userId: 'a', tagId: tagId).first;
  TaskPreparationBudget budget({
    bool Function()? current,
    Duration Function()? elapsed,
  }) => TaskPreparationBudget(
    isCurrent: current ?? () => true,
    elapsed: elapsed ?? () => Duration.zero,
  );

  Future<void> addTags(int count, {int nameLength = 3}) => db.batch((b) {
    for (var i = 0; i < count; i++) {
      b
        ..insert(
          db.tags,
          TagsCompanion.insert(
            id: Value('tag-$i'),
            name: '$i-${'字' * nameLength}',
            userId: const Value('a'),
            order: Value(i),
          ),
        )
        ..insert(
          db.taskTags,
          TaskTagsCompanion.insert(
            id: Value('link-$i'),
            taskId: 'task',
            tagId: 'tag-$i',
            userId: const Value('a'),
          ),
        );
    }
  });

  Future<void> addRulesAndChild() async {
    final rule = RecurrenceRule(
      frequency: RecurrenceFrequency.daily,
      daysOfWeek: [RecurrenceDayOfWeek.day(Weekday.monday)],
      daysOfMonth: const [19],
      weeksOfMonth: const [3],
      monthsOfYear: const [10],
      daysOfYear: const [1019],
    );
    final alarms = [EventAlarm.relative(15)];
    await (db.update(db.tasks)..where((t) => t.id.equals('task'))).write(
      TasksCompanion(recurrenceRule: Value(rule), alarms: Value(alarms)),
    );
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('child'),
            title: '子任务',
            userId: const Value('a'),
            parentId: const Value('task'),
            recurrenceRule: Value(rule),
            alarms: Value(alarms),
          ),
        );
  }

  test('父子任务的所有重复规则和提醒集合均隔离且只读，不能污染后续命中', () async {
    await addRulesAndChild();
    expect(await prepare(), 1);
    final entity = (await home()).single;
    for (final task in [entity.task, entity.children.single.task]) {
      final rule = task.recurrenceRule!;
      expect(task.alarms.clear, throwsUnsupportedError);
      expect(() => rule.daysOfWeek!.clear(), throwsUnsupportedError);
      expect(() => rule.daysOfMonth!.clear(), throwsUnsupportedError);
      expect(() => rule.weeksOfMonth!.clear(), throwsUnsupportedError);
      // 旧字段也必须隔离，不能丢弃或升级已有规则。
      // ignore: deprecated_member_use
      expect(() => rule.monthsOfYear!.clear(), throwsUnsupportedError);
      expect(() => rule.daysOfYear!.clear(), throwsUnsupportedError);
    }
    final again = (await home()).single;
    expect(again.recurrenceRule!.daysOfMonth, [19]);
    expect(again.children.single.alarms, hasLength(1));
    expect(api.builds, 1);
    final persisted = await db.select(db.tasks).get();
    expect(
      persisted.every((t) => t.recurrenceRule!.daysOfMonth!.single == 19),
      isTrue,
    );
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('预组装源对象后续变化也不能修改缓存中的父子任务规则与提醒', () async {
    await addRulesAndChild();
    await prepare();
    final source = api.source.single;
    for (final task in [source.task, source.children.single.task]) {
      task.alarms.clear();
      task.recurrenceRule!.daysOfMonth!.clear();
      task.recurrenceRule!.daysOfWeek!.clear();
    }
    final cached = (await home()).single;
    for (final task in [cached.task, cached.children.single.task]) {
      expect(task.alarms, hasLength(1));
      expect(task.recurrenceRule!.daysOfMonth, [19]);
      expect(task.recurrenceRule!.daysOfWeek, hasLength(1));
    }
    expect(api.builds, 1);
  });

  test('首页到达后在组装入口中止，不再调用标签读取', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    api.beforePreparation = () {
      entered.complete();
      return release.future;
    };
    final pending = prepare();
    await entered.future;
    expect(await home(tagId: 'absent'), isEmpty);
    release.complete();
    expect(await pending, 0);
    expect(tags.preparationReads, 0);
    expect((await home()).single.id, 'task');
    expect(api.builds, 3);
  });

  test('组装结束但尚未冻结时取消，不创建或回填迟到缓存', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    api.afterPreparation = () {
      entered.complete();
      return release.future;
    };
    final pending = prepare();
    await entered.future;
    expect(await home(tagId: 'absent'), isEmpty);
    release.complete();
    expect(await pending, 0);
    expect((await home()).single.id, 'task');
    expect(api.builds, 3);
  });

  test('准备超时后不再读取标签，也不发布部分结果', () async {
    api.beforePreparation = () =>
        Future<void>.delayed(const Duration(milliseconds: 650));
    expect(await prepare(), 0);
    expect(tags.preparationReads, 0);
    expect((await home()).single.id, 'task');
    expect(api.builds, 2);
  });

  test('关联超限只读上限加一条并整组放弃，首页仍显示完整标签', () async {
    await addTags(300);
    expect(await prepare(), 0);
    expect(reads.from('task_tags').every((r) => r.$2 <= 257), isTrue);
    final before = api.builds;
    expect((await home(tagId: 'tag-0')).single.tags, hasLength(300));
    expect(api.builds, before + 1);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('标签文本计入整组预算，超限不缓存截断的标签集合', () async {
    await addTags(40, nameLength: 4000);
    expect(await prepare(), 0);
    final before = api.builds;
    final entity = (await home(tagId: 'tag-0')).single;
    expect(entity.tags, hasLength(40));
    expect(
      entity.tags.fold<int>(0, (n, t) => n + t.name.length),
      greaterThan(128 * 1024),
    );
    expect(api.builds, before + 1);
  });

  test('标签读取批次完成后取消，不继续读取下一批或构造部分父链', () async {
    await addTags(80);
    var current = true;
    reads.afterRead = (sql) async {
      if (sql.contains('FROM "tags"')) current = false;
    };
    await expectLater(
      tags.getTagEntitiesByTaskIds({
        'task': 'a',
      }, preparationBudget: budget(current: () => current)),
      throwsA(
        isA<TaskPreparationAborted>().having(
          (e) => e.interrupted,
          '取消',
          isTrue,
        ),
      ),
    );
    expect(reads.from('tags'), hasLength(1));
    expect(reads.from('tags').single.$2, 32);
    reads.afterRead = null;
    expect(
      (await tags.getTagEntitiesByTaskIds({'task': 'a'}))['task'],
      hasLength(80),
    );
  });

  test('标签关联查询结束后超时，不再查询标签详情', () async {
    await addTags(1);
    var elapsed = Duration.zero;
    reads.afterRead = (sql) async {
      if (sql.contains('FROM "task_tags"')) {
        elapsed = const Duration(seconds: 1);
      }
    };
    await expectLater(
      tags.getTagEntitiesByTaskIds({
        'task': 'a',
      }, preparationBudget: budget(elapsed: () => elapsed)),
      throwsA(
        isA<TaskPreparationAborted>().having(
          (e) => e.interrupted,
          '超时',
          isTrue,
        ),
      ),
    );
    expect(reads.from('tags'), isEmpty);
  });

  test('父链深度超限中止预读，普通标签查询仍返回完整父链', () async {
    await db.batch((b) {
      for (var i = 31; i >= 0; i--) {
        b.insert(
          db.tags,
          TagsCompanion.insert(
            id: Value('deep-$i'),
            name: '$i',
            userId: const Value('a'),
            parentId: i == 31 ? const Value.absent() : Value('deep-${i + 1}'),
          ),
        );
      }
      b.insert(
        db.taskTags,
        TaskTagsCompanion.insert(
          id: const Value('deep-link'),
          taskId: 'task',
          tagId: 'deep-0',
          userId: const Value('a'),
        ),
      );
    });
    await expectLater(
      tags.getTagEntitiesByTaskIds({'task': 'a'}, preparationBudget: budget()),
      throwsA(
        isA<TaskPreparationAborted>().having(
          (e) => e.interrupted,
          '超限',
          isFalse,
        ),
      ),
    );
    final full = (await tags.getTagEntitiesByTaskIds({
      'task': 'a',
    }))['task']!.single;
    expect(full.fullName.split('/'), hasLength(32));
  });

  test('标签总数包含父标签，超过预算时不返回部分标签', () async {
    await db.batch((b) {
      for (var i = 0; i < 140; i++) {
        b
          ..insert(
            db.tags,
            TagsCompanion.insert(id: Value('parent-$i'), name: '父$i'),
          )
          ..insert(
            db.tags,
            TagsCompanion.insert(
              id: Value('leaf-$i'),
              name: '子$i',
              parentId: Value('parent-$i'),
            ),
          )
          ..insert(
            db.taskTags,
            TaskTagsCompanion.insert(
              id: Value('link-$i'),
              taskId: 'task',
              tagId: 'leaf-$i',
              userId: const Value('a'),
            ),
          );
      }
    });
    await expectLater(
      tags.getTagEntitiesByTaskIds({'task': 'a'}, preparationBudget: budget()),
      throwsA(
        isA<TaskPreparationAborted>().having(
          (e) => e.interrupted,
          '超限',
          isFalse,
        ),
      ),
    );
    final full = (await tags.getTagEntitiesByTaskIds({'task': 'a'}))['task']!;
    expect(full, hasLength(140));
    expect(full.every((t) => t.parent != null), isTrue);
  });

  test('重复构造父链的实体总量受限，普通查询不受预加载上限影响', () async {
    await db.batch((b) {
      for (var i = 2; i >= 0; i--) {
        b.insert(
          db.tags,
          TagsCompanion.insert(
            id: Value('common-$i'),
            name: '父$i',
            parentId: i == 2 ? const Value.absent() : Value('common-${i + 1}'),
          ),
        );
      }
      for (var i = 0; i < 160; i++) {
        b
          ..insert(
            db.tags,
            TagsCompanion.insert(
              id: Value('leaf-$i'),
              name: '子$i',
              parentId: const Value('common-0'),
            ),
          )
          ..insert(
            db.taskTags,
            TaskTagsCompanion.insert(
              id: Value('link-$i'),
              taskId: 'task',
              tagId: 'leaf-$i',
              userId: const Value('a'),
            ),
          );
      }
    });
    await expectLater(
      tags.getTagEntitiesByTaskIds({'task': 'a'}, preparationBudget: budget()),
      throwsA(
        isA<TaskPreparationAborted>().having(
          (e) => e.interrupted,
          '超限',
          isFalse,
        ),
      ),
    );
    final full = (await tags.getTagEntitiesByTaskIds({'task': 'a'}))['task']!;
    expect(full, hasLength(160));
    expect(full.every((t) => t.fullName.split('/').length == 4), isTrue);
  });
}
