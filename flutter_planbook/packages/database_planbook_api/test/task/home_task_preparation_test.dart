import 'dart:async';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class _ObservedApi extends DatabaseTaskTodayApi {
  _ObservedApi({
    required super.db,
    required super.tagApi,
    required super.outboxApi,
  });

  int builds = 0;
  Future<void> Function()? beforePreparationBuild;

  @override
  Future<List<TaskEntity>> assembleTaskEntities(
    List<TypedResult> rows, {
    bool yieldBetweenBatches = false,
    Map<String, List<TagEntity>>? currentTags,
    TaskPreparationBudget? preparationBudget,
  }) async {
    builds++;
    if (yieldBetweenBatches) await beforePreparationBuild?.call();
    return super.assembleTaskEntities(
      rows,
      yieldBetweenBatches: yieldBetweenBatches,
      currentTags: currentTags,
      preparationBudget: preparationBudget,
    );
  }
}

void main() {
  late AppDatabase db;
  late _ObservedApi api;
  final day = Jiffy.parse('2026-10-19');

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final outbox = OutboxApi(db: db);
    api = _ObservedApi(
      db: db,
      tagApi: DatabaseTagApi(db: db, outboxApi: outbox),
      outboxApi: outbox,
    );
    await db.batch((b) {
      for (final id in ['loose', 'tagged']) {
        b.insert(
          db.tasks,
          TasksCompanion.insert(
            id: Value(id),
            title: id,
            userId: const Value('a'),
            startAt: Value(day.add(hours: 9)),
            endAt: Value(day.add(hours: 10)),
          ),
        );
      }
      b
        ..insert(
          db.tasks,
          TasksCompanion.insert(
            id: const Value('child'),
            title: '子任务',
            parentId: const Value('loose'),
            userId: const Value('a'),
          ),
        )
        ..insert(
          db.tags,
          TagsCompanion.insert(
            id: const Value('tag'),
            name: '标签',
            userId: const Value('a'),
          ),
        )
        ..insert(
          db.taskTags,
          TaskTagsCompanion.insert(
            id: const Value('link'),
            taskId: 'tagged',
            tagId: 'tag',
            userId: const Value('a'),
          ),
        );
    });
  });
  tearDown(() => db.close());

  Future<int> prepare() => api.prepareHomeTaskEntities(date: day, userId: 'a');
  Future<List<TaskEntity>> read({
    String? tagId,
    String? userId = 'a',
    Jiffy? date,
    bool? isCompleted,
    TaskPriority? priority,
  }) => api
      .getTaskEntities(
        date: date ?? day,
        userId: userId,
        tagId: tagId,
        isCompleted: isCompleted,
        priority: priority,
      )
      .first;

  test('预组装后原查询复用实体，空白区重复请求不再组装且没有 Outbox 副作用', () async {
    expect(await prepare(), 2);
    expect(api.builds, 2);
    final loose = await read();
    final tagged = await read(tagId: 'tag');
    final blank = await read();
    expect(api.builds, 2);
    expect(loose.single.children.single.title, '子任务');
    expect(tagged.single.tags.single.name, '标签');
    expect(identical(loose.single, blank.single), isTrue);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
    // 返回列表可以由调用方调整，但不能污染缓存中的父子任务集合。
    loose.clear();
    expect((await read()).single.id, 'loose');
    expect(() => blank.single.children.clear(), throwsUnsupportedError);
  });

  test('无需失效通知，任务和子任务直接 SQL 改动仍使缓存失效', () async {
    await prepare();
    await db.customStatement(
      "UPDATE tasks SET title = '新子任务' WHERE id = 'child'",
    );
    final loose = await read();
    expect(loose.single.children.single.title, '新子任务');
    expect(api.builds, 3);
    await db.customStatement(
      "UPDATE tasks SET title = '新任务' WHERE id = 'tagged'",
    );
    expect((await read(tagId: 'tag')).single.title, '新任务');
    expect(api.builds, 4);
  });

  test('没有投影的标签重命名也会重组装，不依赖任务更新时间', () async {
    await prepare();
    await db.customStatement("UPDATE tags SET name = '新标签' WHERE id = 'tag'");
    expect((await read(tagId: 'tag')).single.tags.single.name, '新标签');
    expect(api.builds, 3);
  });

  test('标签父链修改不能复用旧的层级实体', () async {
    await prepare();
    await db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(
            id: const Value('ancestor'),
            name: '父标签',
            userId: const Value('a'),
          ),
        );
    await (db.update(db.tags)..where((t) => t.id.equals('tag'))).write(
      const TagsCompanion(parentId: Value('ancestor')),
    );
    expect((await read(tagId: 'tag')).single.tags.single.fullName, '父标签/标签');
    expect(api.builds, 3);
  });

  test('移除和恢复标签保持无标签列表、标签筛选和完整标签内容', () async {
    await prepare();
    await (db.update(db.taskTags)..where((t) => t.id.equals('link'))).write(
      TaskTagsCompanion(deletedAt: Value(day)),
    );
    expect(await read(tagId: 'tag'), isEmpty);
    final loose = await read();
    expect(loose.map((t) => t.id).toSet(), {'loose', 'tagged'});
    expect(loose.singleWhere((t) => t.id == 'tagged').tags, isEmpty);
    await (db.update(db.taskTags)..where((t) => t.id.equals('link'))).write(
      const TaskTagsCompanion(deletedAt: Value(null)),
    );
    expect((await read(tagId: 'tag')).single.tags.single.id, 'tag');
    expect((await read()).single.id, 'loose');
  });

  test('完成记录变化、完成筛选和优先级筛选不能误用默认缓存', () async {
    await prepare();
    await db
        .into(db.taskActivities)
        .insert(
          TaskActivity(
            id: 'done',
            taskId: 'loose',
            createdAt: day,
            completedAt: day,
          ),
        );
    expect((await read()).single.isCompleted, isTrue);
    expect(await read(isCompleted: false), isEmpty);
    expect((await read(isCompleted: true)).single.isCompleted, isTrue);
    expect(await read(priority: TaskPriority.high), isEmpty);
  });

  test('换日和换号使用原查询，不返回旧账号任务', () async {
    await prepare();
    expect(await read(userId: 'b'), isEmpty);
    expect(await read(date: day.add(days: 1)), isEmpty);
    expect((await read()).single.id, 'loose');
    expect(api.builds, 5);
  });

  test('首页不会等待进行中的预组装，迟到结果不再回填缓存', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    api.beforePreparationBuild = () {
      entered.complete();
      return release.future;
    };
    final pending = prepare();
    await entered.future;
    expect(
      (await read().timeout(const Duration(seconds: 2))).single.id,
      'loose',
    );
    release.complete();
    expect(await pending, 0);
    expect((await read()).single.id, 'loose');
    expect(api.builds, 3);
    expect(await prepare(), 0);
  });

  test('预组装期间账号失效时不发布结果', () async {
    var current = true;
    api.beforePreparationBuild = () async {
      current = false;
    };
    expect(
      await api.prepareHomeTaskEntities(
        date: day,
        userId: 'a',
        isCurrent: () => current,
      ),
      0,
    );
    expect((await read()).single.id, 'loose');
    expect(api.builds, 2);
  });

  test('大分组整组跳过预加载，首页仍返回完整子任务', () async {
    await db.batch((b) {
      for (var i = 0; i < 280; i++) {
        b.insert(
          db.tasks,
          TasksCompanion.insert(
            id: Value('extra-$i'),
            title: '$i',
            parentId: const Value('loose'),
            userId: const Value('a'),
          ),
        );
      }
    });
    expect(await prepare(), 1);
    expect((await read()).single.children, hasLength(281));
    expect(api.builds, 2);
  });

  test('预加载期间让出事件循环，动画和首页可以获得执行机会', () async {
    var yielded = false;
    api.beforePreparationBuild = () async {
      Timer.run(() {
        yielded = true;
      });
    };
    await prepare();
    expect(yielded, isTrue);
  });

  test('文本过大的分组不保留缓存，首页数据也不被截断', () async {
    final title = '长' * (128 * 1024 + 1);
    await (db.update(db.tasks)..where((t) => t.id.equals('loose'))).write(
      TasksCompanion(title: Value(title)),
    );
    expect(await prepare(), 1);
    expect((await read()).single.title, title);
    expect(api.builds, 2);
  });

  test('新准备请求先完成时，旧请求不能覆盖它或在首页开始后回填', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    var first = true;
    api.beforePreparationBuild = () {
      if (!first) return Future.value();
      first = false;
      entered.complete();
      return release.future;
    };
    final old = prepare();
    await entered.future;
    await (db.update(db.tasks)..where((t) => t.id.equals('loose'))).write(
      const TasksCompanion(title: Value('新数据')),
    );
    expect(await prepare(), 2);
    final builds = api.builds;
    expect((await read()).single.title, '新数据');
    expect(api.builds, builds);
    release.complete();
    expect(await old, 0);
    expect((await read()).single.title, '新数据');
    expect(api.builds, builds);
  });

  test('重复实例隐藏、分离改期和完成记录变化均以实际首页查询为准', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('series'),
            title: '重复任务',
            userId: const Value('a'),
            startAt: Value(day.add(hours: 11)),
            endAt: Value(day.add(hours: 12)),
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
    expect(await prepare(), 2);
    var tasks = await read();
    expect(tasks.map((t) => t.id).toSet(), {'loose', 'series'});
    final series = tasks.singleWhere((t) => t.id == 'series');
    expect(series.occurrence, isNotNull);
    await db
        .into(db.taskActivities)
        .insert(
          TaskActivity(
            id: 'done-series',
            taskId: 'series',
            occurrenceAt: series.occurrence!.occurrenceAt,
            completedAt: day,
            createdAt: day,
          ),
        );
    tasks = await read();
    expect(tasks.singleWhere((t) => t.id == 'series').isCompleted, isTrue);
    await (db.update(db.taskOccurrences)..where(
          (o) =>
              o.taskId.equals('series') &
              o.occurrenceAt.equals(series.occurrence!.occurrenceAt.dateTime),
        ))
        .write(TaskOccurrencesCompanion(deletedAt: Value(day)));
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('detached'),
            title: '改期实例',
            userId: const Value('a'),
            detachedFromTaskId: const Value('series'),
            detachedRecurrenceAt: Value(day),
            startAt: Value(day.add(days: 1, hours: 11)),
            endAt: Value(day.add(days: 1, hours: 12)),
          ),
        );
    expect((await read()).map((t) => t.id), ['loose']);
    final tomorrow = await read(date: day.add(days: 1));
    expect(tomorrow.map((t) => t.id).toSet(), {'series', 'detached'});
    final hidden =
        await (db.select(db.taskOccurrences)..where(
              (o) =>
                  o.taskId.equals('series') &
                  o.occurrenceAt.equals(
                    series.occurrence!.occurrenceAt.dateTime,
                  ),
            ))
            .getSingle();
    expect(hidden.deletedAt, day);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('缓存命中后任务数据仍通过原来的 watch 实时更新', () async {
    await prepare();
    final iterator = StreamIterator(
      api.getTaskEntities(date: day, userId: 'a'),
    );
    addTearDown(iterator.cancel);
    expect(await iterator.moveNext(), isTrue);
    expect(api.builds, 2);
    await (db.update(db.tasks)..where((t) => t.id.equals('child'))).write(
      const TasksCompanion(title: Value('实时更新')),
    );
    while (await iterator.moveNext().timeout(const Duration(seconds: 2))) {
      if (iterator.current.single.children.single.title == '实时更新') break;
    }
    expect(iterator.current.single.children.single.title, '实时更新');
  });

  test('预加载读行后发生修改，旧组装结果不能遮蔽新任务', () async {
    var first = true;
    api.beforePreparationBuild = () async {
      if (!first) return;
      first = false;
      await (db.update(db.tasks)..where((t) => t.id.equals('loose'))).write(
        const TasksCompanion(title: Value('组装期间修改')),
      );
    };
    await prepare();
    final builds = api.builds;
    expect((await read()).single.title, '组装期间修改');
    expect(api.builds, builds + 1);
  });
}
