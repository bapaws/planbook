import 'dart:async';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

void main() {
  late AppDatabase db;
  late DatabaseTaskTodayApi api;
  final day = Jiffy.parse('2026-10-18');
  final next = day.add(days: 1);
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final outbox = OutboxApi(db: db);
    api = DatabaseTaskTodayApi(
      db: db,
      outboxApi: outbox,
      tagApi: DatabaseTagApi(db: db, outboxApi: outbox),
    );
    await db.batch((b) {
      for (final (id, user, start) in [
        ('tagged', 'a', day),
        ('loose', 'a', next),
        ('foreign', 'b', day),
        ('series', 'a', day),
      ]) {
        b.insert(
          db.tasks,
          TasksCompanion.insert(
            id: Value(id),
            title: id,
            userId: Value(user),
            startAt: Value(start.add(hours: 9)),
            endAt: Value(start.add(hours: 10)),
            recurrenceRule: id == 'series'
                ? const Value(
                    RecurrenceRule(frequency: RecurrenceFrequency.daily),
                  )
                : const Value.absent(),
          ),
        );
      }
      b
        ..insert(
          db.tasks,
          TasksCompanion.insert(
            id: const Value('child'),
            title: '子任务',
            userId: const Value('a'),
            parentId: const Value('tagged'),
          ),
        )
        ..insert(
          db.tasks,
          TasksCompanion.insert(
            id: const Value('deleted-child'),
            title: '已删除子任务',
            parentId: const Value('tagged'),
            deletedAt: Value(day),
          ),
        )
        ..insert(
          db.tags,
          TagsCompanion.insert(
            id: const Value('tag'),
            name: '工作',
            userId: const Value('a'),
          ),
        );
      for (final id in ['tagged', 'series']) {
        b.insert(
          db.taskTags,
          TaskTagsCompanion.insert(
            id: Value('link-$id'),
            taskId: id,
            tagId: 'tag',
            userId: const Value('a'),
          ),
        );
      }
      for (final at in [day, next]) {
        b.insert(
          db.taskOccurrences,
          TaskOccurrencesCompanion.insert(
            taskId: const Value('series'),
            occurrenceAt: at,
            startAt: Value(at.add(hours: 9)),
            endAt: Value(at.add(hours: 10)),
          ),
        );
      }
      b
        ..insert(
          db.taskActivities,
          TaskActivity(
            id: 'done-parent',
            taskId: 'tagged',
            createdAt: day,
            completedAt: day,
          ),
        )
        ..insert(
          db.taskActivities,
          TaskActivity(
            id: 'done-child',
            taskId: 'child',
            createdAt: day,
            completedAt: day,
          ),
        )
        ..insert(
          db.taskActivities,
          TaskActivity(
            id: 'done-series',
            taskId: 'series',
            occurrenceAt: next,
            createdAt: next,
            completedAt: next,
          ),
        );
    });
  });
  tearDown(() => db.close());

  test('切换日期保持标签分组、完成状态、子任务和账号过滤', () async {
    final today = await api
        .getTaskEntities(date: day, tagId: 'tag', userId: 'a')
        .first;
    expect(today.map((t) => t.id).toSet(), {'tagged', 'series'});
    final tagged = today.singleWhere((t) => t.id == 'tagged');
    expect(tagged.tags.single.id, 'tag');
    expect(tagged.children.single.id, 'child');
    expect(tagged.children.single.isCompleted, isTrue);
    expect(tagged.isCompleted, isTrue);
    expect(today.singleWhere((t) => t.id == 'series').isCompleted, isFalse);
    final tomorrow = await api
        .getTaskEntities(date: next, tagId: 'tag', userId: 'a')
        .first;
    expect(tomorrow.single.id, 'series');
    expect(tomorrow.single.isCompleted, isTrue);
    expect(tomorrow.single.occurrence!.occurrenceAt, next);
    final untagged = await api.getTaskEntities(date: next, userId: 'a').first;
    expect(untagged.single.id, 'loose');
    final incomplete = await api
        .getTaskEntities(
          date: day,
          tagId: 'tag',
          userId: 'a',
          isCompleted: false,
        )
        .first;
    expect(incomplete.single.id, 'series');
    final completed = await api
        .getTaskEntities(
          date: day,
          tagId: 'tag',
          userId: 'a',
          isCompleted: true,
        )
        .first;
    expect(completed.single.id, 'tagged');
  });

  test('不投影标签字段仍监听标签关联变化，移除和恢复标签立即更新筛选', () async {
    final filtered = StreamIterator(
      api.getTaskEntities(
        date: day,
        tagId: 'tag',
        userId: 'a',
      ),
    );
    final untagged = StreamIterator(
      api.getTaskEntities(date: day, userId: 'a'),
    );
    addTearDown(filtered.cancel);
    addTearDown(untagged.cancel);
    expect(await filtered.moveNext(), isTrue);
    expect(await untagged.moveNext(), isTrue);
    expect(filtered.current.map((t) => t.id).toSet(), {'tagged', 'series'});
    expect(untagged.current, isEmpty);
    await (db.update(
      db.taskTags,
    )..where((t) => t.id.equals('link-tagged'))).write(
      TaskTagsCompanion(deletedAt: Value(day)),
    );
    while (await filtered.moveNext().timeout(const Duration(seconds: 2))) {
      if (!filtered.current.any((t) => t.id == 'tagged')) break;
    }
    expect(filtered.current.map((t) => t.id), ['series']);
    while (await untagged.moveNext().timeout(const Duration(seconds: 2))) {
      if (untagged.current.any((t) => t.id == 'tagged')) break;
    }
    expect(untagged.current.single.id, 'tagged');
    expect(untagged.current.single.tags, isEmpty);
    await (db.update(
      db.taskTags,
    )..where((t) => t.id.equals('link-tagged'))).write(
      const TaskTagsCompanion(deletedAt: Value(null)),
    );
    while (await filtered.moveNext().timeout(const Duration(seconds: 2))) {
      if (filtered.current.any((t) => t.id == 'tagged')) break;
    }
    expect(
      filtered.current.singleWhere((t) => t.id == 'tagged').tags.single.id,
      'tag',
    );
  });

  test('全天查询同样保留标签和子任务，子任务修改仍通过原数据流更新', () async {
    final stream = StreamIterator(
      api.getAllTodayTaskEntities(day: day, userId: 'a'),
    );
    addTearDown(stream.cancel);
    expect(await stream.moveNext(), isTrue);
    expect(stream.current.map((t) => t.id).toSet(), {'tagged', 'series'});
    expect(
      stream.current.singleWhere((t) => t.id == 'tagged').tags.single.id,
      'tag',
    );
    await (db.update(db.tasks)..where((t) => t.id.equals('child'))).write(
      const TasksCompanion(title: Value('已修改子任务')),
    );
    while (await stream.moveNext().timeout(const Duration(seconds: 2))) {
      final task = stream.current.singleWhere((t) => t.id == 'tagged');
      if (task.children.single.title == '已修改子任务') break;
    }
    expect(
      stream.current.singleWhere((t) => t.id == 'tagged').children.single.title,
      '已修改子任务',
    );
    final tomorrow = await api
        .getAllTodayTaskEntities(day: next, userId: 'a')
        .first;
    expect(tomorrow.map((t) => t.id).toSet(), {'loose', 'series'});
  });
}
