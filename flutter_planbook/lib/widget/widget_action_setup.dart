import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/task/service/task_action_service.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:planbook_widget/planbook_widget.dart';

/// 在主 App 启动流程末尾调用：把 widget 的 "完成任务" 事件接入到主 App 的
/// [TaskActionService]，并通知 native 端 Flutter 已就绪，可以开始派发事件。
///
/// 这样无论是 widget 上的勾选还是 App 内的勾选，最终都走同一套业务逻辑
/// （Supabase 同步、自动笔记、提醒取消等），保证两端行为一致。
///
/// 流程（iOS 两段式 AppIntent）：
///   1. widget AppIntent 把翻转后的目标状态写入 App Group UserDefaults 的
///      pending 表，Provider 在 reloadTimelines 时把 pending 覆盖到 UI；
///   2. AppIntent 链到主 App，主 App 这一侧通过 MethodChannel 触发本文件
///      中的 `_onCompleteTaskFromWidget`；
///   3. Flutter 走 `taskActionService.completeTask` 写 DB / Supabase /
///      自动笔记，然后调 `PlanbookWidget.clearPendingCompletion(taskId)`
///      清掉 widget 端的 pending 缓存，让 widget 下次刷新读到权威 DB。
Future<void> setupPlanbookWidgetActions({
  required TasksRepository tasksRepository,
  required TaskActionService taskActionService,
}) async {
  // 注入 App Group ID，让 iOS 端的 clearPendingCompletion 能打开正确的
  // App Group UserDefaults。Android 端是 no-op。
  await PlanbookWidget.setAppGroupId(kAppGroupId);

  PlanbookWidget.registerCompleteTaskHandler((taskId) async {
    await _onCompleteTaskFromWidget(
      taskId: taskId,
      tasksRepository: tasksRepository,
      taskActionService: taskActionService,
    );
  });

  await PlanbookWidget.notifyReady();
}

Future<void> _onCompleteTaskFromWidget({
  required String taskId,
  required TasksRepository tasksRepository,
  required TaskActionService taskActionService,
}) async {
  final task = await tasksRepository.getTaskEntityById(taskId);
  if (task == null) {
    developer.log(
      'completeTaskFromWidget: task not found id=$taskId',
      name: 'PlanbookWidget',
    );
    // 即使任务找不到，也清掉 pending，避免 widget 永远显示错误的乐观状态。
    await PlanbookWidget.clearPendingCompletion(taskId);
    return;
  }

  try {
    final activities = await taskActionService.completeTask(
      task: task,
      occurrenceAt: task.occurrence?.occurrenceAt,
    );

    // widget 端没法弹"编辑笔记"页，所以 service 内部会把 edit / createAndEdit
    // 都降级为 create。
    await taskActionService.resolveAutoNotes(
      activities: activities,
      task: task,
      widgetMode: true,
    );
  } finally {
    // 不管 completeTask 成不成功，都清 pending；失败时让 widget 回到 DB 的
    // 真实状态，而不是停留在乐观 UI 上。
    await PlanbookWidget.clearPendingCompletion(taskId);
  }
}
