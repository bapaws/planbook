package com.bapaws.planbook.widget

/** 按实际可用高度计算任务容量，溢出时为 +N 留出一行。 */
object WeekTaskCapacity {
    fun slots(height: Float, rowHeight: Float, spacing: Float = 0f): Int =
        kotlin.math.floor((height.coerceAtLeast(0f) + spacing) / (rowHeight + spacing)).toInt()

    fun visibleCount(taskCount: Int, slots: Int, columns: Int = 1): Int {
        val rows = slots.coerceAtLeast(0)
        return if (taskCount <= rows * columns) taskCount else (rows - 1).coerceAtLeast(0) * columns
    }
}
