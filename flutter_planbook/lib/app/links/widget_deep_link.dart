import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';

/// 小组件 deeplink 与主界面之间的一次性桥接。
///
/// RootTaskBloc 挂在 RootHomePage 下，AppLinksHandler 拿不到它。
/// 先记下待切换的日视图，RootHome 绑定后立刻消费。
class WidgetDeepLink {
  WidgetDeepLink._();

  static void Function(RootTaskViewType)? _handler;
  static RootTaskViewType? _pendingDayViewType;

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

  static void unbind(void Function(RootTaskViewType) handler) {
    if (_handler == handler) {
      _handler = null;
    }
  }
}
