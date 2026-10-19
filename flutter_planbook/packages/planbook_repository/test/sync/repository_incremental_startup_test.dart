// 测试显式区分普通增量和强制全量入口。
// ignore_for_file: avoid_redundant_argument_values
import 'dart:async';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_planbook_api/sync/remote_table_pull.dart';
import 'package:supabase_planbook_api/task/supabase_task_api.dart';

class _Remote extends Mock implements SupabaseTaskApi {}

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
  late SharedPreferences sp;
  late OutboxApi outbox;
  late DatabaseTagApi tagApi;
  late _Remote remote;
  late _AccountTasks repository;
  late Map<String, Map<String, String>> saved;
  final date = Jiffy.parse('2026-10-18');
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
  }) {
    final tables = {
      'tasks': tasks,
      'task_activities': activities,
      'tags': <Map<String, dynamic>>[],
      'task_tags': <Map<String, dynamic>>[],
    };
    return RemoteSyncRows({
      for (final entry in tables.entries)
        entry.key: RemoteTableBatch(
          table: entry.key,
          rows: [
            for (final row in entry.value) {...row, '_sync_version': '2'},
          ],
          inventory: entry.value.map((r) => r['id']! as String).toSet(),
          confirmMissing: (ids) async => ids.toSet(),
          previous: const {},
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
    db = AppDatabase.forTesting(NativeDatabase.memory());
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
  tearDown(() => db.close());

  test('任务增量为空也应用活动增量，不推进旧时间游标', () async {
    await db.into(db.tasks).insert(task('parent'));
    final activity = TaskActivity(
      id: 'done',
      userId: 'a',
      taskId: 'parent',
      createdAt: date,
      completedAt: date,
    );
    when(
      () => remote.getLatestTasks(force: false),
    ).thenAnswer((_) async => rows(activities: [activity.toJson()]));
    await repository.syncTasks();
    expect((await db.select(db.taskActivities).get()).single.completedAt, date);
    expect(saved['task_activities'], {'done': '2'});
    expect(sp.getInt(SupabaseTaskApi.cursorKey('a')), isNull);
  });

  test('远端快照取得期间本地修改已上传也不能被覆盖，版本保持未确认', () async {
    final original = task('parent');
    await db.into(db.tasks).insert(original);
    final pending = Completer<List<Map<String, dynamic>>>();
    final entered = Completer<void>();
    when(() => remote.getLatestTasks(force: false)).thenAnswer((_) {
      entered.complete();
      return pending.future;
    });
    final pulling = repository.syncTasks();
    await entered.future;
    await (db.update(db.tasks)..where((t) => t.id.equals('parent'))).write(
      const TasksCompanion(title: Value('本地新版本')),
    );
    await outbox.enqueue(
      tableName: 'tasks',
      recordId: 'parent',
      operation: 'update',
      payload: '{}',
    );
    await outbox.markSynced((await outbox.getPending()).single.id);
    pending.complete(rows(tasks: [original.toJson()]));
    await pulling;
    expect((await db.select(db.tasks).get()).single.title, '本地新版本');
    expect(saved['tasks'], isNull);
  });

  test('中途合并失败不确认任务版本；换号返回不落库', () async {
    when(() => remote.getLatestTasks(force: false)).thenAnswer(
      (_) async => rows(
        tasks: [
          task('ok').toJson(),
          task('bad').copyWith(userId: const Value('b')).toJson(),
        ],
      ),
    );
    await expectLater(repository.syncTasks(), throwsStateError);
    expect(saved['tasks'], isNull);
    final pending = Completer<List<Map<String, dynamic>>>();
    final entered = Completer<void>();
    when(() => remote.getLatestTasks(force: false)).thenAnswer((_) {
      entered.complete();
      return pending.future;
    });
    final request = repository.syncTasks();
    await entered.future;
    repository.account = 'b';
    pending.complete(rows(tasks: [task('old-account').toJson()]));
    await expectLater(request, throwsStateError);
    expect((await db.select(db.tasks).get()).map((r) => r.id), ['ok']);
  });

  test('旧实例修复先于网络执行，离线成功后留独立标记且不再依赖全量', () async {
    final original = task('legacy');
    await db.into(db.tasks).insert(original);
    await db
        .into(db.taskOccurrences)
        .insert(
          TaskOccurrencesCompanion.insert(
            taskId: const Value('legacy'),
            occurrenceAt: date,
            startAt: Value(date),
          ),
        );
    when(() => remote.getLatestTasks(force: false)).thenAnswer((_) async {
      expect(await db.select(db.taskOccurrences).get(), isEmpty);
      throw StateError('offline');
    });
    await expectLater(repository.syncTasks(), throwsStateError);
    expect(sp.getBool('occurrence_repair_v1__existing__a'), isTrue);
    when(
      () => remote.getLatestTasks(force: false),
    ).thenAnswer((_) async => rows());
    await repository.syncTasks();
    verifyNever(() => remote.getLatestTasks(force: true));
    expect(
      (await db.select(db.tasks).get()).single.toJson(),
      original.toJson(),
    );
  });
}
