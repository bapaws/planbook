import Foundation
import Flutter

/// 给 widget 端（如 `CompleteTaskIntent`）使用的派发器（iOS）。
///
/// 调用 `completeTask(taskId:)` 即可把"完成任务"请求转发到主 App 的 Flutter 端。
/// 注意：调用方需保证此 AppIntent 的 target membership 同时勾选了主 App 与 Widget Extension，
/// 这样系统会把 `perform()` 调度到主 App 进程（必要时后台冷启动 App），
/// 我们才能通过 `AppDelegate.flutterEngine` 拿到主 App 的 FlutterEngine。
public enum WidgetActionDispatcher {

    /// 触发 Flutter 端"完成 / 撤销完成"任务（toggle 语义）。
    ///
    /// 因为 widget AppIntent 触发时主 App 进程通常未启动，
    /// FlutterEngine 冷启动 + plugin 注册 + Dart 注册 handler 整链路需要时间，
    /// 默认超时 30 秒。
    /// - Returns: `true` 表示 Flutter 端已成功收到并执行；`false` 表示超时 / 错误。
    public static func completeTask(
        taskId: String,
        timeout: TimeInterval = 30
    ) async -> Bool {
        guard let channel = await EngineReadyTracker.shared.awaitChannel(timeout: timeout) else {
            NSLog("[PlanbookWidget] completeTask: channel not ready within %.1fs", timeout)
            return false
        }
        return await invokeOnMain(
            channel: channel,
            method: "completeTask",
            arguments: ["taskId": taskId]
        )
    }

    private static func invokeOnMain(
        channel: FlutterMethodChannel,
        method: String,
        arguments: Any?
    ) async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            DispatchQueue.main.async {
                channel.invokeMethod(method, arguments: arguments) { result in
                    if let error = result as? FlutterError {
                        NSLog("[PlanbookWidget] %@ error: %@ %@",
                              method, error.code, error.message ?? "")
                        continuation.resume(returning: false)
                    } else {
                        continuation.resume(returning: true)
                    }
                }
            }
        }
    }
}
