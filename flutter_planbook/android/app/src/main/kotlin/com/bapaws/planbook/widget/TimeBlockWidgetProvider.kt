package com.bapaws.planbook.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import com.bapaws.planbook.R
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking

private const val TAG = "PlanbookTimeBlockRV"
private const val HIT_COUNT = 8

class TimeBlockWidgetLargeProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            TimeBlockWidgetUpdater.update(context, appWidgetManager, appWidgetId, isLarge = true)
        }
    }
}

class TimeBlockWidgetMediumProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            TimeBlockWidgetUpdater.update(context, appWidgetManager, appWidgetId, isLarge = false)
        }
    }
}

private object TimeBlockWidgetUpdater {
    fun update(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        isLarge: Boolean,
    ) {
        try {
            val rv = RemoteViews(context.packageName, R.layout.widget_time_block)
            val isDark = WidgetSettings.isDarkMode(context)
            val isPremium = WidgetSettings.isPremium(context)
            val density = context.resources.displayMetrics.density
            val widgetInfo = appWidgetManager.getAppWidgetInfo(appWidgetId)
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minW = widgetInfo?.minWidth ?: if (isLarge) 250 else 250
            val minH = widgetInfo?.minHeight ?: if (isLarge) 250 else 110
            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, minW)
            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, minH)
            val widthPx = (widthDp * density).toInt().coerceAtLeast(100)
            val heightPx = (heightDp * density).toInt().coerceAtLeast(100)

            val bgResId = WidgetBackgroundConfig.safeBackgroundResId(context)
            val bgBitmap = createRoundedTiledBackground(
                context, bgResId, widthPx, heightPx, 24f * density,
            )
            rv.setImageViewBitmap(R.id.widget_bg, bgBitmap)

            val tasks = if (isPremium) {
                runBlocking(Dispatchers.IO) {
                    WidgetDatabase.getInstance(context)?.fetchTimeBlockTasks() ?: emptyList()
                }
            } else {
                emptyList()
            }

            val (timeline, hits) = TimeBlockRenderer.render(
                context = context,
                widthPx = widthPx,
                heightPx = heightPx,
                isLarge = isLarge,
                isPremium = isPremium,
                tasks = tasks,
                isDark = isDark,
            )
            rv.setImageViewBitmap(R.id.timeline, timeline)

            hideHits(context, rv)
            if (isPremium && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                bindHits(context, rv, hits, density)
            }

            val deepLink = if (isPremium) {
                "planbook.bapaws://task/today?view=timeBlock"
            } else {
                "planbook.bapaws://purchases"
            }
            bindOpenAppClick(rv, context, R.id.widget_root, if (isLarge) 4100 else 4200, deepLink)

            appWidgetManager.updateAppWidget(appWidgetId, rv)
            Log.d(TAG, "Time block widget updated large=$isLarge premium=$isPremium")
        } catch (e: Exception) {
            Log.e(TAG, "Time block update error", e)
        }
    }

    private fun hideHits(context: Context, rv: RemoteViews) {
        for (i in 0 until HIT_COUNT) {
            val id = hitId(context, i) ?: continue
            rv.setViewVisibility(id, android.view.View.GONE)
        }
    }

    private fun bindHits(
        context: Context,
        rv: RemoteViews,
        hits: List<TimeBlockHit>,
        density: Float,
    ) {
        for (i in 0 until HIT_COUNT) {
            val id = hitId(context, i) ?: continue
            if (i >= hits.size) {
                rv.setViewVisibility(id, android.view.View.GONE)
                continue
            }
            val hit = hits[i]
            rv.setViewVisibility(id, android.view.View.VISIBLE)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                rv.setViewLayoutMargin(id, RemoteViews.MARGIN_LEFT, hit.left / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
                rv.setViewLayoutMargin(id, RemoteViews.MARGIN_TOP, hit.top / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
                rv.setViewLayoutWidth(id, hit.width / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
                rv.setViewLayoutHeight(id, hit.height / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
            }
            val completeIntent = Intent(context, WidgetClickReceiver::class.java).apply {
                action = WidgetClickReceiver.ACTION_COMPLETE_TASK
                putExtra(WidgetClickReceiver.EXTRA_TASK_ID, hit.task.taskId)
                putExtra(WidgetClickReceiver.EXTRA_OCCURRENCE_AT, hit.task.occurrenceAt)
            }
            val pending = PendingIntent.getBroadcast(
                context,
                hit.task.taskId.hashCode() xor (hit.task.occurrenceAt?.hashCode() ?: 0),
                completeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            rv.setOnClickPendingIntent(id, pending)
        }
    }

    private fun hitId(context: Context, index: Int): Int? {
        val id = context.resources.getIdentifier("time_block_hit_$index", "id", context.packageName)
        return id.takeIf { it != 0 }
    }
}
