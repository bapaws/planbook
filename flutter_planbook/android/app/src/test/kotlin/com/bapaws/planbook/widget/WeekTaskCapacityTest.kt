package com.bapaws.planbook.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WeekTaskCapacityTest {
    @Test
    fun tallerDayColumnsShowMoreTasksAndReserveOverflowRow() {
        val shortSlots = WeekTaskCapacity.slots(54f, 12f, 2f)
        val tallSlots = WeekTaskCapacity.slots(110f, 12f, 2f)
        assertEquals(4, shortSlots)
        assertEquals(8, tallSlots)
        assertEquals(3, WeekTaskCapacity.visibleCount(10, shortSlots))
        assertEquals(7, WeekTaskCapacity.visibleCount(10, tallSlots))
    }

    @Test
    fun exactFitDoesNotReserveUnnecessaryOverflowSpace() {
        assertEquals(4, WeekTaskCapacity.visibleCount(4, 4))
        assertEquals(8, WeekTaskCapacity.visibleCount(8, 4, columns = 2))
        assertEquals(6, WeekTaskCapacity.visibleCount(9, 4, columns = 2))
    }

    @Test
    fun tinyCellsShowOnlyOverflowWhenOneRowFits() {
        assertEquals(0, WeekTaskCapacity.slots(-5f, 12f, 2f))
        assertEquals(0, WeekTaskCapacity.slots(11f, 12f, 2f))
        assertEquals(1, WeekTaskCapacity.slots(12f, 12f, 2f))
        assertEquals(0, WeekTaskCapacity.visibleCount(5, 1))
        assertEquals(0, WeekTaskCapacity.visibleCount(5, 0))
        assertEquals(0, WeekTaskCapacity.visibleCount(0, 4))
    }

    @Test
    fun visibleRowsAndOverflowNeverExceedAvailableHeight() {
        // 覆盖单列日历、宫格和双列列表，包含分数高度与不同屏幕密度。
        for (density in listOf(1f, 1.5f, 2.75f)) {
            for (height in 0..200) {
                for (columns in 1..2) {
                    for (count in 0..30) {
                        val rowHeight = 12f * density
                        val spacing = 2f * density
                        val available = (height + 0.25f) * density
                        val slots = WeekTaskCapacity.slots(available, rowHeight, spacing)
                        val visible = WeekTaskCapacity.visibleCount(count, slots, columns)
                        val rows = (visible + columns - 1) / columns + if (count > visible && slots > 0) 1 else 0
                        val used = rows * rowHeight + (rows - 1).coerceAtLeast(0) * spacing
                        assertTrue(visible in 0..count)
                        assertTrue(used <= available)
                    }
                }
            }
        }
    }
}
