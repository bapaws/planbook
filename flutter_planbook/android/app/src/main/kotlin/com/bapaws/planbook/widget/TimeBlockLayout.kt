package com.bapaws.planbook.widget

import android.database.Cursor
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** 时间块任务（仅渲染所需列） */
data class TimeBlockTask(
    val taskId: String,
    val title: String,
    val priority: TaskPriority,
    val startAtMillis: Long,
    val endAtMillis: Long,
    val occurrenceAt: String?,
    val isCompleted: Boolean,
) {
    val startMinutes: Int get() = TimeBlockLayout.minutesFromTodayStart(startAtMillis)
    val endMinutes: Int get() = TimeBlockLayout.minutesFromTodayStart(endAtMillis)
}

data class TimeBlockLayoutItem(
    val task: TimeBlockTask,
    val top: Float,
    val height: Float,
    val startMinutes: Int,
    val endMinutes: Int,
    val timeRangeLabel: String,
    val columnCount: Int = 1,
    val columnIndex: Int = 0,
    val widthFactor: Float = 1f,
)

data class TimeBlockHit(
    val task: TimeBlockTask,
    val left: Float,
    val top: Float,
    val width: Float,
    val height: Float,
)

/**
 * 移植 Flutter `buildTaskTimeBlockLayoutItems`：按窗口裁剪、重叠分列。
 */
object TimeBlockLayout {
    const val DAY_MINUTES = 24 * 60
    const val APP_HOUR_HEIGHT = 60f
    const val APP_MIN_BLOCK_HEIGHT = 24f
    const val TIME_LABEL_WIDTH_DP = 36f
    const val HEADER_HEIGHT_DP = 22f

    fun minutesFromTodayStart(millis: Long): Int {
        val cal = Calendar.getInstance()
        cal.timeInMillis = millis
        val start = cal.clone() as Calendar
        start.set(Calendar.HOUR_OF_DAY, 0)
        start.set(Calendar.MINUTE, 0)
        start.set(Calendar.SECOND, 0)
        start.set(Calendar.MILLISECOND, 0)
        return ((millis - start.timeInMillis) / 60_000L).toInt()
    }

    fun nowMinutes(): Int = minutesFromTodayStart(System.currentTimeMillis())

    fun parseIso(raw: String?): Long? {
        if (raw.isNullOrBlank()) return null
        val truncated = if (raw.length >= 19) raw.substring(0, 19) + "Z" else raw
        return try {
            val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
            fmt.timeZone = TimeZone.getTimeZone("UTC")
            fmt.parse(truncated)?.time
        } catch (_: Exception) {
            null
        }
    }

    fun formatTimeRange(startMillis: Long, endMillis: Long): String {
        val fmt = SimpleDateFormat("HH:mm", Locale.getDefault())
        return "${fmt.format(Date(startMillis))} – ${fmt.format(Date(endMillis))}"
    }

    fun formatHourLabel(hour: Int): String = String.format(Locale.US, "%02d:00", hour)

    fun formatNowLabel(minutes: Int): String {
        val hour = minutes / 60
        val minute = minutes % 60
        return String.format(Locale.US, "%02d:%02d", hour, minute)
    }

    fun mediumWindow(nowMinutes: Int, visibleMinutes: Int = 4 * 60): Pair<Int, Int> {
        val maxStart = maxOf(0, DAY_MINUTES - visibleMinutes)
        val start = minOf(maxOf(nowMinutes - visibleMinutes / 3, 0), maxStart)
        return start to (start + visibleMinutes)
    }

    /** 窗口内需要对齐的整点；中号窗口不一定从整点开始。 */
    fun visibleHours(windowStart: Int, windowEnd: Int): List<Int> {
        val hours = mutableListOf<Int>()
        var hour = windowStart / 60
        if (hour * 60 < windowStart) hour += 1
        while (hour * 60 < windowEnd) {
            hours.add(hour)
            hour += 1
        }
        return hours
    }

    fun minBlockHeight(hourHeight: Float): Float =
        maxOf(14f, hourHeight * (APP_MIN_BLOCK_HEIGHT / APP_HOUR_HEIGHT))

    fun taskFromCursor(cursor: Cursor): TimeBlockTask? {
        val startRaw = cursor.getStringOrNull("start_at") ?: return null
        val start = parseIso(startRaw) ?: return null
        val endRaw = cursor.getStringOrNull("end_at")
        var end = parseIso(endRaw) ?: (start + 60 * 60 * 1000)
        if (end <= start) end = start + 15 * 60 * 1000
        val completedAt = cursor.getStringOrNull("completed_at")
        val activityDeletedAt = cursor.getStringOrNull("activity_deleted_at")
        return TimeBlockTask(
            taskId = cursor.getString(cursor.getColumnIndexOrThrow("id")),
            title = cursor.getString(cursor.getColumnIndexOrThrow("title")) ?: "",
            priority = TaskPriority.fromRawValue(cursor.getStringOrNull("priority")),
            startAtMillis = start,
            endAtMillis = end,
            occurrenceAt = cursor.getStringOrNull("occurrence_at"),
            isCompleted = completedAt != null && activityDeletedAt == null,
        )
    }

    fun overlayPending(
        tasks: List<TimeBlockTask>,
        pending: Map<String, Boolean>,
    ): List<TimeBlockTask> {
        if (pending.isEmpty()) return tasks
        return tasks.map { task ->
            val target = pending[task.taskId]
            if (target == null || target == task.isCompleted) task
            else task.copy(isCompleted = target)
        }
    }

    fun layout(
        tasks: List<TimeBlockTask>,
        windowStart: Int,
        windowEnd: Int,
        hourHeight: Float,
    ): List<TimeBlockLayoutItem> {
        val minHeight = minBlockHeight(hourHeight)
        val items = mutableListOf<TimeBlockLayoutItem>()
        for (task in tasks) {
            var start = maxOf(task.startMinutes, windowStart)
            var end = minOf(task.endMinutes, windowEnd)
            if (end <= start) continue
            if (end - start < 5) end = minOf(start + 15, windowEnd)
            if (end <= start) continue
            val top = (start - windowStart) / 60f * hourHeight
            var height = (end - start) / 60f * hourHeight
            if (height < minHeight) height = minHeight
            val startMillis = todayStartMillis() + start * 60_000L
            val endMillis = todayStartMillis() + end * 60_000L
            items.add(
                TimeBlockLayoutItem(
                    task = task,
                    top = top,
                    height = height,
                    startMinutes = start,
                    endMinutes = end,
                    timeRangeLabel = formatTimeRange(startMillis, endMillis),
                ),
            )
        }
        items.sortBy { it.top }

        val clusters = mutableListOf<MutableList<TimeBlockLayoutItem>>()
        for (item in items) {
            var added = false
            for (cluster in clusters) {
                val last = cluster.last()
                if (item.top < last.top + last.height) {
                    cluster.add(item)
                    added = true
                    break
                }
            }
            if (!added) clusters.add(mutableListOf(item))
        }

        val result = mutableListOf<TimeBlockLayoutItem>()
        for (cluster in clusters) {
            val columns = mutableListOf<MutableList<TimeBlockLayoutItem>>()
            for (item in cluster) {
                var placed = false
                for (column in columns) {
                    val last = column.last()
                    if (item.top >= last.top + last.height - 0.001f) {
                        column.add(item)
                        placed = true
                        break
                    }
                }
                if (!placed) columns.add(mutableListOf(item))
            }
            val columnCount = columns.size
            columns.forEachIndexed { columnIndex, column ->
                for (item in column) {
                    result.add(
                        item.copy(
                            columnCount = columnCount,
                            columnIndex = columnIndex,
                            widthFactor = 1f / columnCount,
                        ),
                    )
                }
            }
        }
        result.sortBy { it.top }
        return result
    }

    private fun todayStartMillis(): Long {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun Cursor.getStringOrNull(column: String): String? {
        val idx = getColumnIndex(column)
        if (idx < 0 || isNull(idx)) return null
        return getString(idx)
    }
}
