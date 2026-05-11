import Foundation
import Flutter

/// Flutter 引擎就绪状态追踪器（iOS）。
///
/// 工作流程：
///   1. `PlanbookWidgetPlugin.register(with:)` 时通过 `attach(channel:)` 注册 channel；
///   2. Dart 端注册完 handler 后调用 `notifyReady`，触发 `markReady()`；
///   3. 调用方（如 `WidgetActionDispatcher`）通过 `awaitChannel(timeout:)` 拿到 channel。
///
/// 单例线程安全；channel 与 ready 信号都满足后才会唤醒等待者。
public final class EngineReadyTracker {

    public static let shared = EngineReadyTracker()

    private let lock = NSLock()
    private var channel: FlutterMethodChannel?
    private var isReady: Bool = false
    private var waiters: [(FlutterMethodChannel?) -> Void] = []

    private init() {}

    /// Plugin attach 时调用。
    public func attach(channel: FlutterMethodChannel) {
        lock.lock()
        self.channel = channel
        lock.unlock()
        flushWaitersIfReady()
    }

    /// Plugin detach 时调用，清空状态以避免下一次进程冷启动时拿到陈旧引用。
    public func detach() {
        lock.lock()
        channel = nil
        isReady = false
        let pending = waiters
        waiters.removeAll()
        lock.unlock()
        pending.forEach { $0(nil) }
    }

    /// Dart 端 `notifyReady` 触发。
    public func markReady() {
        lock.lock()
        isReady = true
        lock.unlock()
        flushWaitersIfReady()
    }

    private func flushWaitersIfReady() {
        lock.lock()
        guard isReady, let ch = channel else {
            lock.unlock()
            return
        }
        let toResume = waiters
        waiters.removeAll()
        lock.unlock()
        toResume.forEach { $0(ch) }
    }

    /// 等待 channel 就绪。超时返回 nil。
    public func awaitChannel(timeout: TimeInterval) async -> FlutterMethodChannel? {
        // 快路径
        lock.lock()
        if isReady, let ch = channel {
            lock.unlock()
            return ch
        }
        lock.unlock()

        return await withTaskGroup(of: FlutterMethodChannel?.self) { group in
            group.addTask { [weak self] in
                await withCheckedContinuation { (cont: CheckedContinuation<FlutterMethodChannel?, Never>) in
                    guard let self = self else {
                        cont.resume(returning: nil)
                        return
                    }
                    self.lock.lock()
                    if self.isReady, let ch = self.channel {
                        self.lock.unlock()
                        cont.resume(returning: ch)
                        return
                    }
                    self.waiters.append { ch in cont.resume(returning: ch) }
                    self.lock.unlock()
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }
}
