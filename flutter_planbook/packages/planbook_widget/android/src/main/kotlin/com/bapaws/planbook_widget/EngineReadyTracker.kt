package com.bapaws.planbook_widget

import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume

/**
 * Flutter 引擎就绪状态追踪器。
 *
 * 工作流程：
 *   1. [PlanbookWidgetPlugin.onAttachedToEngine] 时通过 [attach] 注册 channel；
 *   2. Dart 端在 handler 注册完成后调用 `notifyReady`，触发 [markReady]；
 *   3. 调用方（[WidgetActionDispatcher]）通过 [awaitChannel] 等待两件事都满足后
 *      拿到 channel 进行 invokeMethod。
 *
 * 进程内单例，FlutterEngineCache 和当前进程绑定（headless engine 也使用同一个实例）。
 */
internal object EngineReadyTracker {

    private val lock = Any()

    @Volatile
    private var channel: MethodChannel? = null

    @Volatile
    private var isReady = false

    private val waiters = mutableListOf<(MethodChannel?) -> Unit>()

    /** 由 plugin attach 时调用 */
    fun attach(c: MethodChannel) {
        synchronized(lock) {
            channel = c
        }
        flushWaitersIfReady()
    }

    /** 由 plugin detach 时调用 */
    fun detach() {
        val pending: List<(MethodChannel?) -> Unit>
        synchronized(lock) {
            channel = null
            isReady = false
            pending = waiters.toList()
            waiters.clear()
        }
        pending.forEach { it.invoke(null) }
    }

    /** Dart 端 `notifyReady` 触发 */
    fun markReady() {
        synchronized(lock) {
            isReady = true
        }
        flushWaitersIfReady()
    }

    private fun flushWaitersIfReady() {
        val ch: MethodChannel?
        val toResume: List<(MethodChannel?) -> Unit>
        synchronized(lock) {
            if (!isReady || channel == null) return
            ch = channel
            toResume = waiters.toList()
            waiters.clear()
        }
        toResume.forEach { it.invoke(ch) }
    }

    /**
     * 等待 channel 就绪。超时返回 null。
     * 调用方应在协程作用域内执行。
     */
    suspend fun awaitChannel(timeoutMs: Long): MethodChannel? =
        withTimeoutOrNull(timeoutMs) {
            synchronized(lock) {
                if (isReady && channel != null) return@withTimeoutOrNull channel
            }
            suspendCancellableCoroutine<MethodChannel?> { cont ->
                val callback: (MethodChannel?) -> Unit = { ch ->
                    if (cont.isActive) cont.resume(ch)
                }
                synchronized(lock) {
                    if (isReady && channel != null) {
                        cont.resume(channel)
                        return@suspendCancellableCoroutine
                    }
                    waiters.add(callback)
                }
                cont.invokeOnCancellation {
                    synchronized(lock) { waiters.remove(callback) }
                }
            }
        }
}
