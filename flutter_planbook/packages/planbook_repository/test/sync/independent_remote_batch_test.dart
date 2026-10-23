import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:planbook_repository/sync/apply_remote_batch.dart';
import 'package:planbook_repository/sync/pull_write_fence.dart';
import 'package:supabase_planbook_api/sync/remote_table_pull.dart';

void main() {
  late AppDatabase db;
  late OutboxApi outbox;
  late Map<String, String>? saved;
  final date = Jiffy.parse('2026-10-18');
  RemoteTableBatch batch(
    String table,
    List<Map<String, dynamic>> rows, {
    Set<String>? inventory,
    Future<Set<String>> Function(List<String>)? confirmMissing,
    Map<String, String> previous = const {},
  }) => RemoteTableBatch(
    table: table,
    rows: [
      for (final row in rows) {...row, '_sync_version': '2'},
    ],
    inventory: inventory ?? rows.map((r) => r['id']! as String).toSet(),
    confirmMissing: confirmMissing ?? (ids) async => ids.toSet(),
    previous: previous,
    save: (versions) async {
      saved = versions;
    },
  );
  Future<void> apply(RemoteTableBatch value, {PullWriteFence? fence}) =>
      applyRemoteBatch(
        db: db,
        batch: value,
        account: 'a',
        validateAccount: () {},
        fence: fence,
      );
  setUp(() async {
    saved = null;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    outbox = OutboxApi(db: db);
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: const Value('task'),
            title: 'task',
            userId: const Value('a'),
          ),
        );
    await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            id: const Value('note'),
            title: 'note',
            userId: const Value('a'),
          ),
        );
    await db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(
            id: const Value('tag'),
            name: 'tag',
            userId: const Value('a'),
          ),
        );
  });
  tearDown(() => db.close());

  test('主表无修改也能合并完成活动、撤销完成', () async {
    final original = (await db.select(db.tasks).get()).single;
    final activity = TaskActivity(
      id: 'done',
      taskId: 'task',
      userId: 'a',
      createdAt: date,
      completedAt: date,
    );
    await apply(batch('task_activities', [activity.toJson()]));
    expect((await db.select(db.taskActivities).get()).single.completedAt, date);
    await apply(
      batch('task_activities', [
        activity.copyWith(deletedAt: Value(date)).toJson(),
      ]),
    );
    expect((await db.select(db.taskActivities).get()).single.deletedAt, date);
    expect(
      (await db.select(db.tasks).get()).single.toJson(),
      original.toJson(),
    );
    expect(saved, {'done': '2'});
  });

  for (final table in ['task_tags', 'note_tags']) {
    test('$table 独立新增关联、确认物理删除后只软删除；其他账号不受影响', () async {
      final Map<String, dynamic> row;
      if (table == 'task_tags') {
        row = TaskTag(
          id: 'link',
          taskId: 'task',
          tagId: 'tag',
          userId: 'a',
          createdAt: date,
        ).toJson();
      } else {
        row = NoteTag(
          id: 'link',
          noteId: 'note',
          tagId: 'tag',
          userId: 'a',
          createdAt: date,
        ).toJson();
      }
      await apply(batch(table, [row]));
      if (table == 'task_tags') {
        await db
            .into(db.taskTags)
            .insert(TaskTag.fromJson({...row, 'id': 'other', 'user_id': 'b'}));
      } else {
        await db
            .into(db.noteTags)
            .insert(NoteTag.fromJson({...row, 'id': 'other', 'user_id': 'b'}));
      }
      await apply(batch(table, []));
      final rows = table == 'task_tags'
          ? (await db.select(db.taskTags).get()).map((r) => r.toJson()).toList()
          : (await db.select(db.noteTags).get())
                .map((r) => r.toJson())
                .toList();
      expect(rows, hasLength(2));
      expect(
        rows.firstWhere((r) => r['id'] == 'link')['deleted_at'],
        isNotNull,
      );
      expect(rows.firstWhere((r) => r['id'] == 'other')['deleted_at'], isNull);
    });
  }

  test('清单漏掉但二次查询仍存在的关联不删除', () async {
    final link = TaskTag(
      id: 'link',
      taskId: 'task',
      tagId: 'tag',
      userId: 'a',
      createdAt: date,
    );
    await db.into(db.taskTags).insert(link);
    await apply(batch('task_tags', [], confirmMissing: (_) async => {}));
    expect((await db.select(db.taskTags).get()).single.deletedAt, isNull);
  });

  for (final preexisting in [true, false]) {
    test('本地写入（拉取前已有：$preexisting）上传成功后仍被本轮保护，不确认远程版本', () async {
      final activity = TaskActivity(
        id: 'done',
        taskId: 'task',
        userId: 'a',
        createdAt: date,
        completedAt: date,
      );
      await db.into(db.taskActivities).insert(activity);
      Future<void> enqueue() => outbox.enqueue(
        tableName: 'task_activities',
        recordId: 'done',
        operation: 'update',
        payload: '{}',
      );
      if (preexisting) await enqueue();
      final fence = await PullWriteFence.capture(db);
      if (!preexisting) await enqueue();
      final pending = await outbox.getPending();
      await outbox.markSynced(pending.single.id);
      await apply(
        batch('task_activities', [
          activity.copyWith(completedAt: const Value(null)).toJson(),
        ]),
        fence: fence,
      );
      expect(
        (await db.select(db.taskActivities).get()).single.completedAt,
        date,
      );
      expect(saved, isNull);
    });
  }

  test('父任务待上传时保护其活动和关联删除，解除保护后可重新合并', () async {
    final link = TaskTag(
      id: 'link',
      taskId: 'task',
      tagId: 'tag',
      userId: 'a',
      createdAt: date,
    );
    await db.into(db.taskTags).insert(link);
    await outbox.enqueue(
      tableName: 'tasks',
      recordId: 'task',
      operation: 'update',
      payload: '{}',
    );
    final activity = TaskActivity(
      id: 'done',
      taskId: 'task',
      userId: 'a',
      createdAt: date,
      completedAt: date,
    );
    await apply(batch('task_activities', [activity.toJson()]));
    await apply(batch('task_tags', []));
    expect(await db.select(db.taskActivities).get(), isEmpty);
    expect((await db.select(db.taskTags).get()).single.deletedAt, isNull);
    await outbox.markSynced((await outbox.getPending()).single.id);
    await apply(batch('task_activities', [activity.toJson()]));
    expect(await db.select(db.taskActivities).get(), hasLength(1));
  });

  test('异账号数据、失败的删除确认均不标记同步成功', () async {
    final activity = TaskActivity(id: 'bad', userId: 'b', createdAt: date);
    await expectLater(
      apply(batch('task_activities', [activity.toJson()])),
      throwsStateError,
    );
    expect(saved, isNull);
    await db
        .into(db.taskTags)
        .insert(
          TaskTag(
            id: 'link',
            taskId: 'task',
            tagId: 'tag',
            userId: 'a',
            createdAt: date,
          ),
        );
    await expectLater(
      apply(
        batch(
          'task_tags',
          [],
          confirmMissing: (_) async => throw StateError('network failed'),
        ),
      ),
      throwsStateError,
    );
    expect((await db.select(db.taskTags).get()).single.deletedAt, isNull);
    expect(saved, isNull);
  });

  test('版本清单已建立后，从未记录的本地关联不会被软删除', () async {
    await db
        .into(db.taskTags)
        .insert(
          TaskTag(
            id: 'local',
            taskId: 'task',
            tagId: 'tag',
            userId: 'a',
            createdAt: date,
          ),
        );
    await apply(batch('task_tags', [], previous: {'other': '1'}));
    expect((await db.select(db.taskTags).get()).single.deletedAt, isNull);
  });

  test('版本清单里见过的关联，远程确认消失后仍软删除', () async {
    await db
        .into(db.taskTags)
        .insert(
          TaskTag(
            id: 'link',
            taskId: 'task',
            tagId: 'tag',
            userId: 'a',
            createdAt: date,
          ),
        );
    await apply(batch('task_tags', [], previous: {'link': '1'}));
    expect((await db.select(db.taskTags).get()).single.deletedAt, isNotNull);
  });
}
