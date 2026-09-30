package com.bapaws.planbook.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import com.bapaws.planbook.R
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking

private const val TAG = "PlanbookWeekWidget"
private const val COMPLETE_HIT_COUNT = 28
private const val DAY_HIT_COUNT = 16

class WeekListWidgetLargeProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { WeekWidgetUpdater.update(context, appWidgetManager, it, WeekWidgetKind.LIST, twoWeeks = false) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        WeekWidgetUpdater.update(context, appWidgetManager, appWidgetId, WeekWidgetKind.LIST, twoWeeks = false)
    }
}

class WeekGridWidgetLargeProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { WeekWidgetUpdater.update(context, appWidgetManager, it, WeekWidgetKind.GRID, twoWeeks = false) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        WeekWidgetUpdater.update(context, appWidgetManager, appWidgetId, WeekWidgetKind.GRID, twoWeeks = false)
    }
}

class MonthWeekWidgetMediumProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { WeekWidgetUpdater.update(context, appWidgetManager, it, WeekWidgetKind.MONTH, twoWeeks = false) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        WeekWidgetUpdater.update(context, appWidgetManager, appWidgetId, WeekWidgetKind.MONTH, twoWeeks = false)
    }
}

class MonthWeekWidgetLargeProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { WeekWidgetUpdater.update(context, appWidgetManager, it, WeekWidgetKind.MONTH, twoWeeks = true) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        WeekWidgetUpdater.update(context, appWidgetManager, appWidgetId, WeekWidgetKind.MONTH, twoWeeks = true)
    }
}

object WeekWidgetUpdater {
    fun update(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        kind: WeekWidgetKind,
        twoWeeks: Boolean,
    ) {
        try {
            val rv = RemoteViews(context.packageName, R.layout.widget_week)
            val isDark = WidgetSettings.isDarkMode(context)
            val density = context.resources.displayMetrics.density
            val widgetInfo = appWidgetManager.getAppWidgetInfo(appWidgetId)
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minW = widgetInfo?.minWidth ?: 250
            val minH = widgetInfo?.minHeight ?: 110
            val isLandscape = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
            val widthOption = if (isLandscape) {
                AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH
            } else {
                AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH
            }
            val heightOption = if (isLandscape) {
                AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT
            } else {
                AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT
            }
            val widthDp = options.getInt(widthOption, minW)
            val heightDp = options.getInt(heightOption, minH)
            val widthPx = (widthDp * density).toInt().coerceAtLeast(100)
            val heightPx = (heightDp * density).toInt().coerceAtLeast(100)

            val bgResId = WidgetBackgroundConfig.safeBackgroundResId(context)
            rv.setImageViewBitmap(
                R.id.widget_bg,
                createRoundedTiledBackground(context, bgResId, widthPx, heightPx, 24f * density),
            )

            val start = WeekCalendar.startOfWeek()
            val dayCount = if (kind == WeekWidgetKind.MONTH && twoWeeks) 14 else 7
            val end = WeekCalendar.endExclusive(start, dayCount)
            val startKey = WeekCalendar.dayKey(start)
            val endKey = WeekCalendar.dayKey(end)
            val tasks = runBlocking(Dispatchers.IO) {
                WidgetDatabase.open(context) { db ->
                    WeekCalendar.overlayPending(context, db.fetchWeekTasks(startKey, endKey))
                } ?: emptyList()
            }
            val focus = if (kind == WeekWidgetKind.GRID) {
                runBlocking(Dispatchers.IO) {
                    WidgetDatabase.open(context) { it.fetchWeeklyFocus(startKey, WeekCalendar.dayKey(WeekCalendar.endExclusive(start, 7))) }
                }
            } else {
                null
            }

            val (bitmap, completeHits, dayHits) = WeekWidgetRenderer.render(
                context, widthPx, heightPx, kind, twoWeeks, isDark, tasks, focus,
            )
            rv.setImageViewBitmap(R.id.week_content, bitmap)

            bindOpenAppClick(
                rv, context, R.id.week_create, 5100 + appWidgetId + kind.ordinal * 17,
                "planbook.bapaws://task/new?dueAt=today",
            )
            val rootLink = if (kind == WeekWidgetKind.GRID) {
                "planbook.bapaws://task/week?view=grid"
            } else {
                "planbook.bapaws://task/week?view=list"
            }
            bindOpenAppClick(rv, context, R.id.widget_root, 5200 + appWidgetId + kind.ordinal * 17, rootLink)

            hideHits(context, rv)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                bindCompleteHits(context, rv, completeHits, density, appWidgetId)
                bindDayHits(context, rv, dayHits, density, appWidgetId)
            }

            appWidgetManager.updateAppWidget(appWidgetId, rv)
        } catch (e: Exception) {
            Log.e(TAG, "Week widget update error kind=$kind", e)
        }
    }

    private fun hideHits(context: Context, rv: RemoteViews) {
        for (i in 0 until COMPLETE_HIT_COUNT) {
            completeId(context, i)?.let { rv.setViewVisibility(it, android.view.View.GONE) }
        }
        for (i in 0 until DAY_HIT_COUNT) {
            dayId(context, i)?.let { rv.setViewVisibility(it, android.view.View.GONE) }
        }
    }

    private fun bindCompleteHits(
        context: Context,
        rv: RemoteViews,
        hits: List<WeekHit>,
        density: Float,
        appWidgetId: Int,
    ) {
        for (i in 0 until COMPLETE_HIT_COUNT) {
            val id = completeId(context, i) ?: continue
            if (i >= hits.size) {
                rv.setViewVisibility(id, android.view.View.GONE)
                continue
            }
            val hit = hits[i]
            val task = hit.task ?: continue
            rv.setViewVisibility(id, android.view.View.VISIBLE)
            rv.setViewLayoutMargin(id, RemoteViews.MARGIN_LEFT, hit.left / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
            rv.setViewLayoutMargin(id, RemoteViews.MARGIN_TOP, hit.top / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
            rv.setViewLayoutWidth(id, hit.width / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
            rv.setViewLayoutHeight(id, hit.height / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
            val completeIntent = Intent(context, WidgetClickReceiver::class.java).apply {
                action = WidgetClickReceiver.ACTION_COMPLETE_TASK
                putExtra(WidgetClickReceiver.EXTRA_TASK_ID, task.taskId)
                putExtra(WidgetClickReceiver.EXTRA_OCCURRENCE_AT, task.occurrenceAt)
            }
            val pending = android.app.PendingIntent.getBroadcast(
                context,
                (appWidgetId * 37) xor "week-complete#${task.id}".hashCode(),
                completeIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE,
            )
            rv.setOnClickPendingIntent(id, pending)
        }
    }

    private fun bindDayHits(
        context: Context,
        rv: RemoteViews,
        hits: List<WeekHit>,
        density: Float,
        appWidgetId: Int,
    ) {
        for (i in 0 until DAY_HIT_COUNT) {
            val id = dayId(context, i) ?: continue
            if (i >= hits.size) {
                rv.setViewVisibility(id, android.view.View.GONE)
                continue
            }
            val hit = hits[i]
            val dateKey = hit.dateKey ?: continue
            rv.setViewVisibility(id, android.view.View.VISIBLE)
            rv.setViewLayoutMargin(id, RemoteViews.MARGIN_LEFT, hit.left / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
            rv.setViewLayoutMargin(id, RemoteViews.MARGIN_TOP, hit.top / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
            rv.setViewLayoutWidth(id, hit.width / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
            rv.setViewLayoutHeight(id, hit.height / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
            bindOpenAppClick(
                rv, context, id, appWidgetId xor dateKey.hashCode() xor 0x51,
                "planbook.bapaws://task/today?date=$dateKey",
            )
        }
    }

    private fun completeId(context: Context, index: Int): Int? {
        val id = context.resources.getIdentifier("week_complete_$index", "id", context.packageName)
        return id.takeIf { it != 0 }
    }

    private fun dayId(context: Context, index: Int): Int? {
        val id = context.resources.getIdentifier("week_day_$index", "id", context.packageName)
        return id.takeIf { it != 0 }
    }
}

fun refreshWeekWidgets(context: Context) {
    val appWidgetManager = AppWidgetManager.getInstance(context)
    listOf(
        WeekListWidgetLargeProvider::class.java,
        WeekGridWidgetLargeProvider::class.java,
        MonthWeekWidgetMediumProvider::class.java,
        MonthWeekWidgetLargeProvider::class.java,
    ).forEach { clazz ->
        val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, clazz))
        ids.forEach { id ->
            when (clazz) {
                WeekListWidgetLargeProvider::class.java ->
                    WeekWidgetUpdater.update(context, appWidgetManager, id, WeekWidgetKind.LIST, false)
                WeekGridWidgetLargeProvider::class.java ->
                    WeekWidgetUpdater.update(context, appWidgetManager, id, WeekWidgetKind.GRID, false)
                MonthWeekWidgetMediumProvider::class.java ->
                    WeekWidgetUpdater.update(context, appWidgetManager, id, WeekWidgetKind.MONTH, false)
                MonthWeekWidgetLargeProvider::class.java ->
                    WeekWidgetUpdater.update(context, appWidgetManager, id, WeekWidgetKind.MONTH, true)
                else -> Unit
            }
        }
    }
}
