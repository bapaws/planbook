import 'package:planbook_api/planbook_api.dart';

/// 任务闹钟调度器：为任务的 [EventAlarm] 调度/取消本地通知。
///
/// 由 app 层实现，在从 Supabase 同步任务后可为同步下来的任务统一调度闹钟。
abstract class TaskAlarmScheduler {
  /// 为任务的所有闹钟调度本地通知。
  Future<void> scheduleForTask(Task task);

  /// 取消该任务已调度的所有闹钟通知。
  Future<void> cancelForTask(String taskId);
}
