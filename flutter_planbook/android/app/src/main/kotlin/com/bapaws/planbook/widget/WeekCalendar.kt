package com.bapaws.planbook.widget

import android.content.Context
import com.bapaws.planbook.R
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

object WeekCalendar {
    private val dayFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)

    fun startOfWeek(now: Long = System.currentTimeMillis()): Calendar {
        val cal = Calendar.getInstance()
        cal.timeInMillis = now
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        cal.set(Calendar.DAY_OF_WEEK, cal.firstDayOfWeek)
        return cal
    }

    fun days(start: Calendar, count: Int): List<Calendar> {
        return (0 until count).map { offset ->
            (start.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, offset) }
        }
    }

    fun dayKey(cal: Calendar): String = dayFormat.format(cal.time)

    fun endExclusive(start: Calendar, dayCount: Int): Calendar {
        return (start.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, dayCount) }
    }

    fun shortWeekday(cal: Calendar): String {
        val fmt = SimpleDateFormat("EEE", Locale.getDefault())
        return fmt.format(cal.time)
    }

    fun dayNumber(cal: Calendar): String = cal.get(Calendar.DAY_OF_MONTH).toString()

    fun isToday(cal: Calendar): Boolean {
        val now = Calendar.getInstance()
        return now.get(Calendar.YEAR) == cal.get(Calendar.YEAR) &&
            now.get(Calendar.DAY_OF_YEAR) == cal.get(Calendar.DAY_OF_YEAR)
    }

    fun weekRangeLabel(context: Context, days: List<Calendar>, twoWeeks: Boolean): String {
        if (days.isEmpty()) return ""
        if (twoWeeks && days.size >= 8) {
            val first = days.first().get(Calendar.WEEK_OF_YEAR)
            val last = days.last().get(Calendar.WEEK_OF_YEAR)
            return context.getString(R.string.widget_week_weeks_capsule, first, last)
        }
        val startFmt = SimpleDateFormat("MMM d", Locale.getDefault())
        val endFmt = SimpleDateFormat("d", Locale.getDefault())
        return "${startFmt.format(days.first().time)}–${endFmt.format(days.last().time)}"
    }

    fun groupTasks(tasks: List<WeekTask>, days: List<Calendar>): Map<String, List<WeekTask>> {
        val grouped = days.associate { dayKey(it) to mutableListOf<WeekTask>() }.toMutableMap()
        val keys = grouped.keys
        for (task in tasks) {
            for (key in dayKeys(task, days)) {
                if (key in keys) grouped.getValue(key).add(task)
            }
        }
        return grouped
    }

    fun overlayPending(context: Context, tasks: List<WeekTask>): List<WeekTask> {
        val pending = WidgetSettings.getPendingCompletions(context)
        if (pending.isEmpty()) return tasks
        return tasks.map { task ->
            val target = pending[task.taskId]
            if (target == null || target == task.isCompleted) task else task.copy(isCompleted = target)
        }
    }

    fun progress(tasks: List<WeekTask>): Pair<Int, Int> {
        val unique = LinkedHashMap<String, WeekTask>()
        for (task in tasks) unique.putIfAbsent(task.id, task)
        val completed = unique.values.count { it.isCompleted }
        return completed to unique.size
    }

    private fun dayKeys(task: WeekTask, days: List<Calendar>): List<String> {
        val rangeKeys = days.map { dayKey(it) }.toSet()
        task.dueAt?.let {
            val key = dayKey(millisToDay(it))
            return if (key in rangeKeys) listOf(key) else emptyList()
        }
        if (task.startAt != null && task.endAt != null) {
            return days.mapNotNull { day ->
                val start = startOfDayMillis(day)
                val next = start + 24L * 60 * 60 * 1000
                if (task.startAt < next && task.endAt >= start) dayKey(day) else null
            }
        }
        task.startAt?.let {
            val key = dayKey(millisToDay(it))
            return if (key in rangeKeys) listOf(key) else emptyList()
        }
        task.occurrenceAt?.let { raw ->
            val millis = TimeBlockLayout.parseIso(raw) ?: return emptyList()
            val key = dayKey(millisToDay(millis))
            return if (key in rangeKeys) listOf(key) else emptyList()
        }
        return emptyList()
    }

    private fun millisToDay(millis: Long): Calendar {
        return Calendar.getInstance().apply { timeInMillis = millis }
    }

    private fun startOfDayMillis(cal: Calendar): Long {
        return (cal.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }
}
