//
//  CompleteTaskIntent.swift
//  Widgets
//
//  标记任务完成 / 撤销完成 Intent
//

import AppIntents
import WidgetKit

#if canImport(planbook_widget)
    import planbook_widget
#endif

/// 标记任务完成 / 撤销完成
///
/// 该 intent 在 widget extension 进程内执行：
///   1. 把翻转后的目标状态写入 App Group UserDefaults 的 pending 表，
///      让 Provider 在下一次 reloadTimelines 时把覆盖值反映到 UI；
///   2. 通过 `opensIntent` 唤起 `_CompleteTaskIntent`，由它在主 App 进程
///      内调用 Flutter 完成真实的 DB / Supabase 写入。
///
/// 重点：widget 进程**不再直接写 DB**。pending 只是给 UI 用的乐观状态，
/// Flutter 端跑完业务后会通过 MethodChannel 清除对应条目。
@available(iOS 17.0, *)
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.completeTask.title"
    static var description: IntentDescription? = "intent.completeTask.description"

    static var isDiscoverable: Bool { false }

    @Parameter(title: "Task ID")
    var taskId: String

    init() {}

    init(taskId: String) {
        self.taskId = taskId
    }

    /// 返回 IntentResult & OpensIntent 是为了让系统在主 App 进程执行 `perform()`。
    /// 这样我们才能通过 `AppDelegate.flutterEngine` 拿到主 App 的 FlutterEngine，
    /// 从而通过 MethodChannel 调用 Flutter 端的方法。
    ///
    /// 注意：必须返回 IntentResult & OpensIntent，否则会导致崩溃，无法执行 OpensIntent。
    func perform() async throws -> some IntentResult & OpensIntent {
        // 1. 计算翻转后的目标状态——优先看 pending（防止用户连点时基于 stale DB 翻转），
        //    其次回落到 DB 的真实状态；都拿不到就当作未完成。
        let current =
            WidgetSettings.pendingCompletion(forTaskId: taskId)
                ?? WidgetDatabase.shared.isTaskCompleted(taskId: taskId)
                ?? false
        let newCompleted = !current

        // 2. 写入 pending，让下一次 reload 立刻反馈。
        WidgetSettings.setPendingCompletion(taskId: taskId, completed: newCompleted)

        // 3. 立刻刷新所有四象限 widget。
        WidgetCenter.shared.reloadTimelines(ofKind: kQuadrantWidgetLargeKind)
        WidgetCenter.shared.reloadTimelines(ofKind: kQuadrantWidgetSmallKind)

        // 4. 链到 `_CompleteTaskIntent`：它是 LiveActivityIntent，会被系统调度
        //    到主 App 进程，在那里把 toggle 请求透传给 Flutter 跑完整业务链路。
        return .result(opensIntent: _CompleteTaskIntent(taskId: taskId))
    }
}

/// `CompleteTaskIntent` 的"主 App 端"分身。
///
/// 通过 `LiveActivityIntent` 协议强制在主 App 进程执行 `perform()`，
/// 这样 `canImport(planbook_widget)` 才会为 true，能调到主 App 注册的
/// MethodChannel handler。
@available(iOS 17.0, *)
struct _CompleteTaskIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "intent.completeTask.title"
    static var description: IntentDescription? = "intent.completeTask.description"

    static var isDiscoverable: Bool { false }

    @Parameter(title: "Task ID")
    var taskId: String

    init() {}

    init(taskId: String) {
        self.taskId = taskId
    }

    func perform() async throws -> some IntentResult {
        #if canImport(planbook_widget)
            _ = await WidgetActionDispatcher.completeTask(taskId: taskId)
        #endif

        return .result()
    }
}
