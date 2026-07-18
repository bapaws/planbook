import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:database_planbook_api/task/database_task_api.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kDebugMode;
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
  group('DatabaseTaskApi', () {
    late AppDatabase db;
    late OutboxApi outboxApi;
    late DatabaseTagApi tagApi;
    late DatabaseTaskApi api;

    setUp(() {
      db = createTestDatabase();
      outboxApi = OutboxApi(db: db);
      tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
      api = DatabaseTaskApi(db: db, tagApi: tagApi, outboxApi: outboxApi);
    });

    tearDown(() async {
      await db.close();
    });

    group('create', () {
      test('inserts a task and enqueues outbox record', () async {
        final task = _sampleTask();
        await api.create(task: task);

        final fetched = await api.getTaskById(task.id);
        expect(fetched, isNotNull);
        expect(fetched!.id, task.id);
        expect(fetched.title, task.title);

        final outbox = await db.select(db.syncOutbox).get();
        expect(outbox, hasLength(1));
        expect(outbox.first.targetTable, 'tasks');
        expect(outbox.first.recordId, task.id);
        expect(outbox.first.operation, 'insert');
      });

      test(
        'creates task with taskTags and enqueues replace_associations',
        () async {
          final task = _sampleTask();
          final tag = _sampleTagEntity();
          final taskTags = api.generateTaskTags(
            task: task,
            tags: [tag],
            userId: null,
          );

          await api.create(task: task, taskTags: taskTags);

          final outbox = await db.select(db.syncOutbox).get();
          expect(outbox, hasLength(2));

          final taskOutbox = outbox.firstWhere((o) => o.targetTable == 'tasks');
          expect(taskOutbox.operation, 'insert');

          final tagOutbox = outbox.firstWhere(
            (o) => o.targetTable == 'task_tags',
          );
          expect(tagOutbox.operation, 'replace_associations');
          expect(tagOutbox.recordId, task.id);
        },
      );

      test(
        'creates task with children and enqueues child outbox records',
        () async {
          final parentTask = _sampleTask();
          final childTask = _sampleTask(
            title: 'Child Task',
            parentId: parentTask.id,
            layer: 1,
          );

          await api.create(task: parentTask, children: [childTask]);

          final fetchedChild = await api.getTaskById(childTask.id);
          expect(fetchedChild, isNotNull);
          expect(fetchedChild!.parentId, parentTask.id);

          final outbox = await db.select(db.syncOutbox).get();
          expect(outbox, hasLength(2));
          expect(outbox.every((o) => o.targetTable == 'tasks'), isTrue);
        },
      );

      test('pre-generates occurrences for recurring task', () async {
        final now = Jiffy.now().startOf(Unit.day);
        final task = _sampleTask(
          startAt: now,
          recurrenceRule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
          ),
        );

        await api.create(task: task);

        // 等待异步的 preGenerateTaskOccurrences 完成
        await Future.delayed(const Duration(milliseconds: 200));

        final occurrences = await (db.select(
          db.taskOccurrences,
        )..where((o) => o.taskId.equals(task.id))).get();
        expect(occurrences, isNotEmpty);
      });
    });

    group('deleteTaskById', () {
      test('removes task (debug=physical, release=soft)', () async {
        final task = _sampleTask();
        await api.create(task: task);
        // 清空 outbox，避免干扰
        await db.delete(db.syncOutbox).go();

        final result = await api.deleteTaskById(task.id);

        final fetched = await api.getTaskById(task.id);

        if (kDebugMode) {
          // Debug 模式：物理删除
          expect(result, isNotNull);
          expect(fetched, isNull);
          final outbox = await db.select(db.syncOutbox).get();
          expect(outbox, isEmpty);
        } else {
          // Release 模式：软删除
          expect(result, isNotNull);
          expect(result!.deletedAt, isNotNull);
          expect(fetched, isNull);
          final outbox = await db.select(db.syncOutbox).get();
          expect(outbox, hasLength(1));
          expect(outbox.first.operation, 'delete');
          expect(outbox.first.targetTable, 'tasks');
        }
      });

      test('returns null for non-existent task', () async {
        final result = await api.deleteTaskById('non-existent');
        expect(result, isNull);
      });
    });

    group('getTaskById', () {
      test('returns task when found', () async {
        final task = _sampleTask();
        await api.create(task: task);

        final fetched = await api.getTaskById(task.id);
        expect(fetched, isNotNull);
        expect(fetched!.id, task.id);
      });

      test('returns null when task is soft deleted', () async {
        final task = _sampleTask();
        await api.insertOrUpdate(task: task);

        // 直接软删除
        await (db.update(db.tasks)..where((t) => t.id.equals(task.id))).write(
          TasksCompanion(deletedAt: Value(Jiffy.now())),
        );

        final fetched = await api.getTaskById(task.id);
        expect(fetched, isNull);
      });

      test('returns null for non-existent task', () async {
        final fetched = await api.getTaskById('non-existent');
        expect(fetched, isNull);
      });
    });

    group('getTotalCount', () {
      test('counts only non-deleted tasks', () async {
        expect(await api.getTotalCount(userId: null), 0);

        final task1 = _sampleTask();
        await api.create(task: task1);
        expect(await api.getTotalCount(userId: null), 1);

        final task2 = _sampleTask();
        await api.create(task: task2);
        expect(await api.getTotalCount(userId: null), 2);

        // 软删除 task1
        await (db.update(db.tasks)..where((t) => t.id.equals(task1.id))).write(
          TasksCompanion(deletedAt: Value(Jiffy.now())),
        );

        expect(await api.getTotalCount(userId: null), 1);
      });

      test('filters by userId', () async {
        final userTask = _sampleTask(userId: 'user-1');
        final anonTask = _sampleTask();

        await api.create(task: userTask);
        await api.create(task: anonTask);

        expect(await api.getTotalCount(userId: 'user-1'), 1);
        expect(await api.getTotalCount(userId: null), 1);
        expect(await api.getTotalCount(userId: 'other-user'), 0);
      });
    });

    group('generateTaskTags', () {
      test('returns null when tags is null', () {
        final task = _sampleTask();
        final result = api.generateTaskTags(
          task: task,
          tags: null,
          userId: null,
        );
        expect(result, isNull);
      });

      test('generates TaskTag for each tag', () {
        final task = _sampleTask();
        final tag1 = _sampleTagEntity(name: 'Tag 1');
        final tag2 = _sampleTagEntity(name: 'Tag 2');

        final result = api.generateTaskTags(
          task: task,
          tags: [tag1, tag2],
          userId: 'user-1',
        );

        expect(result, hasLength(2));
        expect(result!.every((tt) => tt.taskId == task.id), isTrue);
        expect(result.every((tt) => tt.userId == 'user-1'), isTrue);
        expect(result.map((tt) => tt.tagId), containsAll([tag1.id, tag2.id]));
      });

      test('includes parent tags with linkedTagId', () {
        final task = _sampleTask();
        final parentTag = _sampleTagEntity(name: 'Parent');
        final childTag = _sampleTagEntity(
          name: 'Child',
          parentId: parentTag.id,
          level: 1,
          parent: parentTag,
        );

        final result = api.generateTaskTags(
          task: task,
          tags: [childTag],
          userId: null,
        );

        expect(result, hasLength(2));

        final childTaskTag = result!.firstWhere(
          (tt) => tt.tagId == childTag.id,
        );
        expect(childTaskTag.linkedTagId, isNull);

        final parentTaskTag = result.firstWhere(
          (tt) => tt.tagId == parentTag.id,
        );
        expect(parentTaskTag.linkedTagId, childTag.id);
      });
    });

    group('insertOrUpdate', () {
      test('inserts a new task', () async {
        final task = _sampleTask();
        await api.insertOrUpdate(task: task);

        final fetched = await api.getTaskById(task.id);
        expect(fetched, isNotNull);
        expect(fetched!.title, task.title);
      });

      test('updates existing task', () async {
        final task = _sampleTask(title: 'Original');
        await api.insertOrUpdate(task: task);

        final updated = task.copyWith(title: 'Updated');
        await api.insertOrUpdate(task: updated);

        final fetched = await api.getTaskById(task.id);
        expect(fetched, isNotNull);
        expect(fetched!.title, 'Updated');
      });
    });
  });
}
