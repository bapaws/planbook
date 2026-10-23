package com.bapaws.planbook.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import com.bapaws.planbook.R

private const val TAG = "PlanbookWeekWidget"
private const val DAY_HIT_COUNT = 16

class WeekListWidgetLargeProvider : BackgroundWidgetProvider() {
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

class WeekGridWidgetLargeProvider : BackgroundWidgetProvider() {
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

class MonthWeekWidgetMediumProvider : BackgroundWidgetProvider() {
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

class MonthWeekWidgetLargeProvider : BackgroundWidgetProvider() {
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
            val isDark = WidgetSettings.resolvedIsDark(context)
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
            val tasks = run {
                WidgetDatabase.open(context) { db ->
                    WeekCalendar.overlayPending(context, db.fetchWeekTasks(startKey, endKey))
                } ?: emptyList()
            }
            val focus = if (kind == WeekWidgetKind.GRID) {
                run {
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
        rv.removeAllViews(R.id.week_complete_hits)
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
        for (hit in hits) {
            val id = R.id.week_complete_hit
            val hitView = RemoteViews(context.packageName, R.layout.widget_week_complete_hit)
            val task = hit.task ?: continue
            hitView.setViewVisibility(id, android.view.View.VISIBLE)
            hitView.setViewLayoutMargin(id, RemoteViews.MARGIN_LEFT, hit.left / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
            hitView.setViewLayoutMargin(id, RemoteViews.MARGIN_TOP, hit.top / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
            hitView.setViewLayoutWidth(id, hit.width / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
            hitView.setViewLayoutHeight(id, hit.height / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
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
            hitView.setOnClickPendingIntent(id, pending)
            rv.addView(R.id.week_complete_hits, hitView)
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

    private fun dayId(context: Context, index: Int): Int? {
        val id = context.resources.getIdentifier("week_day_$index", "id", context.packageName)
        return id.takeIf { it != 0 }
    }
}

fun refreshWeekWidgets(context: Context) {
    listOf(
        WeekListWidgetLargeProvider::class.java,
        WeekGridWidgetLargeProvider::class.java,
        MonthWeekWidgetMediumProvider::class.java,
        MonthWeekWidgetLargeProvider::class.java,
    ).forEach { provider -> requestWidgetUpdate(context, provider) }
}
