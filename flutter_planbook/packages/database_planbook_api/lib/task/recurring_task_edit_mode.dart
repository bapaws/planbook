/// 重复任务修改模式（Apple Calendar 风格）
///
/// 用于编辑任务时，让用户选择如何处理重复任务的修改
enum RecurringTaskEditMode {
  /// 仅此事件 - 创建分离实例，原始重复规则保持不变
  thisEventOnly,

  /// 此事件及将来事件 - 原始任务设置结束日期，创建新的重复任务
  thisAndFutureEvents,

  /// 所有事件 - 修改整个重复序列
  allEvents,
}

/// 重复任务删除模式（Apple Calendar 风格）
///
/// 用于删除任务时，让用户选择如何处理重复任务的删除
enum RecurringTaskDeleteMode {
  /// 仅此事件 - 软删除该实例的 occurrence
  thisEventOnly,

  /// 此事件及将来事件 - 原始重复规则结束于该实例前一天
  thisAndFutureEvents,

  /// 所有事件 - 软删除整个重复序列（主任务）
  allEvents,
}
