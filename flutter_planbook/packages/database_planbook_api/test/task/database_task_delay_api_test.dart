import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:database_planbook_api/task/database_task_delay_api.dart';
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
  group('DatabaseTaskDelayApi', () {
    late AppDatabase db;
    late OutboxApi outboxApi;
    late DatabaseTagApi tagApi;
    late DatabaseTaskApi baseApi;
    late DatabaseTaskDelayApi api;

    setUp(() {
      db = createTestDatabase();
      outboxApi = OutboxApi(db: db);
      tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
      baseApi = DatabaseTaskApi(db: db, tagApi: tagApi, outboxApi: outboxApi);
      api = DatabaseTaskDelayApi(db: db, tagApi: tagApi);
    });

    tearDown(() async {
      await db.close();
    });

    group('softDeleteOccurrence', () {
      test('marks occurrence as deleted for given date', () async {
        final taskId = const Uuid().v4();
        final date = Jiffy.now().startOf(Unit.day);

        await db
            .into(db.taskOccurrences)
            .insert(
              TaskOccurrence(
                id: const Uuid().v4(),
                taskId: taskId,
                occurrenceAt: date,
                createdAt: Jiffy.now(),
              ),
            );

        await api.softDeleteOccurrence(
          taskId: taskId,
          occurrenceAt: date,
        );

        final occurrences = await db.select(db.taskOccurrences).get();
        expect(occurrences, hasLength(1));
        expect(occurrences.first.deletedAt, isNotNull);
      });

      test('only affects occurrence on the same day', () async {
        final taskId = const Uuid().v4();
        final today = Jiffy.now().startOf(Unit.day);
        final tomorrow = today.add(days: 1);

        await db
            .into(db.taskOccurrences)
            .insert(
              TaskOccurrence(
                id: const Uuid().v4(),
                taskId: taskId,
                occurrenceAt: today,
                createdAt: Jiffy.now(),
              ),
            );
        await db
            .into(db.taskOccurrences)
            .insert(
              TaskOccurrence(
                id: const Uuid().v4(),
                taskId: taskId,
                occurrenceAt: tomorrow,
                createdAt: Jiffy.now(),
              ),
            );

        await api.softDeleteOccurrence(
          taskId: taskId,
          occurrenceAt: today,
        );

        final occurrences = await db.select(db.taskOccurrences).get();
        final todayOcc = occurrences.firstWhere(
          (o) => o.occurrenceAt.isSame(today),
        );
        final tomorrowOcc = occurrences.firstWhere(
          (o) => o.occurrenceAt.isSame(tomorrow),
        );

        expect(todayOcc.deletedAt, isNotNull);
        expect(tomorrowOcc.deletedAt, isNull);
      });

      test('does nothing when no matching occurrence exists', () async {
        await api.softDeleteOccurrence(
          taskId: 'non-existent',
          occurrenceAt: Jiffy.now(),
        );

        final occurrences = await db.select(db.taskOccurrences).get();
        expect(occurrences, isEmpty);
      });
    });

    group('prepareDelayTask', () {
      test('non-recurring task: shifts dueAt/startAt/endAt', () {
        final baseDate = Jiffy.parse('2024-01-01');
        final task = _sampleTask(
          startAt: baseDate,
          endAt: baseDate.add(days: 1),
          dueAt: baseDate,
        );
        final entity = TaskEntity(task: task);
        final delayTo = baseDate.add(days: 9);

        final result = api.prepareDelayTask(
          entity: entity,
          delayTo: delayTo,
        );

        expect(result.isNewTask, isFalse);
        expect(result.task.startAt, isNotNull);
        expect(result.task.startAt!.dateTime.day, 10);
        expect(result.task.endAt, isNotNull);
        expect(result.task.endAt!.dateTime.day, 11);
        expect(result.task.dueAt, isNotNull);
        expect(result.task.dueAt!.dateTime.day, 10);
      });

      test('non-recurring task: delays children with same offset', () {
        final baseDate = Jiffy.parse('2024-01-01');
        final parentTask = _sampleTask(
          startAt: baseDate,
          dueAt: baseDate,
        );
        final childTask = _sampleTask(
          title: 'Child',
          parentId: parentTask.id,
          startAt: baseDate,
          dueAt: baseDate,
          layer: 1,
        );
        final entity = TaskEntity(
          task: parentTask,
          children: [TaskEntity(task: childTask)],
        );
        final delayTo = baseDate.add(days: 9);

        final result = api.prepareDelayTask(
          entity: entity,
          delayTo: delayTo,
        );

        expect(result.children, isNotNull);
        expect(result.children, hasLength(1));
        expect(result.children!.first.startAt!.dateTime.day, 10);
      });

      test('recurring task: creates detached instance', () {
        final baseDate = Jiffy.parse('2024-01-01');
        final task = _sampleTask(
          startAt: baseDate,
          recurrenceRule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
          ),
        );
        final entity = TaskEntity(task: task);
        final delayTo = Jiffy.parse('2024-01-05');

        final result = api.prepareDelayTask(
          entity: entity,
          delayTo: delayTo,
        );

        expect(result.isNewTask, isTrue);
        expect(result.task.detachedFromTaskId, task.id);
        expect(result.task.detachedRecurrenceAt, isNotNull);
        expect(result.task.recurrenceRule, isNull);
        expect(result.originalTaskId, task.id);
        expect(result.originalOccurrenceAt, isNotNull);
      });

      test('recurring task: copies children with new IDs for detached', () {
        final baseDate = Jiffy.parse('2024-01-01');
        final task = _sampleTask(
          startAt: baseDate,
          recurrenceRule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
          ),
        );
        final childTask = _sampleTask(
          title: 'Child',
          parentId: task.id,
          layer: 1,
        );
        final entity = TaskEntity(
          task: task,
          children: [TaskEntity(task: childTask)],
        );
        final delayTo = Jiffy.parse('2024-01-05');

        final result = api.prepareDelayTask(
          entity: entity,
          delayTo: delayTo,
        );

        expect(result.children, isNotNull);
        expect(result.children, hasLength(1));
        expect(result.children!.first.id, isNot(childTask.id));
        expect(result.children!.first.parentId, result.task.id);
      });

      test('throws when recurring task has no occurrence date', () {
        final task = _sampleTask(
          recurrenceRule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
          ),
        );
        final entity = TaskEntity(task: task);
        final delayTo = Jiffy.parse('2024-01-05');

        expect(
          () => api.prepareDelayTask(
            entity: entity,
            delayTo: delayTo,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('calculateDelayedTask', () {
      test('shifts dates by day difference', () {
        final baseDate = Jiffy.parse('2024-01-01');
        final task = _sampleTask(
          startAt: baseDate,
          endAt: baseDate.add(days: 1),
          dueAt: baseDate,
        );
        final delayTo = baseDate.add(days: 9);

        final result = api.calculateDelayedTask(task, delayTo);

        expect(result.startAt!.dateTime.day, 10);
        expect(result.endAt!.dateTime.day, 11);
        expect(result.dueAt!.dateTime.day, 10);
      });

      test('preserves null dates', () {
        final task = _sampleTask();
        final delayTo = Jiffy.parse('2024-01-10');

        final result = api.calculateDelayedTask(task, delayTo);

        expect(result.startAt, isNull);
        expect(result.endAt, isNull);
        expect(result.dueAt, isNull);
      });
    });

    group('createDetachedInstance', () {
      test('creates task with detached fields set', () {
        final originalTask = _sampleTask(
          title: 'Original',
          startAt: Jiffy.parse('2024-01-01'),
        );
        final occurrenceAt = Jiffy.parse('2024-01-03');
        final delayTo = Jiffy.parse('2024-01-05');
        final newId = const Uuid().v4();

        final result = api.createDetachedInstance(
          taskId: newId,
          originalTask: originalTask,
          originalOccurrenceAt: occurrenceAt,
          delayTo: delayTo,
        );

        expect(result.id, newId);
        expect(result.title, originalTask.title);
        expect(result.detachedFromTaskId, originalTask.id);
        expect(result.detachedReason, DetachedReason.modified);
        expect(result.recurrenceRule, isNull);
      });

      test('calculates correct dates for detached instance', () {
        final originalTask = _sampleTask(
          title: 'Original',
          startAt: Jiffy.parse('2024-01-01T10:00:00'),
          endAt: Jiffy.parse('2024-01-01T12:00:00'),
          dueAt: Jiffy.parse('2024-01-01T14:00:00'),
        );
        final occurrenceAt = Jiffy.parse('2024-01-03');
        final delayTo = Jiffy.parse('2024-01-05');
        final newId = const Uuid().v4();

        final result = api.createDetachedInstance(
          taskId: newId,
          originalTask: originalTask,
          originalOccurrenceAt: occurrenceAt,
          delayTo: delayTo,
        );

        // 原始任务 startAt 是 1 号 10:00，occurrence 是 3 号
        // 所以 instance startAt 应该是 3 号 10:00
        // delayTo 是 5 号，所以最终 startAt 应该是 5 号 10:00
        expect(result.startAt!.dateTime.day, 5);
        expect(result.startAt!.dateTime.hour, 10);

        expect(result.endAt!.dateTime.day, 5);
        expect(result.endAt!.dateTime.hour, 12);

        expect(result.dueAt!.dateTime.day, 5);
        expect(result.dueAt!.dateTime.hour, 14);
      });
    });
  });
}
