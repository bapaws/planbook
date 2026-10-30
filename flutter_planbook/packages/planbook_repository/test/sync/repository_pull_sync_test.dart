// Mock 的命名参数需与生产调用一致，显式匹配 force: false。
// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';

import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart'
    show
        ApplyInterceptor,
        BatchedStatements,
        QueryExecutor,
        QueryInterceptor,
        Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:planbook_repository/sync/merge_remote_rows.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_planbook_api/note/supabase_note_api.dart';
import 'package:supabase_planbook_api/task/supabase_task_api.dart';

class _Tasks extends Mock implements SupabaseTaskApi {}

class _Notes extends Mock implements SupabaseNoteApi {}

class _Writes extends QueryInterceptor {
  int batches = 0;
  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    batches++;
    return executor.runBatched(statements);
  }
}

void main() {
  late AppDatabase db;
  late SharedPreferences sp;
  late DatabaseTagApi tags;
  late OutboxApi outbox;
  late _Tasks remote;
  late TasksRepository tasks;
  late _Writes writes;
  final date = Jiffy.parse('2026-10-18T09:00:00');

  Task task(String id) => Task(
    id: id,
    title: id,
    layer: 0,
    childCount: 0,
    order: 0,
    isAllDay: false,
    alarms: const [],
    createdAt: date,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sp = await SharedPreferences.getInstance();
    writes = _Writes();
    db = AppDatabase.forTesting(NativeDatabase.memory().interceptWith(writes));
    outbox = OutboxApi(db: db);
    tags = DatabaseTagApi(db: db, outboxApi: outbox);
    remote = _Tasks();
    tasks = TasksRepository(
      sp: sp,
      db: db,
      tagApi: tags,
      outboxApi: outbox,
      supabaseTaskApi: remote,
    );
  });
  tearDown(() => db.close());

  test('Repository 合并远端请求且等本地数据真正落库后返回', () async {
    final response = Completer<List<Map<String, dynamic>>>();
    final entered = Completer<void>();
    when(() => remote.getLatestTasks(force: false)).thenAnswer((_) {
      entered.complete();
      return response.future;
    });
    final first = tasks.syncTasks();
    await entered.future;
    final second = tasks.syncTasks();
    expect(identical(first, second), isTrue);
    expect(sp.getInt(SupabaseTaskApi.cursorKey(null)), isNull);
    response.complete([task('a').toJson()]);
    await Future.wait([first, second]);
    expect((await db.select(db.tasks).get()).single.id, 'a');
    expect(
      sp.getInt(SupabaseTaskApi.cursorKey(null)),
      date.dateTime.millisecondsSinceEpoch,
    );
    verify(() => remote.getLatestTasks(force: false)).called(1);
  });

  test('分条提交后中途失败不推进游标，重试可安全重放已提交记录', () async {
    when(() => remote.getLatestTasks(force: true)).thenAnswer(
      (_) async => [
        task('a').toJson(),
        {'id': 'invalid'},
      ],
    );
    await expectLater(tasks.syncTasks(force: true), throwsA(anything));
    expect((await db.select(db.tasks).get()).single.id, 'a');
    expect(sp.getInt(SupabaseTaskApi.cursorKey(null)), isNull);
    when(
      () => remote.getLatestTasks(force: true),
    ).thenAnswer((_) async => [task('a').toJson(), task('b').toJson()]);
    await tasks.syncTasks(force: true);
    expect(await db.select(db.tasks).get(), hasLength(2));
    expect(sp.getInt(SupabaseTaskApi.cursorKey(null)), isNotNull);
  });

  test('本地 Outbox 保护未上传任务，不被远端覆盖', () async {
    await tasks.create(task: task('a').copyWith(title: '本地修改'));
    when(
      () => remote.getLatestTasks(force: true),
    ).thenAnswer((_) async => [task('a').copyWith(title: '远端旧版').toJson()]);
    await tasks.syncTasks(force: true);
    expect((await db.select(db.tasks).get()).single.title, '本地修改');
  });

  test('笔记同步同样合并请求，失败不保存游标且允许立即重试', () async {
    final api = _Notes();
    final repository = NotesRepository(
      sp: sp,
      db: db,
      tagApi: tags,
      outboxApi: outbox,
      supabaseNoteApi: api,
    );
    when(() => api.getLatestNotes(force: false)).thenAnswer(
      (_) async => [
        {'id': 'invalid'},
      ],
    );
    await expectLater(repository.syncNotes(), throwsA(anything));
    expect(sp.getInt(SupabaseNoteApi.cursorKey(null)), isNull);
    final note = Note(id: 'n', title: '笔记', images: const [], createdAt: date);
    when(
      () => api.getLatestNotes(force: false),
    ).thenAnswer((_) async => [note.toJson()]);
    await repository.syncNotes();
    expect((await db.select(db.notes).get()).single.id, 'n');
    expect(sp.getInt(SupabaseNoteApi.cursorKey(null)), isNotNull);
  });

  test('提醒迁移覆盖单次和重复任务，排除已完成与其他账号任务', () async {
    final single = task(
      'single',
    ).copyWith(startAt: Value(date), alarms: [EventAlarm.relative(0)]);
    final recurring = single.copyWith(
      id: 'recurring',
      recurrenceRule: const Value(
        RecurrenceRule(frequency: RecurrenceFrequency.daily),
      ),
    );
    await db.into(db.tasks).insert(single);
    await db.into(db.tasks).insert(recurring);
    await db
        .into(db.tasks)
        .insert(single.copyWith(id: 'other', userId: const Value('other')));
    expect((await tasks.getTasksForAlarms()).map((t) => t.id), [
      'single',
      'recurring',
    ]);
    await db
        .into(db.taskActivities)
        .insert(
          TaskActivity(
            id: 'done',
            taskId: 'single',
            completedAt: date,
            createdAt: date,
          ),
        );
    expect((await tasks.getTasksForAlarms()).map((t) => t.id), ['recurring']);
    expect(await tasks.getTaskForAlarm('single'), isNull);
    expect(await tasks.getTaskForAlarm('other'), isNull);
  });

  test('账号游标键隔离，不复用旧全局游标', () {
    expect(
      SupabaseTaskApi.cursorKey('a'),
      isNot(SupabaseTaskApi.cursorKey('b')),
    );
    expect(
      SupabaseTaskApi.cursorKey('a'),
      isNot(SupabaseTaskApi.kLastGetTasksTimestamp),
    );
    expect(
      SupabaseNoteApi.cursorKey('a'),
      isNot(SupabaseNoteApi.cursorKey('b')),
    );
  });

  test('关联批量合并跨参数批次，内容未变时不重复写入或唤醒订阅', () async {
    await db.into(db.tasks).insert(task('parent'));
    final rows = List.generate(
      805,
      (i) => TaskActivity(
        id: 'activity-$i',
        taskId: 'parent',
        createdAt: date,
        completedAt: date,
      ),
    );
    Future<void> merge() => db.transaction(
      () => mergeRemoteRows(
        db: db,
        table: db.taskActivities,
        idColumn: db.taskActivities.id,
        rows: rows,
      ),
    );
    await merge();
    final before = writes.batches;
    await merge();
    expect(writes.batches, before);
    expect(await db.select(db.taskActivities).get(), hasLength(805));
  });

  test('关联本身的 Outbox 修改也必须保留，不能被父任务同步覆盖', () async {
    await db.into(db.tasks).insert(task('parent'));
    final local = TaskActivity(
      id: 'activity',
      taskId: 'parent',
      createdAt: date,
      completedAt: date,
    );
    await db.into(db.taskActivities).insert(local);
    await outbox.enqueue(
      tableName: 'task_activities',
      recordId: local.id,
      operation: 'update',
      payload: '{}',
    );
    await db.transaction(
      () => mergeRemoteRows(
        db: db,
        table: db.taskActivities,
        idColumn: db.taskActivities.id,
        rows: [local.copyWith(completedAt: const Value(null))],
      ),
    );
    expect((await db.select(db.taskActivities).get()).single.completedAt, date);
  });
}
