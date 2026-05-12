import 'package:database_planbook_api/sync/outbox_api.dart';
import 'package:database_planbook_api/tag/database_tag_api.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_repository/task/tasks_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final parent = _testTask(id: 'parent-1', title: 'Parent', layer: 0);
      final child = TaskEntity(
        task: _testTask(id: 'child-1', title: 'Child', layer: 0),
      );

      await repository.create(task: parent, children: [child]);

      final parentEntity = await repository.getTaskEntityById('parent-1');
      expect(parentEntity!.task.childCount, 1);

      final childEntity = await repository.getTaskEntityById('child-1');
      expect(childEntity!.task.parentId, 'parent-1');
      expect(childEntity.task.layer, 1);
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
