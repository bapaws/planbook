package com.bapaws.planbook.widget

import java.util.Calendar
import org.junit.Assert.assertEquals
import org.junit.Test

class WeekCalendarTest {
    private fun date(day: Int, hour: Int = 0, minute: Int = 0): Calendar =
        Calendar.getInstance().apply {
            clear()
            set(2026, Calendar.OCTOBER, day, hour, minute)
        }

    private fun task(day: Int, endDay: Int = day): WeekTask = WeekTask(
        taskId = "work",
        title = "上班",
        priority = TaskPriority.NONE,
        isCompleted = false,
        occurrenceAt = "2026-10-${day}T00:00:00Z",
        startAt = date(day).timeInMillis,
        endAt = date(endDay, 23, 59).timeInMillis,
        dueAt = date(day).timeInMillis,
    )

    @Test
    fun recurringTwoDayTasksAppearOnBothDaysDespiteDueDate() {
        // 对应用户反馈：每四天重复，每次从当天零点持续至次日 23:59。
        val tasks = listOf(task(26, 27), task(30, 31))
        val days = WeekCalendar.days(date(26), 7)
        val grouped = WeekCalendar.groupTasks(tasks, days)
        assertEquals(listOf(1, 1, 0, 0, 1, 1, 0), days.map { grouped.getValue(WeekCalendar.dayKey(it)).size })
        assertEquals(tasks[0].id, grouped.getValue("2026-10-27").single().id)
        assertEquals(tasks[1].id, grouped.getValue("2026-10-31").single().id)
        assertEquals(0 to 2, WeekCalendar.progress(grouped.values.flatten()))
    }

    @Test
    fun taskStartingBeforeVisibleWeekStillAppearsOnOverlappingDay() {
        val days = WeekCalendar.days(date(27), 7)
        val grouped = WeekCalendar.groupTasks(listOf(task(26, 27)), days)
        assertEquals(1, grouped.getValue("2026-10-27").size)
        assertEquals(1, grouped.values.sumOf { it.size })
    }

    @Test
    fun ordinaryTwoDayTaskAlsoUsesItsTimeRange() {
        val grouped = WeekCalendar.groupTasks(
            listOf(task(26, 27).copy(occurrenceAt = null)),
            WeekCalendar.days(date(26), 7),
        )
        assertEquals(1, grouped.getValue("2026-10-26").size)
        assertEquals(1, grouped.getValue("2026-10-27").size)
    }

    @Test
    fun singleDayAndDueOnlyTasksRemainOnOneDay() {
        val days = WeekCalendar.days(date(26), 7)
        for (task in listOf(task(26), task(26).copy(startAt = null, endAt = null))) {
            val grouped = WeekCalendar.groupTasks(listOf(task), days)
            assertEquals(1, grouped.getValue("2026-10-26").size)
            assertEquals(1, grouped.values.sumOf { it.size })
        }
    }
}
