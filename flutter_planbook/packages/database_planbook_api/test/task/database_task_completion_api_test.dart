import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:database_planbook_api/task/database_task_completion_api.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:uuid/uuid.dart';

import '../test_helper.dart';

Task _sampleTask({
  String? id,
  String? userId,
  String title = 'Test Task',
  String? parentId,
  int layer = 0,
  int childCount = 0,
  int order = 0,
  Jiffy? startAt,
  Jiffy? endAt,
  bool isAllDay = false,
  Jiffy? dueAt,
  RecurrenceRule? recurrenceRule,
  List<EventAlarm> alarms = const [],
  TaskPriority? priority,
  Jiffy? createdAt,
}) {
  return Task(
    id: id ?? const Uuid().v4(),
    userId: userId,
    title: title,
    parentId: parentId,
    layer: layer,
    childCount: childCount,
    order: order,
    startAt: startAt,
    endAt: endAt,
    isAllDay: isAllDay,
    dueAt: dueAt,
    recurrenceRule: recurrenceRule,
    alarms: alarms,
    priority: priority,
    createdAt: createdAt ?? Jiffy.now(),
  );
}

void main() {
  group('DatabaseTaskCompletionApi', () {
    late AppDatabase db;
    late OutboxApi outboxApi;
    late DatabaseTagApi tagApi;
    late DatabaseTaskCompletionApi api;
    late DatabaseTaskApi baseApi;

    setUp(() {
      db = createTestDatabase();
      outboxApi = OutboxApi(db: db);
      tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
      api = DatabaseTaskCompletionApi(
        db: db,
        tagApi: tagApi,
        outboxApi: outboxApi,
      );
      baseApi = DatabaseTaskApi(
        db: db,
        tagApi: tagApi,
        outboxApi: outboxApi,
      );
    });

    tearDown(() async {
      await db.close();
    });

    group('completeTaskByActivities', () {
      test('inserts activities and enqueues outbox records', () async {
        final activity1 = TaskActivity(
          id: const Uuid().v4(),
          taskId: 'task-1',
          completedAt: Jiffy.now(),
          activityType: 'completed',
          createdAt: Jiffy.now(),
        );
        final activity2 = TaskActivity(
          id: const Uuid().v4(),
          taskId: 'task-2',
          completedAt: Jiffy.now(),
          activityType: 'completed',
          createdAt: Jiffy.now(),
        );

        await api.completeTaskByActivities([activity1, activity2]);

        final stored = await db.select(db.taskActivities).get();
        expect(stored, hasLength(2));

        final outbox = await db.select(db.syncOutbox).get();
        expect(outbox, hasLength(2));
        expect(
          outbox.map((o) => o.recordId),
          containsAll([activity1.id, activity2.id]),
        );
        expect(outbox.every((o) => o.targetTable == 'task_activities'), isTrue);
        expect(outbox.every((o) => o.operation == 'insert'), isTrue);
      });

      test('does nothing for empty list', () async {
        await api.completeTaskByActivities([]);

        final stored = await db.select(db.taskActivities).get();
        expect(stored, isEmpty);

        final outbox = await db.select(db.syncOutbox).get();
        expect(outbox, isEmpty);
      });

      test('updates existing activity on conflict', () async {
        final id = const Uuid().v4();
        final activity = TaskActivity(
          id: id,
          taskId: 'task-1',
          completedAt: Jiffy.now(),
          activityType: 'completed',
          createdAt: Jiffy.now(),
        );
        await api.completeTaskByActivities([activity]);

        final updatedActivity = activity.copyWith(
          activityType: const Value('skipped'),
        );
        await api.completeTaskByActivities([updatedActivity]);

        final stored = await db.select(db.taskActivities).get();
        expect(stored, hasLength(1));
        expect(stored.first.activityType, 'skipped');
      });
    });

    group('completeTask', () {
      test('returns completion activity for non-recurring task', () async {
        final task = _sampleTask();
        await baseApi.create(task: task);

        final entity = await baseApi.getTaskEntityById(task.id);
        expect(entity, isNotNull);

        final activities = await api.completeTask(entity!);
        expect(activities, hasLength(1));
        expect(activities.first.taskId, task.id);
        expect(activities.first.completedAt, isNotNull);
        expect(activities.first.activityType, 'completed');
        expect(activities.first.occurrenceAt, isNull);
      });

      test(
        'returns completion activity with occurrenceAt for recurring task',
        () async {
          final now = Jiffy.now().startOf(Unit.day);
          final task = _sampleTask(
            startAt: now,
            recurrenceRule: RecurrenceRule(
              frequency: RecurrenceFrequency.daily,
            ),
          );
          await baseApi.create(task: task);

          final entity = await baseApi.getTaskEntityById(task.id);
          expect(entity, isNotNull);

          final occurrenceAt = now.add(days: 1);
          final activities = await api.completeTask(
            entity!,
            occurrenceAt: occurrenceAt,
          );
          expect(activities, hasLength(1));
          expect(activities.first.occurrenceAt, isNotNull);
        },
      );

      test('cascades to parent when all children are completed', () async {
        final parentTask = _sampleTask();
        final childTask1 = _sampleTask(
          title: 'Child 1',
          parentId: parentTask.id,
          layer: 1,
        );
        final childTask2 = _sampleTask(
          title: 'Child 2',
          parentId: parentTask.id,
          layer: 1,
        );

        await baseApi.create(
          task: parentTask,
          children: [childTask1, childTask2],
        );

        // 完成第一个子任务
        final childEntity1 = await baseApi.getTaskEntityById(childTask1.id);
        final activities1 = await api.completeTask(childEntity1!);
        await api.completeTaskByActivities(activities1);

        // 父任务不应该被级联完成（还有一个子任务未完成）
        final parentEntity1 = await baseApi.getTaskEntityById(parentTask.id);
        expect(parentEntity1!.isCompleted, isFalse);

        // 完成第二个子任务
        final childEntity2 = await baseApi.getTaskEntityById(childTask2.id);
        final activities2 = await api.completeTask(childEntity2!);
        await api.completeTaskByActivities(activities2);

        // 父任务应该被级联完成
        final parentEntity2 = await baseApi.getTaskEntityById(parentTask.id);
        expect(parentEntity2!.isCompleted, isTrue);
      });

      test('deletes completion activity when toggling off', () async {
        final task = _sampleTask();
        await baseApi.create(task: task);

        final entity = await baseApi.getTaskEntityById(task.id);
        expect(entity, isNotNull);

        // 完成
        final activities1 = await api.completeTask(entity!);
        await api.completeTaskByActivities(activities1);

        final completedEntity = await baseApi.getTaskEntityById(task.id);
        expect(completedEntity!.isCompleted, isTrue);

        // 取消完成
        final activities2 = await api.completeTask(completedEntity);
        await api.completeTaskByActivities(activities2);

        final uncompletedEntity = await baseApi.getTaskEntityById(task.id);
        expect(uncompletedEntity!.isCompleted, isFalse);
      });

      test(
        'cascades uncompletion to parent when child is toggled off',
        () async {
          final parentTask = _sampleTask();
          final childTask = _sampleTask(
            title: 'Child',
            parentId: parentTask.id,
            layer: 1,
          );

          await baseApi.create(task: parentTask, children: [childTask]);

          // 完成子任务 → 父任务自动完成
          final childEntity = await baseApi.getTaskEntityById(childTask.id);
          final activities1 = await api.completeTask(childEntity!);
          await api.completeTaskByActivities(activities1);

          final parentEntity1 = await baseApi.getTaskEntityById(parentTask.id);
          expect(parentEntity1!.isCompleted, isTrue);

          // 取消完成子任务 → 父任务自动取消完成
          final completedChild = await baseApi.getTaskEntityById(childTask.id);
          final activities2 = await api.completeTask(completedChild!);
          await api.completeTaskByActivities(activities2);

          final parentEntity2 = await baseApi.getTaskEntityById(parentTask.id);
          expect(parentEntity2!.isCompleted, isFalse);
        },
      );
    });

    group('getCompletedTaskCount / getCompletedTaskEntities', () {
      test('counts completed tasks for given date', () async {
        final today = Jiffy.now().startOf(Unit.day);
        final task = _sampleTask();
        await baseApi.create(task: task);

        final entity = await baseApi.getTaskEntityById(task.id);
        final activities = await api.completeTask(entity!);
        await api.completeTaskByActivities(activities);

        final stream = api.getCompletedTaskCount(
          date: today,
          userId: null,
        );

        final count = await stream.first;
        expect(count, 1);
      });

      test('counts completed tasks filtered by priority', () async {
        final today = Jiffy.now().startOf(Unit.day);
        final task1 = _sampleTask(priority: TaskPriority.high);
        final task2 = _sampleTask(priority: TaskPriority.low);
        await baseApi.create(task: task1);
        await baseApi.create(task: task2);

        final entity1 = await baseApi.getTaskEntityById(task1.id);
        final entity2 = await baseApi.getTaskEntityById(task2.id);
        final activities1 = await api.completeTask(entity1!);
        final activities2 = await api.completeTask(entity2!);
        await api.completeTaskByActivities([...activities1, ...activities2]);

        final stream = api.getCompletedTaskCount(
          date: today,
          priority: TaskPriority.high,
        );

        final count = await stream.first;
        expect(count, 1);
      });

      test('returns 0 when no completed tasks', () async {
        final today = Jiffy.now().startOf(Unit.day);
        final stream = api.getCompletedTaskCount(date: today);
        expect(await stream.first, 0);
      });

      test('excludes completed child tasks from count', () async {
        final today = Jiffy.now().startOf(Unit.day);
        final parentTask = _sampleTask(title: 'Parent');
        final childTask1 = _sampleTask(
          title: 'Child 1',
          parentId: parentTask.id,
        );
        final childTask2 = _sampleTask(
          title: 'Child 2',
          parentId: parentTask.id,
        );
        await baseApi.create(
          task: parentTask,
          children: [childTask1, childTask2],
        );

        final childEntity = await baseApi.getTaskEntityById(childTask1.id);
        final activities = await api.completeTask(childEntity!);
        await api.completeTaskByActivities(activities);

        final stream = api.getCompletedTaskCount(date: today);
        expect(await stream.first, 0);
      });

      test('returns completed non-recurring tasks for date', () async {
        final today = Jiffy.now().startOf(Unit.day);
        final task = _sampleTask(title: 'Non-recurring');
        await baseApi.create(task: task);

        final entity = await baseApi.getTaskEntityById(task.id);
        final activities = await api.completeTask(entity!);
        await api.completeTaskByActivities(activities);

        final stream = api.getCompletedTaskEntities(date: today);
        final result = await stream.first;
        expect(result, hasLength(1));
        expect(result.first.title, 'Non-recurring');
      });

      test('returns completed recurring tasks for date', () async {
        final today = Jiffy.now().startOf(Unit.day);
        final task = _sampleTask(
          title: 'Recurring',
          startAt: today,
          recurrenceRule: RecurrenceRule(frequency: RecurrenceFrequency.daily),
        );
        await baseApi.create(task: task);

        final occurrenceAt = today;
        await db
            .into(db.taskOccurrences)
            .insert(
              TaskOccurrencesCompanion.insert(
                taskId: Value(task.id),
                occurrenceAt: occurrenceAt,
              ),
            );

        final entity = await baseApi.getTaskEntityById(
          task.id,
          occurrenceAt: occurrenceAt,
        );
        final activities = await api.completeTask(
          entity!,
          occurrenceAt: occurrenceAt,
          completedAt: occurrenceAt,
        );
        await api.completeTaskByActivities(activities);

        final stream = api.getCompletedTaskEntities(date: occurrenceAt);
        final result = await stream.first;
        expect(result, hasLength(1));
        expect(result.first.title, 'Recurring');
      });

      test('filters entities by priority', () async {
        final today = Jiffy.now().startOf(Unit.day);
        final task1 = _sampleTask(
          title: 'High',
          priority: TaskPriority.high,
        );
        final task2 = _sampleTask(
          title: 'Low',
          priority: TaskPriority.low,
        );
        await baseApi.create(task: task1);
        await baseApi.create(task: task2);

        final entity1 = await baseApi.getTaskEntityById(task1.id);
        final entity2 = await baseApi.getTaskEntityById(task2.id);
        final activities1 = await api.completeTask(entity1!);
        final activities2 = await api.completeTask(entity2!);
        await api.completeTaskByActivities([...activities1, ...activities2]);

        final stream = api.getCompletedTaskEntities(
          date: today,
          priority: TaskPriority.high,
        );
        final result = await stream.first;
        expect(result, hasLength(1));
        expect(result.first.title, 'High');
      });

      test('filters entities by userId', () async {
        final today = Jiffy.now().startOf(Unit.day);
        final task1 = _sampleTask(title: 'User A', userId: 'user-a');
        final task2 = _sampleTask(title: 'User B', userId: 'user-b');
        await baseApi.create(task: task1);
        await baseApi.create(task: task2);

        final entity1 = await baseApi.getTaskEntityById(task1.id);
        final entity2 = await baseApi.getTaskEntityById(task2.id);
        final activities1 = await api.completeTask(entity1!);
        final activities2 = await api.completeTask(entity2!);
        await api.completeTaskByActivities([...activities1, ...activities2]);

        final stream = api.getCompletedTaskEntities(
          date: today,
          userId: 'user-a',
        );
        final result = await stream.first;
        expect(result, hasLength(1));
        expect(result.first.title, 'User A');
      });

      test('returns empty list when no completed tasks', () async {
        final today = Jiffy.now().startOf(Unit.day);
        final stream = api.getCompletedTaskEntities(date: today);
        final result = await stream.first;
        expect(result, isEmpty);
      });
    });

    group('completeTask additional scenarios', () {
      test('uses explicit completedAt parameter', () async {
        final task = _sampleTask();
        await baseApi.create(task: task);

        final entity = await baseApi.getTaskEntityById(task.id);
        final customCompletedAt = Jiffy.now().subtract(days: 1);
        final activities = await api.completeTask(
          entity!,
          completedAt: customCompletedAt,
        );
        await api.completeTaskByActivities(activities);

        final stored = await db.select(db.taskActivities).get();
        expect(stored, hasLength(1));
        expect(stored.first.completedAt, customCompletedAt);
      });

      test(
        'recurring task without occurrenceAt uses entity occurrence',
        () async {
          final today = Jiffy.now().startOf(Unit.day);
          final task = _sampleTask(
            startAt: today,
            recurrenceRule: RecurrenceRule(
              frequency: RecurrenceFrequency.daily,
            ),
          );
          await baseApi.create(task: task);

          final occurrenceAt = today.add(days: 1);
          await db
              .into(db.taskOccurrences)
              .insert(
                TaskOccurrencesCompanion.insert(
                  taskId: Value(task.id),
                  occurrenceAt: occurrenceAt,
                ),
              );

          final entity = await baseApi.getTaskEntityById(
            task.id,
            occurrenceAt: occurrenceAt,
          );
          final activities = await api.completeTask(entity!);
          expect(activities, hasLength(1));
          expect(activities.first.occurrenceAt, occurrenceAt);
        },
      );
    });
  });
}
