import 'package:database_planbook_api/database_planbook_api.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:uuid/uuid.dart';

import '../test_helper.dart';

Task _sampleTask({
  String? id,
  String title = 'Test Task',
  Jiffy? startAt,
  Jiffy? endAt,
  Jiffy? dueAt,
  bool isAllDay = false,
  RecurrenceRule? recurrenceRule,
}) {
  return Task(
    id: id ?? const Uuid().v4(),
    title: title,
    layer: 0,
    childCount: 0,
    order: 0,
    startAt: startAt,
    endAt: endAt,
    dueAt: dueAt,
    isAllDay: isAllDay,
    recurrenceRule: recurrenceRule,
    alarms: const [],
    createdAt: Jiffy.now(),
  );
}

void main() {
  group('DatabaseTaskDeleteApi', () {
    late AppDatabase db;
    late OutboxApi outboxApi;
    late DatabaseTagApi tagApi;
    late DatabaseTaskApi baseApi;
    late DatabaseTaskDeleteApi api;

    setUp(() {
      db = createTestDatabase();
      outboxApi = OutboxApi(db: db);
      tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
      baseApi = DatabaseTaskApi(db: db, tagApi: tagApi, outboxApi: outboxApi);
      api = DatabaseTaskDeleteApi(
        db: db,
        tagApi: tagApi,
        outboxApi: outboxApi,
      );
    });

    tearDown(() async {
      await db.close();
    });

    group('deleteTask', () {
      test('thisEventOnly marks existing occurrence as deleted', () async {
        final task = _sampleTask(title: 'Recurring');
        await baseApi.create(task: task);

        final occurrenceAt = Jiffy.now().startOf(Unit.day).add(days: 2);
        await db
            .into(db.taskOccurrences)
            .insert(
              TaskOccurrence(
                id: const Uuid().v4(),
                taskId: task.id,
                occurrenceAt: occurrenceAt,
                createdAt: Jiffy.now(),
              ),
            );

        final entity = TaskEntity(
          task: task.copyWith(
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
        await api.deleteTask(
          entity: entity,
          mode: RecurringTaskDeleteMode.thisEventOnly,
          occurrenceAt: occurrenceAt,
        );

        final occurrences = await (db.select(
          db.taskOccurrences,
        )..where((to) => to.taskId.equals(task.id))).get();
        expect(occurrences, hasLength(1));
        expect(occurrences.first.deletedAt, isNotNull);

        final detached = await (db.select(db.tasks)..where(
              (t) => t.detachedFromTaskId.equals(task.id),
            ))
            .get();
        expect(detached, hasLength(1));
        expect(detached.first.deletedAt, isNotNull);
        expect(detached.first.detachedReason, DetachedReason.deleted);
        expect(
          detached.first.detachedRecurrenceAt!.isSame(
            occurrenceAt,
            unit: Unit.day,
          ),
          isTrue,
        );

        final outbox = await db.select(db.syncOutbox).get();
        expect(
          outbox.any(
            (e) =>
                e.targetTable == 'tasks' &&
                e.recordId == detached.first.id &&
                e.operation == 'insert',
          ),
          isTrue,
        );
      });

      test(
        'thisEventOnly inserts deleted placeholder when occurrence missing',
        () async {
          final baseDate = Jiffy.parse('2024-01-01');
          final task = _sampleTask(
            title: 'Recurring',
            startAt: baseDate,
            endAt: baseDate.add(hours: 1),
            dueAt: baseDate,
          );
          await baseApi.create(task: task);

          final occurrenceAt = baseDate.add(days: 2);
          final entity = TaskEntity(
            task: task.copyWith(
              recurrenceRule: const Value(
                RecurrenceRule(frequency: RecurrenceFrequency.daily),
              ),
            ),
          );
          await api.deleteTask(
            entity: entity,
            mode: RecurringTaskDeleteMode.thisEventOnly,
            occurrenceAt: occurrenceAt,
          );

          final occurrences = await (db.select(
            db.taskOccurrences,
          )..where((to) => to.taskId.equals(task.id))).get();
          expect(occurrences, hasLength(1));
          expect(occurrences.first.deletedAt, isNotNull);
          expect(
            occurrences.first.occurrenceAt.isSame(
              occurrenceAt,
              unit: Unit.day,
            ),
            isTrue,
          );

          final detached = await (db.select(db.tasks)..where(
                (t) => t.detachedFromTaskId.equals(task.id),
              ))
              .get();
          expect(detached, hasLength(1));
          expect(detached.first.deletedAt, isNotNull);
          expect(detached.first.detachedReason, DetachedReason.deleted);
        },
      );

      test(
        'thisEventOnly throws when occurrenceAt cannot be determined',
        () async {
          final task = _sampleTask(title: 'Recurring');
          await baseApi.create(task: task);

          final entity = TaskEntity(
            task: task.copyWith(
              recurrenceRule: const Value(
                RecurrenceRule(frequency: RecurrenceFrequency.daily),
              ),
            ),
          );
          expect(
            () => api.deleteTask(
              entity: entity,
              mode: RecurringTaskDeleteMode.thisEventOnly,
            ),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test(
        'thisAndFutureEvents ends recurrence before occurrence date',
        () async {
          final baseDate = Jiffy.parse('2024-01-01');
          final task = _sampleTask(
            title: 'Recurring',
            startAt: baseDate,
            recurrenceRule: const RecurrenceRule(
              frequency: RecurrenceFrequency.daily,
            ),
          );
          await baseApi.create(task: task);
          await Future<void>.delayed(const Duration(milliseconds: 300));
          await db.delete(db.syncOutbox).go();

          final occurrenceAt = baseDate.add(days: 5);
          final entity = TaskEntity(task: task);
          final updatedTask = await api.deleteTask(
            entity: entity,
            mode: RecurringTaskDeleteMode.thisAndFutureEvents,
            occurrenceAt: occurrenceAt,
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));

          expect(updatedTask, isNotNull);
          expect(updatedTask!.recurrenceRule, isNotNull);
          expect(updatedTask.recurrenceRule!.recurrenceEnd, isNotNull);

          final newEndAt = occurrenceAt.subtract(days: 1).endOf(Unit.day);
          expect(
            updatedTask.recurrenceRule!.recurrenceEnd!.toJson(),
            RecurrenceEnd.fromEndAt(newEndAt).toJson(),
          );

          final outbox = await db.select(db.syncOutbox).get();
          expect(outbox, isNotEmpty);
          final taskOutbox = outbox
              .where((o) => o.targetTable == 'tasks')
              .toList();
          expect(taskOutbox, hasLength(1));
          expect(taskOutbox.first.operation, 'update');
        },
      );

      test('thisAndFutureEvents throws when occurrenceAt is null', () async {
        final task = _sampleTask(title: 'Recurring');
        await baseApi.create(task: task);

        final entity = TaskEntity(
          task: task.copyWith(
            recurrenceRule: const Value(
              RecurrenceRule(frequency: RecurrenceFrequency.daily),
            ),
          ),
        );
        expect(
          () => api.deleteTask(
            entity: entity,
            mode: RecurringTaskDeleteMode.thisAndFutureEvents,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('allEvents deletes the task', () async {
        final task = _sampleTask(title: 'To Delete');
        await baseApi.create(task: task);

        final entity = TaskEntity(task: task);
        await api.deleteTask(
          entity: entity,
          mode: RecurringTaskDeleteMode.allEvents,
        );

        final fetched = await baseApi.getTaskById(task.id);
        expect(fetched, isNull);
      });

      test(
        'uses entity occurrence when occurrenceAt is not provided',
        () async {
          final task = _sampleTask(title: 'Recurring');
          await baseApi.create(task: task);

          final occurrenceAt = Jiffy.now().startOf(Unit.day).add(days: 3);
          await db
              .into(db.taskOccurrences)
              .insert(
                TaskOccurrence(
                  id: const Uuid().v4(),
                  taskId: task.id,
                  occurrenceAt: occurrenceAt,
                  createdAt: Jiffy.now(),
                ),
              );

          final entity = TaskEntity(
            task: task.copyWith(
              recurrenceRule: const Value(
                RecurrenceRule(frequency: RecurrenceFrequency.daily),
              ),
            ),
            occurrence: TaskOccurrence(
              id: const Uuid().v4(),
              taskId: task.id,
              occurrenceAt: occurrenceAt,
              createdAt: Jiffy.now(),
            ),
          );

          await api.deleteTask(
            entity: entity,
            mode: RecurringTaskDeleteMode.thisEventOnly,
          );

          final occurrences = await (db.select(
            db.taskOccurrences,
          )..where((to) => to.taskId.equals(task.id))).get();
          expect(occurrences, hasLength(1));
          expect(occurrences.first.deletedAt, isNotNull);
        },
      );
    });
  });
}
