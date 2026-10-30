import 'package:drift/drift.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

/// 拖到某一天时如何改写任务时间，供乐观更新与测试共用。
///
/// [asAllDay] 为 true 时写成目标日全天（侧栏「全天」）。
/// 否则已有日期的任务按天数平移，保留钟点；没有日期则落到当天全天。
TaskEntity applyDraggedTaskSchedule({
  required TaskEntity task,
  required Jiffy targetDate,
  bool asAllDay = false,
  TaskPriority? priority,
}) {
  final target = targetDate.startOf(Unit.day);
  final taskDay = (task.occurrenceAt ?? task.startAt ?? task.dueAt)?.startOf(
    Unit.day,
  );
  final hasDate =
      task.startAt != null || task.dueAt != null || task.endAt != null;
  final priorityValue = priority == null
      ? const Value<TaskPriority?>.absent()
      : Value<TaskPriority?>(priority);

  if (asAllDay || !hasDate || taskDay == null) {
    return task.copyWith(
      task: task.task.copyWith(
        startAt: Value(target),
        endAt: Value(target.endOf(Unit.day)),
        isAllDay: true,
        priority: priorityValue,
      ),
      occurrence: task.occurrence?.copyWith(
        occurrenceAt: target,
        startAt: Value(target),
        endAt: Value(target.endOf(Unit.day)),
        dueAt: const Value(null),
      ),
    );
  }

  final daysDiff = target.diff(taskDay, unit: Unit.day).toInt();
  final occurrence = task.occurrence;
  return task.copyWith(
    task: task.task.copyWith(
      startAt: Value(task.task.startAt?.add(days: daysDiff)),
      endAt: Value(task.task.endAt?.add(days: daysDiff)),
      dueAt: Value(task.task.dueAt?.add(days: daysDiff)),
      priority: priorityValue,
    ),
    occurrence: occurrence?.copyWith(
      occurrenceAt: target,
      startAt: Value(occurrence.startAt?.add(days: daysDiff)),
      endAt: Value(occurrence.endAt?.add(days: daysDiff)),
      dueAt: Value(occurrence.dueAt?.add(days: daysDiff)),
    ),
  );
}
