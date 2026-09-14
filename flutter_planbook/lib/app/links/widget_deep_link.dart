import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

class WidgetCreateTaskRequest {
  const WidgetCreateTaskRequest({this.dueAt, this.priority});

  final Jiffy? dueAt;
  final TaskPriority? priority;
}

/// 小组件 deeplink 与主界面之间的一次性桥接。
///
/// RootTaskBloc 挂在 RootHomePage 下，AppLinksHandler 拿不到它。
/// 先记下待切换的日视图，RootHome 绑定后立刻消费。
class WidgetDeepLink {
  WidgetDeepLink._();

  static void Function(RootTaskViewType)? _handler;
  static RootTaskViewType? _pendingDayViewType;
  static void Function(WidgetCreateTaskRequest)? _createTaskHandler;
  static WidgetCreateTaskRequest? _pendingCreateTaskRequest;

  /// 小组件要求打开「今天的时间块」。
  static void openTodayTimeBlock() {
    const viewType = RootTaskViewType.timeBlock;
    final handler = _handler;
    if (handler != null) {
      handler(viewType);
      _pendingDayViewType = null;
    } else {
      _pendingDayViewType = viewType;
    }
  }

  /// RootHome 就绪后绑定；若已有 pending 则立即下发。
  static void bind(void Function(RootTaskViewType) handler) {
    _handler = handler;
    final pending = _pendingDayViewType;
    if (pending != null) {
      _pendingDayViewType = null;
      handler(pending);
    }
  }

  /// 请求创建任务。主页未就绪时先缓存，避免冷启动时把创建页压在 Splash 上。
  static void openCreateTask({Jiffy? dueAt, TaskPriority? priority}) {
    final request = WidgetCreateTaskRequest(
      dueAt: dueAt,
      priority: priority,
    );
    final handler = _createTaskHandler;
    if (handler != null) {
      handler(request);
      _pendingCreateTaskRequest = null;
    } else {
      _pendingCreateTaskRequest = request;
    }
  }

  /// RootHome 就绪后绑定创建入口；若冷启动期间已有请求则立即消费。
  static void bindCreateTask(
    void Function(WidgetCreateTaskRequest) handler,
  ) {
    _createTaskHandler = handler;
    final pending = _pendingCreateTaskRequest;
    if (pending != null) {
      _pendingCreateTaskRequest = null;
      handler(pending);
    }
  }

  static void unbind(void Function(RootTaskViewType) handler) {
    if (_handler == handler) {
      _handler = null;
    }
  }

  static void unbindCreateTask(
    void Function(WidgetCreateTaskRequest) handler,
  ) {
    if (_createTaskHandler == handler) {
      _createTaskHandler = null;
    }
  }
}
