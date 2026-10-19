package com.bapaws.planbook.widget

import java.util.concurrent.Executor
import org.junit.Assert.assertEquals
import org.junit.Test

class CoalescingWidgetUpdateQueueTest {
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
