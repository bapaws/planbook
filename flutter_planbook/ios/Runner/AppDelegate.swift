import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    /// 预启动并持有 FlutterEngine。
    ///
    /// - 主 App UI 启动时由 SceneDelegate 复用本 engine。
    /// - widget AppIntent 触发后台冷启动 App 时，本 engine 也会被立刻拉起，
    ///   `PlanbookWidget` 注册到的 MethodChannel 才能被 `WidgetActionDispatcher`
    ///   通过 `EngineReadyTracker` 等到。
    ///
    /// 注意：必须 **不能** 让 Main.storyboard 默认创建另一个 FlutterViewController，
    /// 否则会出现两个 FlutterEngine 并行跑 `main()` 的问题。
    /// Info.plist 中已移除 `UIMainStoryboardFile` 字段，root 由 SceneDelegate 创建。
    lazy var flutterEngine = FlutterEngine(name: "main_engine")

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        flutterEngine.run()
        GeneratedPluginRegistrant.register(with: flutterEngine)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
