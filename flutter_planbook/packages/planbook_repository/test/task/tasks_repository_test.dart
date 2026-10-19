import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_repository/task/tasks_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_planbook_api/task/supabase_task_api.dart';

class _MockSupabaseTaskApi extends Mock implements SupabaseTaskApi {}

Task _testTask({
  required String id,
  required String title,
  int layer = 0,
  int childCount = 0,
  int order = 0,
  bool isAllDay = false,
  List<EventAlarm> alarms = const [],
  TaskPriority? priority,
  Jiffy? startAt,
  Jiffy? dueAt,
}) {
  return Task(
    id: id,
    title: title,
    layer: layer,
    childCount: childCount,
    order: order,
    isAllDay: isAllDay,
    alarms: alarms,
    priority: priority,
    startAt: startAt,
    dueAt: dueAt,
    createdAt: Jiffy.now(),
  );
}

void main() {
  group('TasksRepository', () {
    late AppDatabase db;
    late TasksRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final outboxApi = OutboxApi(db: db);
      final tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
      repository = TasksRepository(
        sp: sp,
        tagApi: tagApi,
        db: db,
        outboxApi: outboxApi,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('can be instantiated', () {
      expect(repository, isNotNull);
    });

    test('getTotalCount returns 0 when no tasks', () async {
      final count = await repository.getTotalCount();
      expect(count, 0);
    });

    test('prepareForHome 只生成本地缓存，不调用远端任务 API', () async {
      final remote = _MockSupabaseTaskApi();
      final sp = await SharedPreferences.getInstance();
      final outbox = OutboxApi(db: db);
      final localOnly = TasksRepository(
        sp: sp,
        tagApi: DatabaseTagApi(db: db, outboxApi: outbox),
        db: db,
        outboxApi: outbox,
        supabaseTaskApi: remote,
      );
      final date = Jiffy.parse('2026-10-17');
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              title: '启动准备任务',
              startAt: Value(date),
              recurrenceRule: const Value(
                RecurrenceRule(frequency: RecurrenceFrequency.daily),
              ),
            ),
          );

      await localOnly.prepareForHome(date: date);

      expect(await db.select(db.taskOccurrences).get(), isNotEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      verifyZeroInteractions(remote);
    });

    test('create and getTaskEntityById', () async {
      final task = _testTask(id: 'task-1', title: 'Test Task');

      await repository.create(task: task);

      final entity = await repository.getTaskEntityById('task-1');
      expect(entity, isNotNull);
      expect(entity!.task.id, 'task-1');
      expect(entity.task.title, 'Test Task');
    });

    test('update task title', () async {
      final task = _testTask(id: 'task-2', title: 'Old Title');
      await repository.create(task: task);

      final updated = task.copyWith(title: 'New Title');
      await repository.update(task: updated);

      final entity = await repository.getTaskEntityById('task-2');
      expect(entity!.task.title, 'New Title');
    });

    test('deleteTaskById soft-deletes task', () async {
      final task = _testTask(id: 'task-3', title: 'To Delete');
      await repository.create(task: task);

      await repository.deleteTaskById('task-3');

      final entity = await repository.getTaskEntityById('task-3');
      expect(entity, isNull);
    });

    test('deleteRecurringTask thisEventOnly soft-deletes occurrence', () async {
      final now = Jiffy.now().startOf(Unit.day);
      final task =
          _testTask(
            id: 'recurring-delete-one',
            title: 'Recurring',
            startAt: now,
          ).copyWith(
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          );
      await repository.create(task: task);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final occurrenceAt = now.add(days: 2);
      final entity = (await repository.getTaskEntityById(
        task.id,
        occurrenceAt: occurrenceAt,
      ))!;
      await repository.deleteRecurringTask(
        entity: entity,
        mode: RecurringTaskDeleteMode.thisEventOnly,
        occurrenceAt: occurrenceAt,
      );

      final occurrences =
          await (db.select(db.taskOccurrences)..where(
                (to) => to.taskId.equals(task.id),
              ))
              .get();
      final targetOccurrences = occurrences
          .where(
            (o) => o.occurrenceAt.isSame(occurrenceAt, unit: Unit.day),
          )
          .toList();
      expect(targetOccurrences, hasLength(1));
      expect(targetOccurrences.first.deletedAt, isNotNull);

      final detached =
          await (db.select(db.tasks)..where(
                (t) => t.detachedFromTaskId.equals(task.id),
              ))
              .get();
      expect(detached, hasLength(1));
      expect(detached.first.deletedAt, isNotNull);
      expect(detached.first.detachedReason, DetachedReason.deleted);
    });

    test(
      'syncTasks soft-deletes parent occurrence for detached task',
      () async {
        SharedPreferences.setMockInitialValues({});
        final sp = await SharedPreferences.getInstance();
        final outboxApi = OutboxApi(db: db);
        final tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
        final mockSupabase = _MockSupabaseTaskApi();
        final syncRepository = TasksRepository(
          sp: sp,
          tagApi: tagApi,
          db: db,
          outboxApi: outboxApi,
          supabaseTaskApi: mockSupabase,
        );

        final now = Jiffy.now().startOf(Unit.day);
        final parent =
            _testTask(
              id: 'parent-sync-detach',
              title: 'Parent',
              startAt: now,
            ).copyWith(
              recurrenceRule: const Value(
                RecurrenceRule(frequency: RecurrenceFrequency.daily),
              ),
            );
        await syncRepository.create(task: parent);

        final occurrenceAt = now.add(days: 1);
        final detached = Task(
          id: 'detached-sync-1',
          title: 'Detached',
          layer: 0,
          childCount: 0,
          order: 0,
          isAllDay: false,
          alarms: const [],
          detachedFromTaskId: parent.id,
          detachedRecurrenceAt: occurrenceAt,
          detachedReason: DetachedReason.deleted,
          deletedAt: Jiffy.now(),
          createdAt: Jiffy.now(),
        );

        when(
          () => mockSupabase.getLatestTasks(force: any(named: 'force')),
        ).thenAnswer((_) async => [detached.toJson()]);

        await syncRepository.syncTasks(force: true);

        final occurrences =
            await (db.select(db.taskOccurrences)..where(
                  (to) => to.taskId.equals(parent.id),
                ))
                .get();
        final target = occurrences.where(
          (o) => o.occurrenceAt.isSame(occurrenceAt, unit: Unit.day),
        );
        expect(target, hasLength(1));
        expect(target.first.deletedAt, isNotNull);
      },
    );

    for (final alreadySynced in [false, true]) {
      test(
        'syncTasks removes cached occurrences after recurrence end '
        '(already synced: $alreadySynced)',
        () async {
          final sp = await SharedPreferences.getInstance();
          final outboxApi = OutboxApi(db: db);
          final tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
          final taskApi = DatabaseTaskApi(
            db: db,
            tagApi: tagApi,
            outboxApi: outboxApi,
          );
          final todayApi = DatabaseTaskTodayApi(
            db: db,
            tagApi: tagApi,
            outboxApi: outboxApi,
          );
          final mockSupabase = _MockSupabaseTaskApi();
          final syncRepository = TasksRepository(
            sp: sp,
            tagApi: tagApi,
            db: db,
            outboxApi: outboxApi,
            supabaseTaskApi: mockSupabase,
          );
          final start = Jiffy.parse('2026-08-27');
          final end = Jiffy.parse('2026-08-29');
          final afterEnd = Jiffy.parse('2026-08-30');
          final task =
              _testTask(
                id: 'sync-ended-series',
                title: '手机创建的重复任务',
                startAt: start,
              ).copyWith(
                recurrenceRule: const Value(
                  RecurrenceRule(frequency: RecurrenceFrequency.daily),
                ),
              );
          // 模拟 iPad 在手机设置结束日期之前已生成未来实例。
          await db.into(db.tasks).insert(task);
          await taskApi.preGenerateTaskOccurrences(fromDate: start);
          expect(await todayApi.getTodayTaskCount(date: afterEnd).first, 1);
          final hiddenDate = start.add(days: 1);
          await (db.update(db.taskOccurrences)..where(
                (o) => o.occurrenceAt.equals(hiddenDate.dateTime),
              ))
              .write(TaskOccurrencesCompanion(deletedAt: Value(start)));
          final completion = TaskActivity(
            id: 'completed-before-end',
            taskId: task.id,
            occurrenceAt: start,
            completedAt: start,
            createdAt: start,
          );
          await db.into(db.taskActivities).insert(completion);

          final endedTask = task.copyWith(
            recurrenceRule: Value(
              RecurrenceRule.withEndAt(
                frequency: RecurrenceFrequency.daily,
                endAt: end,
              ),
            ),
          );
          if (alreadySynced) {
            // 模拟旧版本已同步规则，但留下了过期实例的状态。
            await db.into(db.tasks).insertOnConflictUpdate(endedTask);
          }
          when(
            () => mockSupabase.getLatestTasks(force: any(named: 'force')),
          ).thenAnswer((_) async => [endedTask.toJson()]);

          await syncRepository.syncTasks(force: alreadySynced);

          final entity = await syncRepository.getTaskEntityById(task.id);
          expect(entity!.task.recurrenceRule!.recurrenceEnd!.endAt, end);
          expect(await todayApi.getTodayTaskCount(date: afterEnd).first, 0);
          expect(
            await todayApi.getAllTodayTaskEntities(day: afterEnd).first,
            isEmpty,
          );
          // 截止当天仍应保留。
          expect(await todayApi.getTodayTaskCount(date: end).first, 1);
          final cached = await db.select(db.taskOccurrences).get();
          expect(
            cached.where((o) => o.occurrenceAt.isAfter(end, unit: Unit.day)),
            isEmpty,
          );
          expect(await todayApi.getTodayTaskCount(date: hiddenDate).first, 0);
          expect(
            cached.singleWhere((o) => o.occurrenceAt == hiddenDate).deletedAt,
            start,
          );
          expect(
            await todayApi
                .getTodayTaskCount(date: start, isCompleted: true)
                .first,
            1,
          );
          expect(await db.select(db.taskActivities).getSingle(), completion);
          expect(await outboxApi.getPending(), isEmpty);
        },
      );
    }

    test('deleteRecurringTask thisAndFutureEvents ends recurrence', () async {
      final now = Jiffy.now().startOf(Unit.day);
      final task =
          _testTask(
            id: 'recurring-delete-future',
            title: 'Recurring',
            startAt: now,
          ).copyWith(
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          );
      await repository.create(task: task);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final occurrenceAt = now.add(days: 3);
      final entity = (await repository.getTaskEntityById(task.id))!;
      final updatedTask = await repository.deleteRecurringTask(
        entity: entity,
        mode: RecurringTaskDeleteMode.thisAndFutureEvents,
        occurrenceAt: occurrenceAt,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(updatedTask, isNotNull);
      expect(updatedTask!.recurrenceRule!.recurrenceEnd, isNotNull);
    });

    test('deleteRecurringTask allEvents deletes the task', () async {
      final now = Jiffy.now().startOf(Unit.day);
      final task =
          _testTask(
            id: 'recurring-delete-all',
            title: 'Recurring',
            startAt: now,
          ).copyWith(
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          );
      await repository.create(task: task);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final entity = (await repository.getTaskEntityById(task.id))!;
      await repository.deleteRecurringTask(
        entity: entity,
        mode: RecurringTaskDeleteMode.allEvents,
      );

      final fetched = await repository.getTaskEntityById(task.id);
      expect(fetched, isNull);
    });

    test('getStartDate returns null when no tasks', () async {
      final date = await repository.getStartDate();
      expect(date, isNull);
    });

    test('getStartDate returns earliest task createdAt', () async {
      final createdAt = Jiffy.now().subtract(days: 10);
      final task = _testTask(
        id: 'task-4',
        title: 'Early Task',
      ).copyWith(createdAt: createdAt);
      await repository.create(task: task);

      final date = await repository.getStartDate();
      expect(date, isNotNull);
      expect(date!.year, createdAt.year);
      expect(date.month, createdAt.month);
      expect(date.date, createdAt.date);
    });

    test('create with children sets parent and layer', () async {
      final parent = _testTask(id: 'parent-1', title: 'Parent');
      final child = TaskEntity(
        task: _testTask(id: 'child-1', title: 'Child'),
      );

      await repository.create(task: parent, children: [child]);

      final parentEntity = await repository.getTaskEntityById('parent-1');
      expect(parentEntity!.task.childCount, 1);

      final childEntity = await repository.getTaskEntityById('child-1');
      expect(childEntity!.task.parentId, 'parent-1');
      expect(childEntity.task.layer, 1);
    });

    test('delayTask preserves completion for recurring task', () async {
      final now = Jiffy.now().startOf(Unit.day);
      final task =
          _testTask(
            id: 'recurring-completed',
            title: 'Recurring Completed',
            startAt: now,
          ).copyWith(
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          );
      await repository.create(task: task);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final occurrenceAt = now.add(days: 2);
      await db
          .into(db.taskActivities)
          .insert(
            TaskActivitiesCompanion.insert(
              taskId: const Value('recurring-completed'),
              occurrenceAt: Value(occurrenceAt),
              completedAt: Value(Jiffy.now()),
              activityType: const Value('completed'),
            ),
          );

      final entity = await repository.getTaskEntityById(
        'recurring-completed',
        occurrenceAt: occurrenceAt,
      );
      expect(entity, isNotNull);
      expect(entity!.isCompleted, isTrue);

      final delayed = await repository.delayTask(
        entity: entity,
        delayTo: now.add(days: 3),
      );
      expect(delayed, isNotNull);
      expect(delayed!.isCompleted, isTrue);

      final originalActivity =
          await (db.select(db.taskActivities)
                ..where((ta) => ta.taskId.equals('recurring-completed'))
                ..where(
                  (ta) => ta.occurrenceAt.equals(occurrenceAt.dateTime),
                ))
              .getSingleOrNull();
      expect(originalActivity, isNotNull);
      expect(originalActivity!.deletedAt, isNotNull);
    });

    test('updateTaskPriority changes priority', () async {
      final task = _testTask(
        id: 'task-5',
        title: 'Priority Task',
        priority: TaskPriority.none,
      );
      await repository.create(task: task);

      final entity = (await repository.getTaskEntityById('task-5'))!;
      await repository.updateTaskPriority(entity, TaskPriority.high);

      final updated = await repository.getTaskEntityById('task-5');
      expect(updated!.task.priority, TaskPriority.high);
    });
  });
}
