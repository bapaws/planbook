import 'package:flutter_planbook/task/list/view/task_drag_schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

TaskEntity _timedOccurrence() {
  final start = Jiffy.parse('2026-09-28 10:30:00');
  return TaskEntity(
    task: Task(
      id: 'series',
      title: '例会',
      layer: 0,
      childCount: 0,
      order: 0,
      isAllDay: false,
      alarms: const [],
      createdAt: start,
      startAt: start,
      endAt: start.add(hours: 1),
      recurrenceRule: const RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
      ),
    ),
    occurrence: TaskOccurrence(
      id: 'occ',
      occurrenceAt: start.startOf(Unit.day),
      startAt: start,
      endAt: start.add(hours: 1),
      createdAt: start,
    ),
  );
}

void main() {
  final target = Jiffy.parse('2026-09-30');

  test('从别的日子拖进四象限时保留钟点', () {
    final scheduled = applyDraggedTaskSchedule(
      task: _timedOccurrence(),
      targetDate: target,
      priority: TaskPriority.high,
    );

    final start = scheduled.occurrence!.startAt!;
    expect(start.dateTime.day, 30);
    expect(start.dateTime.hour, 10);
    expect(start.dateTime.minute, 30);
    expect(scheduled.occurrence!.endAt!.dateTime.hour, 11);
    expect(scheduled.task.isAllDay, isFalse);
    expect(scheduled.task.priority, TaskPriority.high);
  });

  test('没有日期的任务拖进四象限时落到当天全天', () {
    final inbox = TaskEntity(
      task: Task(
        id: 'inbox',
        title: '待整理',
        layer: 0,
        childCount: 0,
        order: 0,
        isAllDay: false,
        alarms: const [],
        createdAt: Jiffy.parse('2026-09-01'),
      ),
    );

    final scheduled = applyDraggedTaskSchedule(
      task: inbox,
      targetDate: target,
    );

    expect(scheduled.task.isAllDay, isTrue);
    expect(scheduled.task.startAt!.dateTime.day, 30);
    expect(scheduled.task.startAt!.dateTime.hour, 0);
  });

  test('拖到全天时写成目标日全天', () {
    final scheduled = applyDraggedTaskSchedule(
      task: _timedOccurrence(),
      targetDate: target,
      asAllDay: true,
    );

    expect(scheduled.task.isAllDay, isTrue);
    expect(scheduled.occurrence!.startAt!.dateTime.hour, 0);
    expect(scheduled.occurrence!.startAt!.dateTime.day, 30);
  });
}
