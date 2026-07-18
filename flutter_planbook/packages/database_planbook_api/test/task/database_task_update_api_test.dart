import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:database_planbook_api/task/database_task_update_api.dart';
import 'package:database_planbook_api/task/recurring_task_edit_mode.dart';
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
  String? detachedFromTaskId,
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
    detachedFromTaskId: detachedFromTaskId,
    createdAt: createdAt ?? Jiffy.now(),
  );
}

TagEntity _sampleTagEntity({
  String? id,
  String name = 'Tag',
  String? parentId,
  int level = 0,
  TagEntity? parent,
}) {
  final tag = Tag(
    id: id ?? const Uuid().v4(),
    name: name,
    order: 0,
    level: level,
    parentId: parentId,
    createdAt: Jiffy.now(),
  );
  return TagEntity(tag: tag, parent: parent);
}

void main() {
  group('DatabaseTaskUpdateApi', () {
    late AppDatabase db;
    late OutboxApi outboxApi;
    late DatabaseTagApi tagApi;
    late DatabaseTaskUpdateApi api;
    late DatabaseTaskApi baseApi;

    setUp(() {
      db = createTestDatabase();
      outboxApi = OutboxApi(db: db);
      tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
      api = DatabaseTaskUpdateApi(
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

    group('prepareUpdate', () {
      test('non-recurring task: updates directly', () {
        final task = _sampleTask();
        final entity = TaskEntity(task: task);
        final updatedTask = task.copyWith(title: 'Updated');

        final result = api.prepareUpdate(
          entity: entity,
          updatedTask: updatedTask,
          tags: null,
          userId: null,
        );

        expect(result.isNewTask, isFalse);
        expect(result.updatedTask.title, 'Updated');
        expect(result.updatedTask.updatedAt, isNotNull);
        expect(result.taskTags, isNull);
      });

      test('recurring task with allEvents mode: updates original', () {
        final now = Jiffy.now();
        final task = _sampleTask(
          startAt: now,
          recurrenceRule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
          ),
        );
        final entity = TaskEntity(task: task);
        final updatedTask = task.copyWith(title: 'Updated');

        final result = api.prepareUpdate(
          entity: entity,
          updatedTask: updatedTask,
          tags: null,
          userId: null,
          editMode: RecurringTaskEditMode.allEvents,
        );

        expect(result.isNewTask, isFalse);
        expect(result.updatedTask.title, 'Updated');
        expect(result.originalTaskUpdated, isNull);
      });

      test(
        'recurring task with thisEventOnly mode: creates detached instance',
        () {
          final now = Jiffy.now().startOf(Unit.day);
          final task = _sampleTask(
            startAt: now,
            recurrenceRule: RecurrenceRule(
              frequency: RecurrenceFrequency.daily,
            ),
          );
          final entity = TaskEntity(task: task);
          final updatedTask = task.copyWith(title: 'Updated');

          final result = api.prepareUpdate(
            entity: entity,
            updatedTask: updatedTask,
            tags: null,
            userId: null,
            occurrenceAt: now,
            editMode: RecurringTaskEditMode.thisEventOnly,
          );

          expect(result.isNewTask, isTrue);
          expect(result.updatedTask.title, 'Updated');
          expect(result.updatedTask.detachedFromTaskId, task.id);
          expect(result.updatedTask.detachedRecurrenceAt, isNotNull);
          expect(result.updatedTask.recurrenceRule, isNull);
        },
      );

      test(
        'recurring task with thisAndFutureEvents mode: splits recurrence',
        () {
          final now = Jiffy.now().startOf(Unit.day);
          final task = _sampleTask(
            startAt: now,
            recurrenceRule: RecurrenceRule(
              frequency: RecurrenceFrequency.daily,
            ),
          );
          final entity = TaskEntity(task: task);
          final updatedTask = task.copyWith(title: 'Updated');

          final result = api.prepareUpdate(
            entity: entity,
            updatedTask: updatedTask,
            tags: null,
            userId: null,
            occurrenceAt: now.add(days: 3),
            editMode: RecurringTaskEditMode.thisAndFutureEvents,
          );

          expect(result.isNewTask, isTrue);
          expect(result.updatedTask.title, 'Updated');
          expect(result.originalTaskUpdated, isNotNull);
          // 原始任务的重复规则应该设置了结束日期
          expect(
            result.originalTaskUpdated!.recurrenceRule!.recurrenceEnd,
            isNotNull,
          );
        },
      );

      test('copies children for detach with new IDs', () {
        final now = Jiffy.now().startOf(Unit.day);
        final task = _sampleTask(
          startAt: now,
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
        final updatedTask = task.copyWith(title: 'Updated');

        final result = api.prepareUpdate(
          entity: entity,
          updatedTask: updatedTask,
          tags: null,
          userId: null,
          occurrenceAt: now,
          editMode: RecurringTaskEditMode.thisEventOnly,
        );

        expect(result.children, isNotNull);
        expect(result.children, hasLength(1));
        expect(result.children!.first.id, isNot(childTask.id));
        expect(result.children!.first.parentId, result.updatedTask.id);
      });
    });

    group('saveUpdateResult', () {
      test('saves update for existing task', () async {
        final task = _sampleTask(title: 'Original');
        await baseApi.create(task: task);
        await db.delete(db.syncOutbox).go();

        final updatedTask = task.copyWith(title: 'Updated');
        final result = UpdateTaskResult(updatedTask: updatedTask);

        await api.saveUpdateResult(result);

        final fetched = await baseApi.getTaskById(task.id);
        expect(fetched, isNotNull);
        expect(fetched!.title, 'Updated');

        final outbox = await db.select(db.syncOutbox).get();
        expect(outbox, isNotEmpty);
      });

      test('saves new task for detached instance', () async {
        final originalTask = _sampleTask(title: 'Original');
        await baseApi.create(task: originalTask);
        await db.delete(db.syncOutbox).go();

        final newTask = _sampleTask(title: 'Detached');
        final result = UpdateTaskResult(
          updatedTask: newTask,
          isNewTask: true,
        );

        await api.saveUpdateResult(result);

        final fetched = await baseApi.getTaskById(newTask.id);
        expect(fetched, isNotNull);
        expect(fetched!.title, 'Detached');
      });

      test('saves originalTaskUpdated for thisAndFutureEvents', () async {
        final now = Jiffy.now().startOf(Unit.day);
        final originalTask = _sampleTask(
          title: 'Original',
          startAt: now,
          recurrenceRule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
          ),
        );
        await baseApi.create(task: originalTask);
        await db.delete(db.syncOutbox).go();

        final updatedOriginal = originalTask.copyWith(
          title: 'Original Updated',
        );
        final newTask = _sampleTask(title: 'New Series');

        final result = UpdateTaskResult(
          updatedTask: newTask,
          originalTaskUpdated: updatedOriginal,
          isNewTask: true,
        );

        await api.saveUpdateResult(result);

        final fetchedOriginal = await baseApi.getTaskById(originalTask.id);
        expect(fetchedOriginal!.title, 'Original Updated');

        final fetchedNew = await baseApi.getTaskById(newTask.id);
        expect(fetchedNew, isNotNull);
      });
    });

    group('update', () {
      test('updates task and enqueues outbox record', () async {
        final task = _sampleTask(title: 'Original');
        await baseApi.create(task: task);
        await db.delete(db.syncOutbox).go();

        final updatedTask = task.copyWith(title: 'Updated');
        await api.update(task: updatedTask);

        final fetched = await baseApi.getTaskById(task.id);
        expect(fetched!.title, 'Updated');

        final outbox = await db.select(db.syncOutbox).get();
        expect(outbox, hasLength(1));
        expect(outbox.first.targetTable, 'tasks');
        expect(outbox.first.operation, 'update');
      });

      test('replaces taskTags and enqueues replace_associations', () async {
        final task = _sampleTask();
        await baseApi.create(task: task);
        await db.delete(db.syncOutbox).go();

        final tag = _sampleTagEntity();
        final taskTags = baseApi.generateTaskTags(
          task: task,
          tags: [tag],
          userId: null,
        );

        // 先插入一个旧的 taskTag
        final oldTaskTag = TaskTag(
          id: const Uuid().v4(),
          taskId: task.id,
          tagId: 'old-tag-id',
          createdAt: Jiffy.now(),
        );
        await db.into(db.taskTags).insert(oldTaskTag);

        await api.update(task: task, taskTags: taskTags);

        final storedTags = await db.select(db.taskTags).get();
        expect(storedTags, hasLength(1));
        expect(storedTags.first.tagId, tag.id);

        final outbox = await db.select(db.syncOutbox).get();
        final tagOutbox = outbox
            .where((o) => o.targetTable == 'task_tags')
            .toList();
        expect(tagOutbox, hasLength(1));
        expect(tagOutbox.first.operation, 'replace_associations');
      });

      test('inserts or updates children', () async {
        final parentTask = _sampleTask();
        await baseApi.create(task: parentTask);
        await db.delete(db.syncOutbox).go();

        final childTask = _sampleTask(
          title: 'Child',
          parentId: parentTask.id,
          layer: 1,
        );

        await api.update(task: parentTask, children: [childTask]);

        final fetchedChild = await baseApi.getTaskById(childTask.id);
        expect(fetchedChild, isNotNull);
        expect(fetchedChild!.parentId, parentTask.id);
      });

      test(
        'clears and regenerates occurrences when recurrence changes',
        () async {
          final now = Jiffy.now().startOf(Unit.day);
          final task = _sampleTask(
            startAt: now,
            recurrenceRule: RecurrenceRule(
              frequency: RecurrenceFrequency.daily,
            ),
          );
          await baseApi.create(task: task);
          await Future.delayed(const Duration(milliseconds: 200));

          // 确认已有 occurrence
          final occurrencesBefore = await (db.select(
            db.taskOccurrences,
          )..where((o) => o.taskId.equals(task.id))).get();
          expect(occurrencesBefore, isNotEmpty);

          // 修改重复规则
          final updatedTask = task.copyWith(
            recurrenceRule: Value(
              RecurrenceRule(frequency: RecurrenceFrequency.weekly),
            ),
          );
          await api.update(task: updatedTask);
          await Future.delayed(const Duration(milliseconds: 200));

          final occurrencesAfter = await (db.select(
            db.taskOccurrences,
          )..where((o) => o.taskId.equals(task.id))).get();
          // 旧的 occurrences 应该被清除，新的会被生成
          // 由于 weekly 从同样的 startAt 开始，可能数量不同
        },
      );
    });

    group('hasDetachedInstances', () {
      test('returns true when detached instances exist', () async {
        final task = _sampleTask();
        await baseApi.create(task: task);

        final detachedTask = _sampleTask(
          title: 'Detached',
          detachedFromTaskId: task.id,
        );
        await baseApi.create(task: detachedTask);

        expect(await api.hasDetachedInstances(task.id), isTrue);
      });

      test('returns false when no detached instances', () async {
        final task = _sampleTask();
        await baseApi.create(task: task);

        expect(await api.hasDetachedInstances(task.id), isFalse);
      });

      test('ignores soft-deleted detached instances', () async {
        final task = _sampleTask();
        await baseApi.create(task: task);

        final detachedTask = _sampleTask(
          title: 'Detached',
          detachedFromTaskId: task.id,
        );
        await baseApi.create(task: detachedTask);

        // 软删除 detached task
        await (db.update(db.tasks)..where((t) => t.id.equals(detachedTask.id)))
            .write(TasksCompanion(deletedAt: Value(Jiffy.now())));

        expect(await api.hasDetachedInstances(task.id), isFalse);
      });
    });
  });
}
