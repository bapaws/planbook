package com.bapaws.planbook_widget

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume

/**
 * 给 widget 端（如 [com.bapaws.planbook.widget.WidgetClickReceiver]）使用的派发器。
 *
 * 调用 [completeTask] 即可把"完成任务"请求转发到主 App 的 Flutter 端：
 *   - 若主 App 进程已启动且 engine 在 cache 中，直接复用；
 *   - 否则启动 headless [FlutterEngine] 跑 Dart `main()` 入口，等其完成
 *     `PlanbookWidget.notifyReady` 之后再下发 invokeMethod；
 *   - 超时仍未就绪返回 false，由调用方走本地 DB 兜底。
 */
object WidgetActionDispatcher {

    private const val TAG = "PlanbookWidgetDispatch"

    /** 与 [com.bapaws.planbook.MainActivity] 中缓存 key 保持一致 */
    const val ENGINE_CACHE_KEY = "main_engine"

    /**
     * 触发 Flutter 端"完成 / 撤销完成"任务。
     *
     * @return true 表示 Flutter 端已成功收到并执行；false 表示超时 / engine 不可用 / 错误。
     */
    suspend fun completeTask(
        context: Context,
        taskId: String,
        occurrenceAt: String? = null,
        timeoutMs: Long = 30000L,
    ): Boolean {
        val channel = obtainChannel(context, timeoutMs) ?: run {
            Log.w(TAG, "completeTask: channel not ready within ${timeoutMs}ms")
            return false
        }
        val args = mutableMapOf<String, Any>("taskId" to taskId)
        if (!occurrenceAt.isNullOrEmpty()) {
            args["occurrenceAt"] = occurrenceAt
        }
        return invokeOnMain(channel, "completeTask", args, timeoutMs)
    }

    /**
     * 拿到一个就绪的 MethodChannel：先复用 main_engine cache，否则拉起 headless engine。
     */
    private suspend fun obtainChannel(
        context: Context,
        timeoutMs: Long,
    ): MethodChannel? {
        val cached = FlutterEngineCache.getInstance().get(ENGINE_CACHE_KEY)
        if (cached == null) {
            ensureHeadlessEngine(context.applicationContext)
        }
        return EngineReadyTracker.awaitChannel(timeoutMs)
    }

    /**
     * 主 App 进程未启动时拉起一个 headless engine 跑 Dart `main()`。
     * Plugin attach、Dart bootstrap 完成后，[EngineReadyTracker.markReady] 会被触发。
     */
    private fun ensureHeadlessEngine(appContext: Context) {
        // 必须切到主线程创建 engine（FlutterEngine 内部访问 main looper）
        runOnMainBlocking {
            if (FlutterEngineCache.getInstance().get(ENGINE_CACHE_KEY) != null) return@runOnMainBlocking

            val loader = FlutterInjector.instance().flutterLoader()
            if (!loader.initialized()) {
                loader.startInitialization(appContext)
            }
            loader.ensureInitializationComplete(appContext, null)

            val engine = FlutterEngine(appContext)
            val entrypoint = DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                "main",
            )
            engine.dartExecutor.executeDartEntrypoint(entrypoint)
            FlutterEngineCache.getInstance().put(ENGINE_CACHE_KEY, engine)
            Log.d(TAG, "headless FlutterEngine started")
        }
    }

    private suspend fun invokeOnMain(
        channel: MethodChannel,
        method: String,
        args: Any?,
        timeoutMs: Long,
    ): Boolean = withTimeoutOrNull(timeoutMs) {
        suspendCancellableCoroutine<Boolean> { cont ->
            Handler(Looper.getMainLooper()).post {
                channel.invokeMethod(
                    method,
                    args,
                    object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            if (cont.isActive) cont.resume(true)
                        }

                        override fun error(code: String, message: String?, details: Any?) {
                            Log.e(TAG, "$method error: $code $message")
                            if (cont.isActive) cont.resume(false)
                        }

                        override fun notImplemented() {
                            Log.e(TAG, "$method notImplemented")
                            if (cont.isActive) cont.resume(false)
                        }
                    },
                )
            }
        }
    } ?: false

    private fun runOnMainBlocking(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            val latch = java.util.concurrent.CountDownLatch(1)
            Handler(Looper.getMainLooper()).post {
                try {
                    block()
                } finally {
                    latch.countDown()
                }
            }
            latch.await()
        }
    }
}
