import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/planbook_core.dart';

/// 为非会员生成周列表视图的演示任务
///
/// 按星期几分配不同任务组合，使一周看起来更真实；
/// 任务 ID 使用固定前缀，确保不会与真实任务冲突。
List<TaskEntity> buildTaskWeekListDemoTasks(
  Jiffy date,
  AppLocalizations l10n,
) {
  final now = Jiffy.now();
  final dayStart = date.startOf(Unit.day);
  final key = date.dateKey;

  TaskEntity build({
    required String id,
    required String title,
    TaskPriority priority = TaskPriority.none,
  }) {
    return TaskEntity(
      task: Task(
        id: id,
        title: title,
        layer: 0,
        childCount: 0,
        order: 0,
        startAt: dayStart,
        endAt: dayStart,
        isAllDay: true,
        alarms: const [],
        priority: priority,
        createdAt: now,
      ),
    );
  }

  final standup = build(
    id: 'demo-week-$key-standup',
    title: l10n.timeBlockDemoTaskStandup,
    priority: TaskPriority.high,
  );
  final deepWork = build(
    id: 'demo-week-$key-deep-work',
    title: l10n.timeBlockDemoTaskDeepWork,
    priority: TaskPriority.medium,
  );
  final meeting = build(
    id: 'demo-week-$key-meeting',
    title: l10n.timeBlockDemoTaskMeeting,
    priority: TaskPriority.high,
  );
  final workout = build(
    id: 'demo-week-$key-workout',
    title: l10n.timeBlockDemoTaskWorkout,
    priority: TaskPriority.low,
  );

  // DateTime.weekday: 1=周一 … 7=周日
  return switch (date.dateTime.weekday) {
    DateTime.monday => [standup, deepWork],
    DateTime.tuesday => [meeting],
    DateTime.wednesday => [deepWork, workout],
    DateTime.thursday => [standup, meeting],
    DateTime.friday => [workout, deepWork],
    DateTime.saturday => [workout],
    _ => const [],
  };
}
