/// 标识最近一次任务拖拽被目标接受后执行的业务操作。
enum TaskDragOperation {
  /// 任务被移动（改日期 / 改优先级 / 改标签等），源列表应移除。
  move,

  /// 任务被投放到笔记卡片，仅追加文本，源列表保持不变。
  noteAppend,
}

/// 全局通知器，用于在 `Draggable.onDragCompleted` 与 `DragTarget.onAccept`
/// 之间同步最近一次拖拽的业务操作类型。
///
/// Flutter 的 drag-n-drop 没有内置渠道让源组件知道目标执行了什么操作，
/// 而源组件需要在释放瞬间同步决定是否从列表中移除任务，因此使用本单例做临时沟通。
/// 一次拖拽只会有一个目标被接受，单例状态是安全的。
class TaskDragOperationNotifier {
  TaskDragOperationNotifier._();

  static final TaskDragOperationNotifier instance =
      TaskDragOperationNotifier._();

  /// 最近一次被接受的拖拽操作类型；由 `DragTarget` 设置，`Draggable` 读取并清空。
  TaskDragOperation? operation;

  /// 读取并清空当前操作类型。
  TaskDragOperation? take() {
    final result = operation;
    operation = null;
    return result;
  }
}
