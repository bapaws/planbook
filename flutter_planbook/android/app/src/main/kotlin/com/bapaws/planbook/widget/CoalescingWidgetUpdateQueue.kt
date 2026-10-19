package com.bapaws.planbook.widget

import java.util.concurrent.Executor

/** 仅合并尚未执行的相同组件请求；执行中到来的新数据会再刷新一次。 */
internal class CoalescingWidgetUpdateQueue(
    private val executor: Executor,
    private val onError: (String, Exception) -> Unit,
) {
    private class Request(
        var action: () -> Unit,
        val completions: MutableList<() -> Unit>,
    )

    private val pending = mutableMapOf<String, Request>()

    fun submit(key: String, action: () -> Unit, onComplete: () -> Unit) {
        synchronized(pending) {
            val queued = pending[key]
            if (queued != null) {
                queued.action = action
                queued.completions.add(onComplete)
                return
            }
            pending[key] = Request(action, mutableListOf(onComplete))
            executor.execute {
                val request = synchronized(pending) { pending.remove(key)!! }
                try {
                    request.action()
                } catch (e: Exception) {
                    onError(key, e)
                } finally {
                    request.completions.forEach { complete ->
                        try {
                            complete()
                        } catch (e: Exception) {
                            onError(key, e)
                        }
                    }
                }
            }
        }
    }
}
