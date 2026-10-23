// 测试显式区分普通增量和强制全量入口。
// ignore_for_file: avoid_redundant_argument_values
import 'dart:async';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:database_planbook_api/task/task_occurrence_generator.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_planbook_api/sync/remote_table_pull.dart';
import 'package:supabase_planbook_api/task/supabase_task_api.dart';

class _Remote extends Mock implements SupabaseTaskApi {}

class _Queries extends QueryInterceptor {
  void Function(String)? afterSelect;
  void Function(String)? afterInsert;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final result = await executor.runSelect(statement, args);
    afterSelect?.call(statement);
    return result;
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final result = await executor.runInsert(statement, args);
    afterInsert?.call(statement);
    return result;
  }
}

class _AccountTasks extends TasksRepository {
  _AccountTasks({
    required super.sp,
    required super.db,
    required super.tagApi,
    required super.outboxApi,
    required super.supabaseTaskApi,
  });
  String? account = 'a';
  @override
  String? get userId => account;
}

void main() {
  late AppDatabase db;
  late _Queries queries;
  late SharedPreferences sp;
  late OutboxApi outbox;
  late DatabaseTagApi tagApi;
  late _Remote remote;
  late _AccountTasks repository;
  late Map<String, Map<String, String>> saved;
  final date = Jiffy.parse('2026-10-18');
  // 自然日不能按固定 24 小时偏移，纽约夏令时结束当天有 25 小时。
  Jiffy calendarDay(int offset) =>
      Jiffy.parseFromDateTime(DateTime(2026, 10, 18 + offset));
  Task task(String id) => Task(
    id: id,
    title: id,
    userId: 'a',
    createdAt: date,
    order: 0,
    layer: 0,
    childCount: 0,
    isAllDay: false,
    alarms: const [],
  );
  RemoteSyncRows rows({
    List<Map<String, dynamic>> tasks = const [],
    List<Map<String, dynamic>> activities = const [],
    List<Map<String, dynamic>> tags = const [],
    List<Map<String, dynamic>> links = const [],
  }) {
    final tables = {
      'tasks': tasks,
      'task_activities': activities,
      'tags': tags,
      'task_tags': links,
    };
    return RemoteSyncRows({
      for (final entry in tables.entries)
        entry.key: RemoteTableBatch(
          table: entry.key,
          rows: [
            for (final row in entry.value)
              {...row, '_sync_version': row['_sync_version'] ?? '2'},
          ],
          inventory: entry.value.map((r) => r['id']! as String).toSet(),
          confirmMissing: (ids) async => ids.toSet(),
          previous: saved[entry.key] ?? const {},
          save: (versions) async {
            saved[entry.key] = versions;
          },
        ),
    }, 'tasks');
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sp = await SharedPreferences.getInstance();
    saved = {};
    queries = _Queries();
    db = AppDatabase.forTesting(NativeDatabase.memory().interceptWith(queries));
    outbox = OutboxApi(db: db);
    tagApi = DatabaseTagApi(db: db, outboxApi: outbox);
    remote = _Remote();
    repository = _AccountTasks(
      sp: sp,
      db: db,
      tagApi: tagApi,
      outboxApi: outbox,
      supabaseTaskApi: remote,
    );
  });
  tearDown(() async {
    await TaskOccurrenceGenerator.shared.close();
    await db.close();
  });

  _AccountTasks freshRepository() => _AccountTasks(
    sp: sp,
    db: db,
    tagApi: tagApi,
    outboxApi: outbox,
    supabaseTaskApi: remote,
  );
  Future<void> pull(List<Task> tasks) async {
    when(() => remote.getLatestTasks(force: false)).thenAnswer(
      (_) async => rows(tasks: tasks.map((t) => t.toJson()).toList()),
    );
    repository = freshRepository();
    await repository.syncTasks();
  }

  Task series([String id = 'z-parent']) => task(id).copyWith(
    startAt: Value(date.add(hours: 9)),
    endAt: Value(date.add(hours: 10)),
    recurrenceRule: const Value(
      RecurrenceRule(frequency: RecurrenceFrequency.daily),
    ),
  );
  Task detached(
    Task parent, {
    bool deleted = false,
    String id = 'a-child',
    int day = 2,
  }) => task(id).copyWith(
    startAt: Value(calendarDay(day + 1).add(hours: 11)),
    endAt: Value(calendarDay(day + 1).add(hours: 12)),
    detachedFromTaskId: Value(parent.id),
    detachedRecurrenceAt: Value(calendarDay(day)),
    detachedReason: Value(
      deleted ? DetachedReason.deleted : DetachedReason.modified,
    ),
    deletedAt: Value(deleted ? date : null),
  );
  Future<List<TaskOccurrence>> markers(Task parent) =>
      (db.select(db.taskOccurrences)..where(
            (o) => o.taskId.equals(parent.id) & o.deletedAt.isNotNull(),
          ))
          .get();
  Future<List<String>> visible(Jiffy at, {String? tagId}) async {
    final today = DatabaseTaskTodayApi(
      db: db,
      tagApi: tagApi,
      outboxApi: outbox,
    );
    await today.preGenerateTaskOccurrences(fromDate: at);
    final result = await today
        .getTaskEntities(date: at, userId: 'a', tagId: tagId)
        .first;
    // 等待查询内沿用的后台核验完成，再关闭测试库。
    await today.preGenerateTaskOccurrences(fromDate: at);
    return result.map((e) => e.id).toList();
  }

  for (final deleted in [false, true]) {
    for (final parentFirst in [false, true]) {
      test(
        '同轮父子乱序：deleted=$deleted parentFirst=$parentFirst，隐藏原日期并确认版本',
        () async {
          final parent = series();
          final child = detached(parent, deleted: deleted);
          await pull(parentFirst ? [parent, child] : [child, parent]);
          expect(saved['tasks'], {child.id: '2', parent.id: '2'});
          final hidden = (await markers(parent)).single;
          expect(hidden.occurrenceAt, child.detachedRecurrenceAt);
          expect(await visible(date.add(days: 2)), isNot(contains(parent.id)));
          final moved = await visible(date.add(days: 3));
          expect(moved.where((id) => id == child.id).length, deleted ? 0 : 1);
          await pull([]);
          expect((await markers(parent)).single, hidden);
          expect(await visible(date.add(days: 2)), isNot(contains(parent.id)));
          verifyNever(() => remote.getLatestTasks(force: true));
        },
      );
    }

    test('跨轮父任务迟到：deleted=$deleted，未补关系前不确认，父任务单独到达可重放', () async {
      final parent = series();
      final child = detached(parent, deleted: deleted);
      await pull([child]);
      expect(saved['tasks'], isNull);
      expect(await markers(parent), isEmpty);
      expect((await db.select(db.tasks).get()).single.id, child.id);
      // 即使服务端没有重发子记录，父任务也要重放本地已存关系。
      await pull([parent]);
      final hidden = (await markers(parent)).single;
      expect(saved['tasks'], {parent.id: '2'});
      expect(await visible(date.add(days: 2)), isNot(contains(parent.id)));
      await pull([child]);
      expect(saved['tasks'], {parent.id: '2', child.id: '2'});
      expect((await markers(parent)).single, hidden);
    });
  }

  test('旧版已经确认的分离及墓碑，空增量也会补偿一次，后续不改隐藏行', () async {
    final parent = series();
    final children = [
      detached(parent),
      detached(parent, deleted: true, id: 'deleted', day: 4),
    ];
    await db.into(db.tasks).insert(parent);
    for (final child in children) {
      await db.into(db.tasks).insert(child);
    }
    saved['tasks'] = {
      for (final t in [parent, ...children]) t.id: '2',
    };
    await pull([]);
    final hidden = await markers(parent);
    expect(hidden.length, 2);
    expect(saved['tasks']!.length, 3);
    expect(sp.getBool('detached_occurrence_repair_v1__existing__a'), isTrue);
    await pull([]);
    expect(await markers(parent), hidden);
  });

  test('补偿失败不确认父子版本、不标记完成；部分成功后重试仍幂等', () async {
    final parent = series();
    final child = detached(parent, deleted: true);
    final second = detached(parent, deleted: true, id: 'b-child', day: 4);
    await db.customStatement("""
      CREATE TRIGGER fail_hidden BEFORE INSERT ON task_occurrences
      WHEN (SELECT COUNT(*) FROM task_occurrences) > 0
      BEGIN SELECT RAISE(ABORT, 'hidden failure'); END
    """);
    await expectLater(pull([child, second, parent]), throwsA(isA<Exception>()));
    expect(saved['tasks'], isNull);
    expect(sp.getBool('detached_occurrence_repair_v1__existing__a'), isNull);
    final firstHidden = (await markers(parent)).single;
    await db.customStatement('DROP TRIGGER fail_hidden');
    await pull([child, second, parent]);
    expect(saved['tasks'], {child.id: '2', second.id: '2', parent.id: '2'});
    final hidden = await markers(parent);
    expect(hidden, hasLength(2));
    expect(hidden, contains(firstHidden));
    expect(
      hidden.map((o) => o.occurrenceAt),
      contains(second.detachedRecurrenceAt),
    );
  });

  test('本地父任务有待上传修改，远端旧父版本不覆盖，分离关系仍能补齐', () async {
    final parent = series();
    final local = parent.copyWith(title: '本地新标题');
    final child = detached(parent);
    await db.into(db.tasks).insert(local);
    await outbox.enqueue(
      tableName: 'tasks',
      recordId: parent.id,
      operation: 'update',
      payload: '{}',
    );
    await pull([child, parent]);
    expect(saved['tasks'], {child.id: '2'});
    expect(
      (await db.select(db.tasks).get())
          .firstWhere((t) => t.id == parent.id)
          .title,
      '本地新标题',
    );
    expect(
      (await markers(parent)).single.occurrenceAt,
      child.detachedRecurrenceAt,
    );
    expect(await outbox.getPending(), hasLength(1));
  });

  test('拉取期间本地分离日期修改并已上传，使用最新关系且不确认旧版本', () async {
    await sp.setBool('detached_occurrence_repair_v1__existing__a', true);
    final parent = series();
    final old = detached(parent);
    final current = old.copyWith(
      detachedRecurrenceAt: Value(date.add(days: 5)),
    );
    await db.into(db.tasks).insert(parent);
    await db.into(db.tasks).insert(old);
    final pending = Completer<List<Map<String, dynamic>>>();
    final entered = Completer<void>();
    when(() => remote.getLatestTasks(force: false)).thenAnswer((_) {
      entered.complete();
      return pending.future;
    });
    final request = repository.syncTasks();
    await entered.future;
    await db.into(db.tasks).insertOnConflictUpdate(current);
    await outbox.enqueue(
      tableName: 'tasks',
      recordId: old.id,
      operation: 'update',
      payload: '{}',
    );
    await outbox.markSynced((await outbox.getPending()).single.id);
    pending.complete(rows(tasks: [old.toJson(), parent.toJson()]));
    await request;
    expect(saved['tasks'], {parent.id: '2'});
    expect(
      (await markers(parent)).single.occurrenceAt,
      current.detachedRecurrenceAt,
    );
  });

  test('跨账号父任务不得建立隐藏标记或确认分离版本', () async {
    final parent = series().copyWith(userId: const Value('b'));
    await db.into(db.tasks).insert(parent);
    final child = detached(parent, deleted: true);
    await pull([child]);
    expect(await markers(parent), isEmpty);
    expect(saved['tasks'], isNull);
  });

  test('超过两批的已确认墓碑随父任务迟到补齐，后续增量保持隐藏行稳定', () async {
    final parent = series();
    final children = [
      for (var i = 0; i < 70; i++)
        detached(
          parent,
          deleted: true,
          id: 'child-${i.toString().padLeft(3, '0')}',
          day: i,
        ),
    ];
    // 模拟旧版已持久化墓碑、父任务始终未到达，升级补偿已完成。
    await sp.setBool('detached_occurrence_repair_v1__existing__a', true);
    for (final child in children) {
      await db.into(db.tasks).insert(child);
    }
    saved['tasks'] = {for (final child in children) child.id: '2'};
    var turns = 0;
    final timer = Timer.periodic(Duration.zero, (_) => turns++);
    try {
      await pull([parent]);
    } finally {
      timer.cancel();
    }
    final hidden = await markers(parent);
    expect(hidden.length, 70);
    expect(turns, greaterThan(2));
    expect(saved['tasks']!.length, 71);
    await pull([]);
    expect(await markers(parent), hidden);
  });

  test('补偿分页后换号，中断旧账号关系写入和版本确认', () async {
    final parent = series();
    final child = detached(parent, deleted: true);
    await db.into(db.tasks).insert(child);
    queries.afterSelect = (sql) {
      if (sql.contains('LIMIT 32') && sql.contains('detached_from_task_id')) {
        repository.account = 'b';
      }
    };
    await expectLater(pull([parent]), throwsStateError);
    expect(saved['tasks'], isNull);
    expect(await markers(parent), isEmpty);
    expect(sp.getBool('detached_occurrence_repair_v1__existing__a'), isNull);
  });

  test('隐藏行写入期间换号，分离记录和隐藏行原子回滚', () async {
    final parent = series();
    final child = detached(parent, deleted: true);
    await db.into(db.tasks).insert(parent);
    queries.afterInsert = (sql) {
      if (sql.contains('task_occurrences')) repository.account = 'b';
    };
    await expectLater(pull([child]), throwsStateError);
    expect(saved['tasks'], isNull);
    expect(await markers(parent), isEmpty);
    expect((await db.select(db.tasks).get()).map((t) => t.id), [parent.id]);
  });

  test('后台实例生成与墓碑补偿交错，旧计算不会复活隐藏日期', () async {
    final parent = series();
    final child = detached(parent, deleted: true);
    await db.into(db.tasks).insert(parent);
    final entered = Completer<void>();
    final resume = Completer<void>();
    final generator = TaskOccurrenceGenerator(
      computeBatch: (input) async {
        entered.complete();
        await resume.future;
        return generateTaskOccurrenceBatch(input);
      },
    );
    final api = DatabaseTaskApi(
      db: db,
      tagApi: tagApi,
      outboxApi: outbox,
      occurrenceGenerator: generator,
    );
    final preparing = api.preGenerateTaskOccurrences(fromDate: date);
    try {
      await entered.future;
      await pull([child]);
      final hidden = (await markers(parent)).single;
      resume.complete();
      await preparing;
      expect((await markers(parent)).single, hidden);
      expect(await visible(date.add(days: 2)), isNot(contains(parent.id)));
      expect(await visible(date.add(days: 1)), contains(parent.id));
    } finally {
      if (!resume.isCompleted) resume.complete();
      await preparing;
      await generator.close();
    }
  });

  test('分离与墓碑补偿保留独立标签和活动，原首页筛选正确', () async {
    final parent = series();
    final child = detached(parent);
    final tombstone = detached(parent, deleted: true, id: 'tombstone', day: 4);
    final tag = Tag(
      id: 'tag',
      userId: 'a',
      name: '标签',
      order: 0,
      level: 0,
      createdAt: date,
    );
    final link = TaskTag(
      id: 'link',
      userId: 'a',
      taskId: child.id,
      tagId: tag.id,
      createdAt: date,
    );
    final activity = TaskActivity(
      id: 'activity',
      userId: 'a',
      taskId: child.id,
      createdAt: date,
      completedAt: date,
    );
    when(() => remote.getLatestTasks(force: false)).thenAnswer(
      (_) async => rows(
        tasks: [child.toJson(), tombstone.toJson(), parent.toJson()],
        tags: [tag.toJson()],
        links: [link.toJson()],
        activities: [activity.toJson()],
      ),
    );
    await repository.syncTasks();
    expect(await visible(date.add(days: 3), tagId: tag.id), [child.id]);
    expect(await visible(date.add(days: 2), tagId: tag.id), isEmpty);
    expect(await visible(date.add(days: 4)), isNot(contains(parent.id)));
    expect((await db.select(db.taskTags).get()).single, link);
    expect((await db.select(db.taskActivities).get()).single, activity);
  });

  test('256 个系列分组边界之外的墓碑也能随父任务到达补齐', () async {
    await sp.setBool('detached_occurrence_repair_v1__existing__a', true);
    final parents = [for (var i = 0; i < 257; i++) series('parent-$i')];
    for (var i = 0; i < parents.length; i++) {
      await db
          .into(db.tasks)
          .insert(detached(parents[i], deleted: true, id: 'child-$i'));
    }
    await pull(parents);
    expect((await db.select(db.taskOccurrences).get()).length, 257);
    expect(saved['tasks']!.length, 257);
    expect((await markers(parents.last)).single.deletedAt, isNotNull);
  });

  test('旧墓碑已确认且父任务有本地保护，拒绝远端旧父版本仍补偿本地关系', () async {
    await sp.setBool('detached_occurrence_repair_v1__existing__a', true);
    final parent = series();
    final child = detached(parent, deleted: true);
    await db.into(db.tasks).insert(child);
    await db.into(db.tasks).insert(parent.copyWith(title: '本地父任务'));
    await outbox.enqueue(
      tableName: 'tasks',
      recordId: parent.id,
      operation: 'update',
      payload: '{}',
    );
    saved['tasks'] = {child.id: '2'};
    await pull([parent]);
    expect(saved['tasks'], {child.id: '2'});
    expect(
      (await markers(parent)).single.occurrenceAt,
      child.detachedRecurrenceAt,
    );
    expect(
      (await db.select(db.tasks).get())
          .firstWhere((t) => t.id == parent.id)
          .title,
      '本地父任务',
    );
  });

  test('主动强制全量也在父子关系补齐后确认版本', () async {
    final parent = series();
    final child = detached(parent, deleted: true);
    when(() => remote.getLatestTasks(force: true)).thenAnswer(
      (_) async => rows(tasks: [child.toJson(), parent.toJson()]),
    );
    await repository.syncTasks(force: true);
    expect(saved['tasks'], {child.id: '2', parent.id: '2'});
    expect(
      (await markers(parent)).single.occurrenceAt,
      child.detachedRecurrenceAt,
    );
    verify(() => remote.getLatestTasks(force: true)).called(1);
  });

  test('旧时间游标入口也不跳过未补关系的墓碑，补齐后才推进', () async {
    final parent = series();
    final child = detached(
      parent,
      deleted: true,
    ).copyWith(updatedAt: Value(date));
    when(() => remote.getLatestTasks(force: false)).thenAnswer(
      (_) async => [child.toJson()],
    );
    await repository.syncTasks();
    expect(sp.getInt(SupabaseTaskApi.cursorKey('a')), isNull);
    repository = freshRepository();
    when(() => remote.getLatestTasks(force: false)).thenAnswer(
      (_) async => [child.toJson(), parent.toJson()],
    );
    await repository.syncTasks();
    expect(sp.getInt(SupabaseTaskApi.cursorKey('a')), isNotNull);
    expect(
      (await markers(parent)).single.occurrenceAt,
      child.detachedRecurrenceAt,
    );
  });
}
