package com.bapaws.planbook.widget

import java.util.concurrent.Executor
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CoalescingWidgetUpdateQueueTest {
    @Test
    fun configurationSavedDuringRenderWinsAfterOldBroadcastForBothKeyShapes() {
        // 系统更新可能包含多个 ID，配置更新只有单个 ID；两种 key 都必须串行。
        for (oldKey in listOf("provider:update:42", "provider:update:41,42")) {
            val executor = Executors.newSingleThreadExecutor()
            val captured = CountDownLatch(1)
            val release = CountDownLatch(1)
            val finished = CountDownLatch(1)
            val setting = AtomicReference("today")
            val rendered = AtomicReference("")
            val renderThread = AtomicReference<Thread>()
            val errors = AtomicReference<Exception>()
            val queue = CoalescingWidgetUpdateQueue(executor) { _, error -> errors.set(error) }
            try {
                queue.submit(oldKey, {
                    val snapshot = setting.get()
                    captured.countDown()
                    check(release.await(5, TimeUnit.SECONDS))
                    rendered.set(snapshot)
                }, {})
                assertTrue(captured.await(5, TimeUnit.SECONDS))
                setting.set("inbox")
                queue.submit("provider:update:42", {
                    renderThread.set(Thread.currentThread())
                    rendered.set(setting.get())
                }, { finished.countDown() })
                // 配置提交线程没有进行绘图；旧结果完成后，新配置才重新读取并发布。
                assertEquals("", rendered.get())
                release.countDown()
                assertTrue(finished.await(5, TimeUnit.SECONDS))
                assertEquals(null, errors.get())
                assertEquals("inbox", rendered.get())
                assertTrue(renderThread.get() !== Thread.currentThread())
            } finally {
                release.countDown()
                executor.shutdownNow()
            }
        }
    }

    @Test
    fun repeatedConfigurationsReadLatestSavedValueAndFinishEveryRequest() {
        val jobs = ArrayDeque<Runnable>()
        val settings = mutableMapOf(41 to "today", 42 to "today")
        val rendered = mutableMapOf<Int, String>()
        var completions = 0
        var renders = 0
        val queue = CoalescingWidgetUpdateQueue(Executor { jobs.add(it) }) { _, error -> throw error }
        for (mode in listOf("inbox", "overdue", "today")) {
            settings[42] = mode
            queue.submit("provider:update:42", {
                renders++
                rendered[42] = settings.getValue(42)
            }, { completions++ })
        }
        jobs.removeFirst().run()
        assertEquals(1, renders)
        assertEquals(3, completions)
        assertEquals(mapOf(42 to "today"), rendered)
        assertEquals("today", settings[41])
    }

    @Test
    fun failedOldRenderDoesNotPreventQueuedConfigurationRefresh() {
        val jobs = ArrayDeque<Runnable>()
        val errors = mutableListOf<Exception>()
        var rendered = ""
        var finished = 0
        val queue = CoalescingWidgetUpdateQueue(Executor { jobs.add(it) }) { _, error -> errors.add(error) }
        queue.submit("provider:update:41,42", { throw IllegalStateException("old read") }, { finished++ })
        queue.submit("provider:update:42", { rendered = "inbox" }, { finished++ })
        while (jobs.isNotEmpty()) jobs.removeFirst().run()
        assertEquals("inbox", rendered)
        assertEquals(2, finished)
        assertEquals(1, errors.size)
    }

    @Test
    fun queuedUpdatesUseLatestActionAndFinishEveryBroadcast() {
        val jobs = ArrayDeque<Runnable>()
        val results = mutableListOf<String>()
        val queue = CoalescingWidgetUpdateQueue(Executor { jobs.add(it) }) { _, error -> throw error }
        queue.submit("widget", { results.add("old") }, { results.add("finish-old") })
        queue.submit("widget", { results.add("new") }, { results.add("finish-new") })
        assertEquals(1, jobs.size)
        jobs.removeFirst().run()
        assertEquals(listOf("new", "finish-old", "finish-new"), results)
    }

    @Test
    fun updatesArrivingDuringRenderRunAfterCurrentResult() {
        val jobs = ArrayDeque<Runnable>()
        val results = mutableListOf<String>()
        val queue = CoalescingWidgetUpdateQueue(Executor { jobs.add(it) }) { _, error -> throw error }
        queue.submit("widget", {
            queue.submit("widget", { results.add("new") }, { results.add("finish-new") })
            results.add("old")
        }, { results.add("finish-old") })
        jobs.removeFirst().run()
        jobs.removeFirst().run()
        assertEquals(listOf("old", "finish-old", "new", "finish-new"), results)
    }

    @Test
    fun failuresStillFinishOtherBroadcastsAndAllowRetry() {
        val jobs = ArrayDeque<Runnable>()
        val errors = mutableListOf<Exception>()
        var finished = 0
        val queue = CoalescingWidgetUpdateQueue(Executor { jobs.add(it) }) { _, error -> errors.add(error) }
        queue.submit("widget", {}, { throw IllegalStateException("finish") })
        queue.submit("widget", { throw IllegalStateException("render") }, { finished++ })
        jobs.removeFirst().run()
        assertEquals(2, errors.size)
        assertEquals(1, finished)
        queue.submit("widget", {}, { finished++ })
        jobs.removeFirst().run()
        assertEquals(2, finished)
    }
}
