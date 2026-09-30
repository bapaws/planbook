import 'package:database_planbook_api/task/database_task_delay_api.dart';
import 'package:database_planbook_api/task/database_task_overdue_api.dart';
import 'package:database_planbook_api/task/database_task_today_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:uuid/uuid.dart';

import '../test_helper.dart';

void main() {
  test('分离实例按实际开始时间归日，不按原始重复日', () async {
    final apis = createTestApis();
    final todayApi = DatabaseTaskTodayApi(
      db: apis.db,
      tagApi: apis.tagApi,
      outboxApi: apis.outboxApi,
    );
    final overdueApi = DatabaseTaskOverdueApi(
      db: apis.db,
      tagApi: apis.tagApi,
      outboxApi: apis.outboxApi,
    );
    final delayApi = DatabaseTaskDelayApi(db: apis.db, tagApi: apis.tagApi);

    final originalDay = Jiffy.parse('2026-09-28 10:30:00');
    final targetDay = Jiffy.parse('2026-09-30');
    final series = Task(
      id: const Uuid().v4(),
      title: '例会',
      layer: 0,
      childCount: 0,
      order: 0,
      isAllDay: false,
      alarms: const [],
      createdAt: originalDay,
      startAt: originalDay,
      endAt: originalDay.add(hours: 1),
      recurrenceRule: const RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
      ),
    );
    await apis.taskApi.create(task: series);
    await apis.db
        .into(apis.db.taskOccurrences)
        .insert(
          TaskOccurrence(
            id: const Uuid().v4(),
            taskId: series.id,
            occurrenceAt: originalDay.startOf(Unit.day),
            startAt: originalDay,
            endAt: originalDay.add(hours: 1),
            createdAt: originalDay,
          ),
        );

    final prepared = delayApi.prepareDelayTask(
      entity: TaskEntity(
        task: series,
        occurrence: TaskOccurrence(
          id: 'occ',
          taskId: series.id,
          occurrenceAt: originalDay.startOf(Unit.day),
          startAt: originalDay,
          endAt: originalDay.add(hours: 1),
          createdAt: originalDay,
        ),
      ),
      delayTo: targetDay,
    );
    await apis.taskApi.create(task: prepared.task);
    await delayApi.softDeleteOccurrence(
      taskId: series.id,
      occurrenceAt: originalDay,
    );

    final onOriginalDay = await todayApi
        .getAllTodayTaskEntities(day: originalDay)
        .first;
    final onTargetDay = await todayApi
        .getAllTodayTaskEntities(day: targetDay)
        .first;
    final overdue = await overdueApi
        .getOverdueTaskEntities(date: targetDay)
        .first;

    expect(
      onOriginalDay.where((task) => task.id == prepared.task.id),
      isEmpty,
    );
    expect(
      onOriginalDay.where((task) => task.id == series.id),
      isEmpty,
    );

    final moved = onTargetDay.singleWhere(
      (task) => task.id == prepared.task.id,
    );
    expect(moved.startAt!.dateTime.day, 30);
    expect(moved.startAt!.dateTime.hour, 10);
    expect(moved.startAt!.dateTime.minute, 30);
    expect(moved.task.detachedRecurrenceAt!.dateTime.day, 28);
    expect(
      overdue.where((task) => task.id == prepared.task.id),
      isEmpty,
    );

    await apis.db.close();
  });
}
