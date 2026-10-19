import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

void main() {
  late AppDatabase db;
  late DatabaseTaskApi api;
  final date = Jiffy.parse('2026-10-18');
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final outbox = OutboxApi(db: db);
    api = DatabaseTaskApi(
      db: db,
      outboxApi: outbox,
      tagApi: DatabaseTagApi(db: db, outboxApi: outbox),
    );
  });
  tearDown(() => db.close());

  test('多标签、多实例、多完成记录的关联展开保持父子顺序和原有选择口径', () async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('parent'),
            title: '父任务',
            userId: const Value('a'),
          ),
        );
    await db.batch((b) {
      for (var i = 0; i < 160; i++) {
        final id = 'child-${i.toString().padLeft(3, '0')}';
        b
          ..insert(
            db.tasks,
            TasksCompanion.insert(
              id: Value(id),
              title: id,
              userId: const Value('a'),
              parentId: const Value('parent'),
            ),
          )
          ..insert(
            db.taskActivities,
            TaskActivity(
              id: 'early-$id',
              taskId: id,
              completedAt: date,
              createdAt: date,
            ),
          );
        if (i == 0) {
          b.insert(
            db.taskActivities,
            TaskActivity(
              id: 'later-$id',
              taskId: id,
              completedAt: date.add(hours: 1),
              createdAt: date.add(hours: 1),
            ),
          );
        }
      }
      for (var i = 0; i < 12; i++) {
        final id = 'tag-$i';
        b
          ..insert(
            db.tags,
            TagsCompanion.insert(
              id: Value(id),
              name: id,
              userId: const Value('a'),
            ),
          )
          ..insert(
            db.taskTags,
            TaskTagsCompanion.insert(
              id: Value('link-$i'),
              taskId: 'parent',
              tagId: id,
              userId: const Value('a'),
            ),
          );
      }
      for (var i = 0; i < 2; i++) {
        b
          ..insert(
            db.taskOccurrences,
            TaskOccurrencesCompanion.insert(
              id: Value('occ-$i'),
              taskId: const Value('parent'),
              occurrenceAt: date.add(days: i),
              startAt: Value(date.add(days: i)),
            ),
          )
          ..insert(
            db.taskActivities,
            TaskActivity(
              id: 'activity-$i',
              taskId: 'parent',
              createdAt: date.add(hours: i),
              completedAt: date.add(hours: i),
            ),
          );
      }
    });
    final rows =
        await (db.select(db.tasks).join([
                leftOuterJoin(
                  db.taskTags,
                  db.taskTags.taskId.equalsExp(db.tasks.id),
                ),
                leftOuterJoin(
                  db.taskOccurrences,
                  db.taskOccurrences.taskId.equalsExp(db.tasks.id),
                ),
                leftOuterJoin(
                  db.taskActivities,
                  db.taskActivities.taskId.equalsExp(db.tasks.id),
                ),
                leftOuterJoin(
                  api.childrenTasks,
                  api.childrenTasks.parentId.equalsExp(db.tasks.id),
                ),
                leftOuterJoin(
                  api.childrenTaskActivities,
                  api.childrenTaskActivities.taskId.equalsExp(
                    api.childrenTasks.id,
                  ),
                ),
              ])
              ..where(db.tasks.id.equals('parent'))
              ..orderBy([
                OrderingTerm.asc(db.taskOccurrences.occurrenceAt),
                OrderingTerm.asc(db.taskActivities.createdAt),
                OrderingTerm.asc(api.childrenTasks.id),
                OrderingTerm.asc(api.childrenTaskActivities.createdAt),
              ]))
            .get();
    expect(rows, hasLength(12 * 2 * 2 * 161));
    final timings = <int>[];
    late List<TaskEntity> result;
    for (var run = 0; run < 5; run++) {
      final stopwatch = Stopwatch()..start();
      result = await api.buildTaskEntities(rows);
      timings.add(stopwatch.elapsedMicroseconds);
    }
    // 只用于桌面前后对照，不使用受机器负载影响的时间阈值作为断言。
    debugPrint('TaskEntityAssembly rows=${rows.length} timingsUs=$timings');
    final parent = result.single;
    expect(parent.id, 'parent');
    expect(parent.tags.map((t) => t.id).toSet(), {
      for (var i = 0; i < 12; i++) 'tag-$i',
    });
    expect(parent.occurrence!.id, 'occ-1');
    expect(parent.activity!.id, 'activity-1');
    expect(parent.children.map((t) => t.id), [
      for (var i = 0; i < 160; i++) 'child-${i.toString().padLeft(3, '0')}',
    ]);
    expect(parent.children.first.activity!.id, 'early-child-000');
    expect(parent.children.last.activity!.id, 'early-child-159');
    expect(parent.children.every((c) => c.tags.isEmpty), isTrue);
  });

  test('无关联父任务保留首次出现顺序，空列表不产生实体', () async {
    await db
        .into(db.tasks)
        .insert(TasksCompanion.insert(id: const Value('a'), title: 'a'));
    await db
        .into(db.tasks)
        .insert(TasksCompanion.insert(id: const Value('b'), title: 'b'));
    final rows = await (db.select(
      db.tasks,
    )..orderBy([(t) => OrderingTerm.desc(t.id)])).get();
    final joined = await (db.select(
      db.tasks,
    )..orderBy([(t) => OrderingTerm.desc(t.id)])).join([]).get();
    expect(
      (await api.buildTaskEntities(joined)).map((t) => t.task.toJson()),
      rows.map((t) => t.toJson()),
    );
    expect(
      (await api.buildTaskEntities(joined)).every(
        (t) => t.children.isEmpty && t.activity == null && t.occurrence == null,
      ),
      isTrue,
    );
    expect(await api.buildTaskEntities([]), isEmpty);
  });
}
