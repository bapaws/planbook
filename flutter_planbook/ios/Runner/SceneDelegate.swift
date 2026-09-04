import Flutter
import UIKit

/// iOS 13+ Scene 生命周期入口。
///
/// UI 与后台 Widget Action 共用 AppDelegate 中预启动的 FlutterEngine，避免重复
/// 执行 Dart `main()`，同时让 Flutter 及插件收到完整的 Scene 生命周期回调。
final class SceneDelegate: FlutterSceneDelegate {
    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard
            let windowScene = scene as? UIWindowScene,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else {
            return
        }

        let controller = FlutterViewController(
            engine: appDelegate.flutterEngine,
            nibName: nil,
            bundle: nil
        )
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = controller
        self.window = window
        window.makeKeyAndVisible()

        super.scene(
            scene,
            willConnectTo: session,
            options: connectionOptions
        )
    }
}
