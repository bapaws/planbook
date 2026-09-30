package com.bapaws.planbook.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.SizeF
import android.widget.RemoteViews
import com.bapaws.planbook.R
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking

private const val TAG = "PlanbookTimeBlockRV"
private const val HIT_COUNT = 8
private const val MAX_RESPONSIVE_SIZE_COUNT = 16

private enum class TimeBlockWidgetSize(
    val defaultWidthDp: Int,
    val defaultHeightDp: Int,
) {
    LARGE(defaultWidthDp = 250, defaultHeightDp = 250),
    MEDIUM(defaultWidthDp = 250, defaultHeightDp = 110),
    SMALL(defaultWidthDp = 110, defaultHeightDp = 110),
}

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
        newOptions: Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId, newOptions)
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            options: Bundle? = null,
        ) {
            TimeBlockWidgetUpdater.update(
                context, appWidgetManager, appWidgetId, TimeBlockWidgetSize.LARGE, options,
            )
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
        newOptions: Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId, newOptions)
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            options: Bundle? = null,
        ) {
            TimeBlockWidgetUpdater.update(
                context, appWidgetManager, appWidgetId, TimeBlockWidgetSize.MEDIUM, options,
            )
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
        newOptions: Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId, newOptions)
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            options: Bundle? = null,
        ) {
            TimeBlockWidgetUpdater.update(
                context, appWidgetManager, appWidgetId, TimeBlockWidgetSize.SMALL, options,
            )
        }
    }
}

private object TimeBlockWidgetUpdater {
    fun update(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetSize: TimeBlockWidgetSize,
        updatedOptions: Bundle?,
    ) {
        try {
            val isDark = WidgetSettings.isDarkMode(context)
            val isPremium = WidgetSettings.isPremium(context)
            val options = updatedOptions ?: appWidgetManager.getAppWidgetOptions(appWidgetId)
            val tasks = if (isPremium) {
                runBlocking(Dispatchers.IO) {
                    WidgetDatabase.open(context) { it.fetchTimeBlockTasks() } ?: emptyList()
                }
            } else {
                emptyList()
            }

            val responsiveSizes = getResponsiveSizes(options)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && responsiveSizes.isNotEmpty()) {
                val views = responsiveSizes.associateWith { size ->
                    createRemoteViews(
                        context = context,
                        appWidgetId = appWidgetId,
                        widthDp = size.width,
                        heightDp = size.height,
                        isPremium = isPremium,
                        tasks = tasks,
                        isDark = isDark,
                    )
                }
                appWidgetManager.updateAppWidget(appWidgetId, RemoteViews(views))
                Log.d(
                    TAG,
                    "Time block widget updated responsive sizes=$responsiveSizes premium=$isPremium",
                )
                return
            }

            val widgetInfo = appWidgetManager.getAppWidgetInfo(appWidgetId)
            val minW = widgetInfo?.minWidth ?: widgetSize.defaultWidthDp
            val minH = widgetInfo?.minHeight ?: widgetSize.defaultHeightDp
            val (widthDp, heightDp) = getLegacySize(context, options, minW, minH)
            val rv = createRemoteViews(
                context = context,
                appWidgetId = appWidgetId,
                widthDp = widthDp.toFloat(),
                heightDp = heightDp.toFloat(),
                isPremium = isPremium,
                tasks = tasks,
                isDark = isDark,
            )
            appWidgetManager.updateAppWidget(appWidgetId, rv)
            Log.d(
                TAG,
                "Time block widget updated legacy size=${widthDp}x$heightDp premium=$isPremium",
            )
        } catch (e: Exception) {
            Log.e(TAG, "Time block update error", e)
        }
    }

    private fun createRemoteViews(
        context: Context,
        appWidgetId: Int,
        widthDp: Float,
        heightDp: Float,
        isPremium: Boolean,
        tasks: List<TimeBlockTask>,
        isDark: Boolean,
    ): RemoteViews {
        val rv = RemoteViews(context.packageName, R.layout.widget_time_block)
        val density = context.resources.displayMetrics.density
        val widthPx = (widthDp * density).toInt().coerceAtLeast(100)
        val heightPx = (heightDp * density).toInt().coerceAtLeast(100)
        val renderLarge = widthDp >= 220f && heightDp >= 200f
        val bgResId = WidgetBackgroundConfig.safeBackgroundResId(context)
        val background = createRoundedTiledBackground(
            context, bgResId, widthPx, heightPx, 24f * density,
        )
        val (timeline, hits) = TimeBlockRenderer.render(
            context = context,
            widthPx = widthPx,
            heightPx = heightPx,
            isLarge = renderLarge,
            isPremium = isPremium,
            tasks = tasks,
            isDark = isDark,
            baseBitmap = background,
        )
        // 背景与时间线合成一张图，避免响应式布局携带双份全尺寸 Bitmap。
        rv.setViewVisibility(R.id.widget_bg, android.view.View.GONE)
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
                if (renderLarge) 4300 + appWidgetId else 4400 + appWidgetId,
                "planbook.bapaws://task/new?dueAt=today",
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
        bindOpenAppClick(
            rv,
            context,
            R.id.widget_root,
            if (renderLarge) 4100 + appWidgetId else 4200 + appWidgetId,
            deepLink,
        )
        return rv
    }

    private fun getLegacySize(
        context: Context,
        options: Bundle,
        defaultWidthDp: Int,
        defaultHeightDp: Int,
    ): Pair<Int, Int> {
        val isLandscape = context.resources.configuration.orientation ==
            Configuration.ORIENTATION_LANDSCAPE
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
        return options.getInt(widthOption, defaultWidthDp) to
            options.getInt(heightOption, defaultHeightDp)
    }

    private fun getResponsiveSizes(options: Bundle): List<SizeF> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return emptyList()
        val sizes: ArrayList<SizeF>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            options.getParcelableArrayList(
                AppWidgetManager.OPTION_APPWIDGET_SIZES,
                SizeF::class.java,
            )
        } else {
            @Suppress("DEPRECATION")
            options.getParcelableArrayList<SizeF>(AppWidgetManager.OPTION_APPWIDGET_SIZES)
        }
        // Launcher 最多应提供 16 个候选尺寸；过滤异常值避免创建非法 Bitmap。
        return sizes.orEmpty()
            .filter { it.width > 0f && it.height > 0f }
            .distinct()
            .take(MAX_RESPONSIVE_SIZE_COUNT)
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
