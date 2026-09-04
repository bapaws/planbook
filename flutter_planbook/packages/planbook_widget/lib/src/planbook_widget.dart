import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:planbook_widget/src/widget_action_handler.dart';

/// Planbook 小组件 ↔ App 事件桥接入口。
///
/// 用法（在主 App `bootstrap()` 完成、`TasksRepository` 等已就绪后）：
///
/// ```dart
/// // 1. 让插件知道用哪个 App Group 写 UserDefaults（仅 iOS 上 pending 状态需要）
/// PlanbookWidget.setAppGroupId(kAppGroupId);
///
/// // 2. 注册 widget 完成任务回调
/// PlanbookWidget.registerCompleteTaskHandler((taskId, {occurrenceAt}) async {
///   final occ = occurrenceAt == null ? null : Jiffy.parse(occurrenceAt);
///   final task = await tasksRepository.getTaskEntityById(
///     taskId,
///     occurrenceAt: occ,
///   );
///   if (task == null) return;
///   await tasksRepository.completeTask(task, occurrenceAt: occ);
///   await PlanbookWidget.clearPendingCompletion(taskId);
/// });
/// await PlanbookWidget.notifyReady();
/// ```
class PlanbookWidget {
  PlanbookWidget._();

  static const MethodChannel _channel = MethodChannel(
    'com.bapaws.planbook/widget_actions',
  );

  static WidgetCompleteTaskHandler? _completeTaskHandler;
  static bool _handlerAttached = false;

  /// 注册"完成任务"回调（toggle 语义）。
  ///
  /// 多次调用会覆盖上一次注册的 handler。
  /// 内部会在第一次调用时绑定 [MethodChannel.setMethodCallHandler]。
  static void registerCompleteTaskHandler(
    WidgetCompleteTaskHandler handler,
  ) {
    _completeTaskHandler = handler;
    _ensureHandlerAttached();
  }

  static void _ensureHandlerAttached() {
    if (_handlerAttached) return;
    _channel.setMethodCallHandler(_handleCall);
    _handlerAttached = true;
  }

  /// 通知 native 端 Flutter 已经就绪，可以开始派发事件。
  ///
  /// 必须在 [registerCompleteTaskHandler] 调用之后再调。
  /// native 端的 `WidgetActionDispatcher` 会一直等待这个信号才发起 MethodChannel 调用。
  static Future<void> notifyReady() async {
    try {
      await _channel.invokeMethod<void>('flutterReady');
    } on PlatformException catch (e) {
      developer.log(
        'PlanbookWidget.notifyReady failed: ${e.code} ${e.message}',
        name: 'PlanbookWidget',
      );
    }
  }

  /// 配置 iOS 端 pending 完成状态使用的 App Group。
  ///
  /// iOS widget AppIntent 在翻转任务状态时会先把目标状态写入 App Group
  /// UserDefaults 的 pending 表，让 widget UI 即时反馈。Flutter 这一侧
  /// 在 DB 写完后通过 [clearPendingCompletion] 把对应条目清掉，让 widget
  /// 下一次刷新读到权威状态。clearPendingCompletion 需要知道 App Group ID
  /// 才能打开正确的 UserDefaults，故请在 `bootstrap()` 中先调一次此方法。
  ///
  /// Android 上不使用 App Group 机制，本调用无副作用。
  static Future<void> setAppGroupId(String appGroupId) async {
    try {
      await _channel.invokeMethod<void>(
        'setAppGroupId',
        {'appGroupId': appGroupId},
      );
    } on MissingPluginException {
      // Android 端没有实现这个方法，没关系。
    } on PlatformException catch (e) {
      developer.log(
        'PlanbookWidget.setAppGroupId failed: ${e.code} ${e.message}',
        name: 'PlanbookWidget',
      );
    }
  }

  /// 清除 iOS widget 端为 [taskId] 临时记录的 pending 完成状态。
  ///
  /// 在 Flutter 端把任务的真实状态写入 DB / Supabase 之后调用，让 widget
  /// 下一次 reloadTimelines 读到权威 DB 状态而不是优先 pending 缓存。
  ///
  /// Android 上 widget 直接调 Flutter 完成 DB 写入，没有 pending 中间态，
  /// 故本调用在 Android 上是 no-op。
  static Future<void> clearPendingCompletion(String taskId) async {
    if (taskId.isEmpty) return;
    try {
      await _channel.invokeMethod<void>(
        'clearPendingCompletion',
        {'taskId': taskId},
      );
    } on MissingPluginException {
      // Android 端没有实现这个方法，没关系。
    } on PlatformException catch (e) {
      developer.log(
        'PlanbookWidget.clearPendingCompletion failed: ${e.code} ${e.message}',
        name: 'PlanbookWidget',
      );
    }
  }

  static Future<dynamic> _handleCall(MethodCall call) async {
    switch (call.method) {
      case 'completeTask':
        final args = (call.arguments as Map?)?.cast<String, dynamic>();
        final taskId = args?['taskId'] as String?;
        if (taskId == null || taskId.isEmpty) {
          throw PlatformException(
            code: 'invalid-arg',
            message: 'completeTask requires taskId',
          );
        }
        final occurrenceAt = args?['occurrenceAt'] as String?;
        final handler = _completeTaskHandler;
        if (handler == null) {
          throw PlatformException(
            code: 'no-handler',
            message: 'completeTask handler not registered',
          );
        }
        try {
          await handler(taskId, occurrenceAt: occurrenceAt);
          return true;
        } on Object catch (e, st) {
          developer.log(
            'completeTask handler error: $e',
            name: 'PlanbookWidget',
            stackTrace: st,
          );
          throw PlatformException(
            code: 'handler-error',
            message: e.toString(),
          );
        }
      default:
        throw MissingPluginException('Method ${call.method} not implemented');
    }
  }
}
