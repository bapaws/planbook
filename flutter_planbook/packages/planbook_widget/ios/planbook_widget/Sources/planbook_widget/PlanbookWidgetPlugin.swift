import Flutter
import UIKit

/// 处理 Dart ↔ native 之间的小组件事件桥接（iOS）。
public class PlanbookWidgetPlugin: NSObject, FlutterPlugin {

    public static let channelName = "com.bapaws.planbook/widget_actions"

    /// pending 完成状态在 App Group UserDefaults 中的 key。
    /// 必须与 `ios/Widgets/Core/WidgetSettings.swift` 中的 key 一致。
    private static let pendingCompletionKey = "widget_pending_completion_states"

    /// Dart 端通过 `setAppGroupId` 注入的 App Group ID。
    /// 没注入时 `clearPendingCompletion` 会回退到 standard UserDefaults，
    /// 在 widget 共享场景下基本不会命中——所以业务上必须先 `setAppGroupId`。
    private var appGroupId: String?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = PlanbookWidgetPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        EngineReadyTracker.shared.attach(channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "flutterReady":
            EngineReadyTracker.shared.markReady()
            result(nil)
        case "setAppGroupId":
            let args = call.arguments as? [String: Any]
            let id = (args?["appGroupId"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard let id, !id.isEmpty else {
                result(FlutterError(
                    code: "invalid-arg",
                    message: "setAppGroupId requires non-empty appGroupId",
                    details: nil
                ))
                return
            }
            appGroupId = id
            result(nil)
        case "clearPendingCompletion":
            let args = call.arguments as? [String: Any]
            guard let taskId = args?["taskId"] as? String, !taskId.isEmpty else {
                result(FlutterError(
                    code: "invalid-arg",
                    message: "clearPendingCompletion requires taskId",
                    details: nil
                ))
                return
            }
            clearPendingCompletion(taskId: taskId)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// 删除 App Group UserDefaults 中 `taskId` 对应的 pending 项。
    /// 字典空了就连 key 一起移除，保持 UserDefaults 干净。
    private func clearPendingCompletion(taskId: String) {
        let defaults = appGroupId.flatMap { UserDefaults(suiteName: $0) }
            ?? .standard
        var dict = defaults.dictionary(forKey: Self.pendingCompletionKey) ?? [:]
        guard dict.removeValue(forKey: taskId) != nil else { return }
        if dict.isEmpty {
            defaults.removeObject(forKey: Self.pendingCompletionKey)
        } else {
            defaults.set(dict, forKey: Self.pendingCompletionKey)
        }
    }
}
