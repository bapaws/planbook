import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

/// 为非会员生成时间块视图的演示任务
///
/// 任务 ID 使用固定前缀，确保不会与真实任务冲突；
/// 所有起止时间都基于 [date] 的当天 00:00 计算。
List<TaskEntity> buildTaskTimeBlockDemoTasks(
  Jiffy date,
  AppLocalizations l10n,
) {
  final dayStart = date.startOf(Unit.day);
  final now = Jiffy.now();

  TaskEntity build({
    required String id,
    required String title,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    TaskPriority priority = TaskPriority.none,
  }) {
    final startAt = dayStart.add(
      hours: startHour,
      minutes: startMinute,
    );
    final endAt = dayStart.add(
      hours: endHour,
      minutes: endMinute,
    );
    return TaskEntity(
      task: Task(
        id: id,
        title: title,
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: startAt,
        endAt: endAt,
        isAllDay: false,
        alarms: const [],
        priority: priority,
        createdAt: now,
      ),
    );
  }

  return [
    build(
      id: 'demo-task-standup',
      title: l10n.timeBlockDemoTaskStandup,
      startHour: 8,
      startMinute: 0,
      endHour: 9,
      endMinute: 0,
      priority: TaskPriority.high,
    ),
    build(
      id: 'demo-task-deep-work',
      title: l10n.timeBlockDemoTaskDeepWork,
      startHour: 9,
      startMinute: 30,
      endHour: 11,
      endMinute: 30,
      priority: TaskPriority.medium,
    ),
    build(
      id: 'demo-task-meeting',
      title: l10n.timeBlockDemoTaskMeeting,
      startHour: 14,
      startMinute: 0,
      endHour: 15,
      endMinute: 30,
      priority: TaskPriority.high,
    ),
    build(
      id: 'demo-task-workout',
      title: l10n.timeBlockDemoTaskWorkout,
      startHour: 16,
      startMinute: 0,
      endHour: 17,
      endMinute: 0,
      priority: TaskPriority.low,
    ),
  ];
}
