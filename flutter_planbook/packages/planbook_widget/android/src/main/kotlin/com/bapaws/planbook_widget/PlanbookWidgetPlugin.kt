package com.bapaws.planbook_widget

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * 处理 Dart ↔ native 之间的小组件事件桥接。
 *
 * Dart 端通过 [PlanbookWidget] 调用 `notifyReady` 表示已经注册好 handler；
 * native 端的 [WidgetActionDispatcher] 会等待这一信号后再发起 `completeTask` 等调用。
 */
class PlanbookWidgetPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            binding.binaryMessenger,
            CHANNEL_NAME,
        )
        channel.setMethodCallHandler(this)
        EngineReadyTracker.attach(channel)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "flutterReady" -> {
                EngineReadyTracker.markReady()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        EngineReadyTracker.detach()
    }

    companion object {
        const val CHANNEL_NAME = "com.bapaws.planbook/widget_actions"
    }
}
