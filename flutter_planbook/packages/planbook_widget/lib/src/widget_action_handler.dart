/// Widget 端触发"完成 / 撤销完成"任务时的回调签名（toggle 语义）。
///
/// 由主 App 注册到 `PlanbookWidget.registerCompleteTaskHandler`，
/// 收到 native 派发的请求后，由 App 自己用现有 `TasksRepository` 等业务
/// 接口完成 toggle 与自动笔记创建。
///
/// 实现内部应当：
///   - 自行判断当前任务状态决定是完成还是撤销（与 widget 端无关）
///   - 处理重复任务的 occurrenceAt
///   - 处理自动笔记规则（widget 端无法弹编辑器，所以 `edit` / `createAndEdit`
///     都应降级为 `create`）
typedef WidgetCompleteTaskHandler =
    Future<void> Function(String taskId, {String? occurrenceAt});
