package com.bapaws.planbook.widget

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

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
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

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    companion object {
        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            TimeBlockWidgetUpdater.update(context, appWidgetManager, appWidgetId, isLarge = false)
        }
    }
}

class TimeBlockWidgetSmallProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
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
            val minW = widgetInfo?.minWidth ?: if (isLarge) 250 else 110
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

            rv.setViewVisibility(
                R.id.time_block_create,
                if (isPremium) android.view.View.VISIBLE else android.view.View.GONE,
            )
            if (isPremium) {
                bindOpenAppClick(
                    rv,
                    context,
                    R.id.time_block_create,
                    if (isLarge) 4300 + appWidgetId else 4400 + appWidgetId,
                    "planbook.bapaws://task/new",
                )
            }

            hideHits(context, rv)
            if (isPremium && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                bindHits(context, rv, hits, density, appWidgetId)
            }

            val deepLink = if (isPremium) {
                "planbook.bapaws://task/today?view=timeBlock"
            } else {
                "planbook.bapaws://purchases"
            }
            bindOpenAppClick(rv, context, R.id.widget_root, if (isLarge) 4100 + appWidgetId else 4200 + appWidgetId, deepLink)

            appWidgetManager.updateAppWidget(appWidgetId, rv)
            Log.d(TAG, "Time block widget updated large=$isLarge premium=$isPremium")
        } catch (e: Exception) {
            Log.e(TAG, "Time block update error", e)
        }
    }

    private fun hideHits(context: Context, rv: RemoteViews) {
        for (i in 0 until HIT_COUNT) {
            val hitId = hitId(context, i)
            if (hitId != null) {
                rv.setViewVisibility(hitId, android.view.View.GONE)
            }
            val completeId = completeId(context, i)
            if (completeId != null) {
                rv.setViewVisibility(completeId, android.view.View.GONE)
            }
        }
    }

    private fun bindHits(
        context: Context,
        rv: RemoteViews,
        hits: List<TimeBlockHit>,
        density: Float,
        appWidgetId: Int,
    ) {
        for (i in 0 until HIT_COUNT) {
            val id = hitId(context, i)
            val completeViewId = completeId(context, i)
            if (i >= hits.size) {
                if (id != null) rv.setViewVisibility(id, android.view.View.GONE)
                if (completeViewId != null) rv.setViewVisibility(completeViewId, android.view.View.GONE)
                continue
            }
            val hit = hits[i]
            if (id != null) {
                rv.setViewVisibility(id, android.view.View.VISIBLE)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    rv.setViewLayoutMargin(id, RemoteViews.MARGIN_LEFT, hit.left / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
                    rv.setViewLayoutMargin(id, RemoteViews.MARGIN_TOP, hit.top / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
                    rv.setViewLayoutWidth(id, hit.width / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
                    rv.setViewLayoutHeight(id, hit.height / density, android.util.TypedValue.COMPLEX_UNIT_DIP)
                }
                val detailUrl = android.net.Uri.Builder()
                    .scheme("planbook.bapaws")
                    .authority("task")
                    .appendPath("detail")
                    .appendQueryParameter("taskId", hit.task.taskId)
                    .apply {
                        hit.task.occurrenceAt?.takeIf { it.isNotEmpty() }?.let {
                            appendQueryParameter("occurrenceAt", it)
                        }
                    }
                    .build()
                    .toString()
                bindOpenAppClick(
                    rv,
                    context,
                    id,
                    appWidgetId xor hit.task.taskId.hashCode() xor (hit.task.occurrenceAt?.hashCode() ?: 0),
                    detailUrl,
                )
            }
            if (completeViewId != null) {
                rv.setViewVisibility(completeViewId, android.view.View.VISIBLE)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    rv.setViewLayoutMargin(
                        completeViewId,
                        RemoteViews.MARGIN_LEFT,
                        hit.completeLeft / density,
                        android.util.TypedValue.COMPLEX_UNIT_DIP,
                    )
                    rv.setViewLayoutMargin(
                        completeViewId,
                        RemoteViews.MARGIN_TOP,
                        hit.completeTop / density,
                        android.util.TypedValue.COMPLEX_UNIT_DIP,
                    )
                    rv.setViewLayoutWidth(
                        completeViewId,
                        hit.completeWidth / density,
                        android.util.TypedValue.COMPLEX_UNIT_DIP,
                    )
                    rv.setViewLayoutHeight(
                        completeViewId,
                        hit.completeHeight / density,
                        android.util.TypedValue.COMPLEX_UNIT_DIP,
                    )
                }
                val completeIntent = Intent(context, WidgetClickReceiver::class.java).apply {
                    action = WidgetClickReceiver.ACTION_COMPLETE_TASK
                    putExtra(WidgetClickReceiver.EXTRA_TASK_ID, hit.task.taskId)
                    putExtra(WidgetClickReceiver.EXTRA_OCCURRENCE_AT, hit.task.occurrenceAt)
                }
                val pending = android.app.PendingIntent.getBroadcast(
                    context,
                    (appWidgetId * 31) xor "complete#${hit.task.taskId}#${hit.task.occurrenceAt.orEmpty()}".hashCode(),
                    completeIntent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE,
                )
                rv.setOnClickPendingIntent(completeViewId, pending)
            }
        }
    }

    private fun hitId(context: Context, index: Int): Int? {
        val id = context.resources.getIdentifier("time_block_hit_$index", "id", context.packageName)
        return id.takeIf { it != 0 }
    }

    private fun completeId(context: Context, index: Int): Int? {
        val id = context.resources.getIdentifier("time_block_complete_$index", "id", context.packageName)
        return id.takeIf { it != 0 }
    }
}
