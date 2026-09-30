import 'package:flutter_planbook/task/list/view/task_drag_to_priority.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

TaskEntity _task({
  TaskPriority priority = TaskPriority.none,
  Jiffy? startAt,
}) {
  return TaskEntity(
    task: Task(
      id: 'task',
      title: 'task',
      layer: 0,
      childCount: 0,
      order: 0,
      isAllDay: startAt != null,
      alarms: const [],
      createdAt: Jiffy.parse('2026-09-01'),
      priority: priority,
      startAt: startAt,
      endAt: startAt?.endOf(Unit.day),
    ),
  );
}

void main() {
  final today = Jiffy.parse('2026-09-30');

  test('收集箱任务即使优先级相同，也能拖进当天象限', () {
    expect(
      TaskPriorityDropArea.wouldAcceptDrop(
        task: _task(),
        targetPriority: TaskPriority.none,
        mode: TaskListMode.today,
        targetDate: today,
      ),
      isTrue,
    );
  });

  test('已经在当天且优先级相同的任务会被拒绝', () {
    expect(
      TaskPriorityDropArea.wouldAcceptDrop(
        task: _task(startAt: today),
        targetPriority: TaskPriority.none,
        mode: TaskListMode.today,
        targetDate: today,
      ),
      isFalse,
    );
  });

  test('不在当天但优先级相同的任务会被接受', () {
    expect(
      TaskPriorityDropArea.wouldAcceptDrop(
        task: _task(startAt: today.subtract(days: 2)),
        targetPriority: TaskPriority.none,
        mode: TaskListMode.today,
        targetDate: today,
      ),
      isTrue,
    );
  });

  test('当天任务改到其他象限会被接受', () {
    expect(
      TaskPriorityDropArea.wouldAcceptDrop(
        task: _task(priority: TaskPriority.high, startAt: today),
        targetPriority: TaskPriority.none,
        mode: TaskListMode.today,
        targetDate: today,
      ),
      isTrue,
    );
  });

  test('收集箱视图只在优先级变化时接受', () {
    expect(
      TaskPriorityDropArea.wouldAcceptDrop(
        task: _task(),
        targetPriority: TaskPriority.none,
        mode: TaskListMode.inbox,
        targetDate: null,
      ),
      isFalse,
    );
    expect(
      TaskPriorityDropArea.wouldAcceptDrop(
        task: _task(priority: TaskPriority.high),
        targetPriority: TaskPriority.none,
        mode: TaskListMode.inbox,
        targetDate: null,
      ),
      isTrue,
    );
  });
}
