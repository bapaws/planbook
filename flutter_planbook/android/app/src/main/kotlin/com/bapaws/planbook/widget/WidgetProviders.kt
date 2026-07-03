package com.bapaws.planbook.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.os.Build
import android.util.Log
import android.text.Html
import android.widget.RemoteViews
import com.bapaws.planbook.R
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext

private const val TAG = "PlanbookWidgetRV"

/**
 * 大号四象限小组件 (4x4) - RemoteViews 实现
 */
class QuadrantWidgetLargeProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "Large onUpdate ids=${appWidgetIds.contentToString()}")
        for (appWidgetId in appWidgetIds) {
            updateLargeWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "Large onEnabled")
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "Large onDisabled")
    }

    companion object {
        fun updateLargeWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val rv = RemoteViews(context.packageName, R.layout.widget_quadrant_large)

                val isDark = WidgetSettings.isDarkMode(context)
                val bgResId = WidgetBackgroundConfig.safeBackgroundResId(context)
                val filterMode = WidgetActionUtils.getFilterMode(context, appWidgetId)

                // 生成圆角平铺背景
                val density = context.resources.displayMetrics.density
                val widgetInfo = appWidgetManager.getAppWidgetInfo(appWidgetId)
                val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
                val minW = widgetInfo?.minWidth ?: 250
                val minH = widgetInfo?.minHeight ?: 250
                val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, minW)
                val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, minH)
                val widthPx = (widthDp * density).toInt().coerceAtLeast(100)
                val heightPx = (heightDp * density).toInt().coerceAtLeast(100)
                val bgBitmap = createRoundedTiledBackground(context, bgResId, widthPx, heightPx, 24f * density)
                rv.setBitmap(R.id.widget_bg, "setImageBitmap", bgBitmap)

                // 获取数据并应用 pending 覆盖（乐观 UI）
                val groups = runBlocking(Dispatchers.IO) {
                    val raw = WidgetDatabase.getInstance(context)?.fetchQuadrantTasks(filterMode) ?: emptyList()
                    applyPendingCompletions(context, raw)
                }

                // 设置每个象限
                val headerIds = listOf(
                    R.id.quadrant_1_header, R.id.quadrant_2_header, R.id.quadrant_3_header, R.id.quadrant_4_header
                )
                val numberIds = listOf(
                    R.id.quadrant_1_number, R.id.quadrant_2_number, R.id.quadrant_3_number, R.id.quadrant_4_number
                )
                val titleIds = listOf(
                    R.id.quadrant_1_title, R.id.quadrant_2_title, R.id.quadrant_3_title, R.id.quadrant_4_title
                )

                val quadrantConfigs = WidgetSettings.getQuadrantConfigs(context)

                for (i in 0 until 4) {
                    val group = groups.getOrNull(i)
                    val priority = TaskPriority.entries[i]
                    val theme = priority.getColorScheme(isDark)

                    // 设置标题栏背景（带圆角的颜色背景）
                    val headerBgRes = when (priority) {
                        TaskPriority.HIGH -> R.drawable.bg_quadrant_header_red
                        TaskPriority.MEDIUM -> R.drawable.bg_quadrant_header_blue
                        TaskPriority.LOW -> R.drawable.bg_quadrant_header_amber
                        TaskPriority.NONE -> R.drawable.bg_quadrant_header_green
                    }
                    rv.setInt(headerIds[i], "setBackgroundResource", headerBgRes)

                    // 设置数字样式（大号粗斜体）
                    val numberText = "<b>${i + 1}.</b>"
                    rv.setTextViewText(numberIds[i], Html.fromHtml(numberText, Html.FROM_HTML_MODE_LEGACY))
                    rv.setTextColor(numberIds[i], theme.onPrimaryContainerColor())

                    // 设置标题文字样式（小号）
                    rv.setTextViewText(titleIds[i], priority.displayTitle(quadrantConfigs))
                    rv.setTextColor(titleIds[i], theme.onPrimaryContainerColor())

                    // 设置任务
                    val tasks = group?.tasks?.take(5) ?: emptyList()
                    for (j in 0 until 5) {
                        val taskRowId = context.resources.getIdentifier(
                            "quadrant_${i + 1}_task_${j + 1}", "id", context.packageName
                        )
                        val iconId = context.resources.getIdentifier(
                            "quadrant_${i + 1}_task_${j + 1}_icon", "id", context.packageName
                        )
                        val textId = context.resources.getIdentifier(
                            "quadrant_${i + 1}_task_${j + 1}_text", "id", context.packageName
                        )

                        if (taskRowId == 0 || iconId == 0 || textId == 0) continue

                        if (j < tasks.size) {
                            val task = tasks[j]
                            rv.setViewVisibility(taskRowId, android.view.View.VISIBLE)
                            rv.setImageViewResource(iconId,
                                if (task.isCompleted) R.drawable.ic_check_circle else R.drawable.ic_circle
                            )
                            rv.setTextViewText(textId, task.title)
                            rv.setTextColor(textId,
                                if (task.isCompleted) theme.outlineColor()
                                else theme.onSurfaceVariantColor()
                            )

                            // 设置点击事件 - 完成任务
                            // 与 iOS 保持一致：点击区域覆盖整行（从象限最左到最右），
                            // 而不是仅图标，避免在 RemoteViews 上图标点击区域过小
                            val completeIntent = Intent(context, WidgetClickReceiver::class.java).apply {
                                action = WidgetClickReceiver.ACTION_COMPLETE_TASK
                                putExtra(WidgetClickReceiver.EXTRA_TASK_ID, task.id)
                            }
                            val completePending = PendingIntent.getBroadcast(
                                context, task.id.hashCode(), completeIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )
                            rv.setOnClickPendingIntent(taskRowId, completePending)
                        } else {
                            rv.setViewVisibility(taskRowId, android.view.View.GONE)
                        }
                    }
                }

                // 空白区域点击打开 App（子 view 有独立 PendingIntent 时优先响应）
                val quadrantIds = listOf(
                    R.id.quadrant_1, R.id.quadrant_2, R.id.quadrant_3, R.id.quadrant_4
                )
                for (i in quadrantIds.indices) {
                    bindOpenAppClick(rv, context, quadrantIds[i], 1000 + i)
                }
                bindOpenAppClick(rv, context, R.id.widget_root, 2000)

                appWidgetManager.updateAppWidget(appWidgetId, rv)
                Log.d(TAG, "Large widget updated successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Large update error", e)
            }
        }
    }
}

/**
 * 中号四象限小组件 (2x2) - RemoteViews 实现
 */
class QuadrantWidgetSmallProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "Small onUpdate ids=${appWidgetIds.contentToString()}")
        for (appWidgetId in appWidgetIds) {
            updateSmallWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "Small onEnabled")
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "Small onDisabled")
    }

    companion object {
        fun updateSmallWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val rv = RemoteViews(context.packageName, R.layout.widget_quadrant_small)

                val isDark = WidgetSettings.isDarkMode(context)
                val bgResId = WidgetBackgroundConfig.safeBackgroundResId(context)
                val filterMode = WidgetActionUtils.getFilterMode(context, appWidgetId)
                val selectedPriority = WidgetSettings.getSelectedPriority(context)

                // 生成圆角平铺背景
                val density = context.resources.displayMetrics.density
                val widgetInfo = appWidgetManager.getAppWidgetInfo(appWidgetId)
                val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
                val minW = widgetInfo?.minWidth ?: 250
                val minH = widgetInfo?.minHeight ?: 110
                val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, minW)
                val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, minH)
                val widthPx = (widthDp * density).toInt().coerceAtLeast(100)
                val heightPx = (heightDp * density).toInt().coerceAtLeast(100)
                val bgBitmap = createRoundedTiledBackground(context, bgResId, widthPx, heightPx, 24f * density)
                rv.setBitmap(R.id.widget_bg, "setImageBitmap", bgBitmap)

                // 按钮 ID
                val btnIds = listOf(R.id.btn_q1, R.id.btn_q2, R.id.btn_q3, R.id.btn_q4)
                val priorities = listOf(TaskPriority.HIGH, TaskPriority.MEDIUM, TaskPriority.LOW, TaskPriority.NONE)

                // 设置按钮样式（ImageView + 动态 Bitmap，精确匹配 iOS）
                for (i in 0 until 4) {
                    val priority = priorities[i]
                    val theme = priority.getColorScheme(isDark)
                    val isSelected = priority == selectedPriority

                    // 动态生成按钮 Bitmap：圆角背景 + 数字文字 + 选中态边框
                    val btnBitmap = createQuadrantButtonBitmap(
                        context = context,
                        number = "${i + 1}",
                        bgColor = theme.primaryContainerColor(),
                        textColor = theme.primaryColor(),
                        isSelected = isSelected,
                        sizeDp = 21,
                        cornerRadiusDp = 8
                    )
                    rv.setImageViewBitmap(btnIds[i], btnBitmap)

                    // 切换象限点击
                    val switchIntent = Intent(context, WidgetClickReceiver::class.java).apply {
                        action = WidgetClickReceiver.ACTION_SWITCH_QUADRANT
                        putExtra(WidgetClickReceiver.EXTRA_PRIORITY, priority.rawValue)
                    }
                    val switchPending = PendingIntent.getBroadcast(
                        context, priority.ordinal, switchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    rv.setOnClickPendingIntent(btnIds[i], switchPending)
                }

                // 获取选中象限的任务并应用 pending 覆盖（乐观 UI）
                val tasks = runBlocking(Dispatchers.IO) {
                    val raw = WidgetDatabase.getInstance(context)?.fetchTasks(selectedPriority, filterMode, 4) ?: emptyList()
                    val pending = WidgetSettings.getPendingCompletions(context)
                    if (pending.isEmpty()) {
                        raw
                    } else {
                        raw.map { task ->
                            val target = pending[task.id]
                            if (target == null || target == task.isCompleted) task else task.copy(isCompleted = target)
                        }
                    }
                }
                val theme = selectedPriority.getColorScheme(isDark)

                // 设置任务
                for (j in 0 until 4) {
                    val taskRowId = context.resources.getIdentifier("task_${j + 1}", "id", context.packageName)
                    val iconId = context.resources.getIdentifier("task_${j + 1}_icon", "id", context.packageName)
                    val textId = context.resources.getIdentifier("task_${j + 1}_text", "id", context.packageName)

                    if (taskRowId == 0 || iconId == 0 || textId == 0) continue

                    if (j < tasks.size) {
                        val task = tasks[j]
                        rv.setViewVisibility(taskRowId, android.view.View.VISIBLE)
                        rv.setImageViewResource(iconId,
                            if (task.isCompleted) R.drawable.ic_check_circle else R.drawable.ic_circle
                        )
                        rv.setTextViewText(textId, task.title)
                        rv.setTextColor(textId,
                            if (task.isCompleted) theme.outlineColor()
                            else theme.onSurfaceVariantColor()
                        )

                        val completeIntent = Intent(context, WidgetClickReceiver::class.java).apply {
                            action = WidgetClickReceiver.ACTION_COMPLETE_TASK
                            putExtra(WidgetClickReceiver.EXTRA_TASK_ID, task.id)
                        }
                        val completePending = PendingIntent.getBroadcast(
                            context, task.id.hashCode(), completeIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        rv.setOnClickPendingIntent(taskRowId, completePending)
                    } else {
                        rv.setViewVisibility(taskRowId, android.view.View.GONE)
                    }
                }

                // 空白区域点击打开 App
                bindOpenAppClick(rv, context, R.id.task_list_spacer, 3000)
                bindOpenAppClick(rv, context, R.id.widget_root, 3001)

                appWidgetManager.updateAppWidget(appWidgetId, rv)
                Log.d(TAG, "Small widget updated successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Small update error", e)
            }
        }
    }
}

/**
 * 快速笔记小组件 (2x2) - RemoteViews 实现
 */
class QuickNoteWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "Quick onUpdate ids=${appWidgetIds.contentToString()}")
        for (appWidgetId in appWidgetIds) {
            updateQuickWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateQuickWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val rv = RemoteViews(context.packageName, R.layout.widget_quick_note)

                val isDark = WidgetSettings.isDarkMode(context)
                val bgResId = WidgetBackgroundConfig.safeBackgroundResId(context)
                val colorScheme = WidgetSettings.getCurrentColorScheme(context)

                // 生成圆角平铺背景
                val density = context.resources.displayMetrics.density
                val widgetInfo = appWidgetManager.getAppWidgetInfo(appWidgetId)
                val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
                val minW = widgetInfo?.minWidth ?: 110
                val minH = widgetInfo?.minHeight ?: 110
                val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, minW)
                val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, minH)
                val widthPx = (widthDp * density).toInt().coerceAtLeast(100)
                val heightPx = (heightDp * density).toInt().coerceAtLeast(100)
                val bgBitmap = createRoundedTiledBackground(context, bgResId, widthPx, heightPx, 24f * density)
                rv.setBitmap(R.id.widget_bg, "setImageBitmap", bgBitmap)

                // 生成圆形 icon 背景（精确匹配 iOS: Circle().fill(iconBackgroundColor)）
                val iconBgSize = (40 * density).toInt()
                val iconBgBitmap = createCircleBitmap(iconBgSize, colorScheme.primaryContainerColor())
                rv.setImageViewBitmap(R.id.icon_bg, iconBgBitmap)

                // 文字颜色
                rv.setTextColor(R.id.label, colorScheme.outlineColor())

                // 点击打开 App 创建笔记
                val openIntent = WidgetActionUtils.createOpenAppIntent(context, "planbook.bapaws://note/new")
                val openPending = PendingIntent.getActivity(
                    context, 0, openIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                rv.setOnClickPendingIntent(R.id.widget_root, openPending)

                appWidgetManager.updateAppWidget(appWidgetId, rv)
                Log.d(TAG, "Quick widget updated successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Quick update error", e)
            }
        }
    }
}

/**
 * 创建圆角平铺背景 Bitmap
 */
private fun createRoundedTiledBackground(
    context: Context,
    tileResId: Int,
    width: Int,
    height: Int,
    radiusPx: Float
): Bitmap {
    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    // 先绘制圆角矩形遮罩（白色背景）
    val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    bgPaint.color = android.graphics.Color.WHITE
    val rect = RectF(0f, 0f, width.toFloat(), height.toFloat())
    canvas.drawRoundRect(rect, radiusPx, radiusPx, bgPaint)

    // 尝试加载平铺图片（支持 XML bitmap drawable）
    try {
        val drawable = androidx.core.content.ContextCompat.getDrawable(context, tileResId)
        if (drawable != null) {
            // 将 drawable（含 tileMode）绘制到与 widget 等大的临时 bitmap 上
            val tileBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val tileCanvas = Canvas(tileBitmap)
            drawable.setBounds(0, 0, width, height)
            drawable.draw(tileCanvas)

            // 用 CLAMP 模式绘制圆角平铺背景（bitmap 已经填满）
            val shader = BitmapShader(tileBitmap, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
            val tilePaint = Paint(Paint.ANTI_ALIAS_FLAG)
            tilePaint.shader = shader
            canvas.drawRoundRect(rect, radiusPx, radiusPx, tilePaint)
        }
    } catch (e: Exception) {
        Log.e(TAG, "createRoundedTiledBackground error", e)
    }

    return bitmap
}

/**
 * 创建四象限按钮 Bitmap（圆角背景 + 数字文字 + 选中态边框）
 * 精确匹配 iOS: .frame(width: 21, height: 21) + .background(theme.primaryContainerColor)
 *            + .border(cornerRadius: 8) [选中态] / .clipShape(.rect(cornerRadius: 8)) [未选中态]
 */
private fun createQuadrantButtonBitmap(
    context: Context,
    number: String,
    bgColor: Int,
    textColor: Int,
    isSelected: Boolean,
    sizeDp: Int,
    cornerRadiusDp: Int
): Bitmap {
    val density = context.resources.displayMetrics.density
    val size = (sizeDp * density).toInt()
    val radius = cornerRadiusDp * density

    val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    // 绘制圆角背景
    val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    bgPaint.color = bgColor
    val rect = RectF(0f, 0f, size.toFloat(), size.toFloat())
    canvas.drawRoundRect(rect, radius, radius, bgPaint)

    // 选中态：绘制边框（精确匹配 iOS .border(cornerRadius: 8, style: .init())）
    if (isSelected) {
        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG)
        strokePaint.style = Paint.Style.STROKE
        strokePaint.strokeWidth = 1.5f * density
        strokePaint.color = textColor
        // 边框内缩，避免被边缘裁剪
        val inset = strokePaint.strokeWidth / 2f
        val strokeRect = RectF(inset, inset, size.toFloat() - inset, size.toFloat() - inset)
        canvas.drawRoundRect(strokeRect, radius, radius, strokePaint)
    }

    // 绘制数字文字（14sp bold italic，精确匹配 iOS .font(.system(size: 14, weight: .bold)).italic()）
    val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    textPaint.color = textColor
    textPaint.textSize = 14f * density
    textPaint.typeface = Typeface.create(Typeface.DEFAULT_BOLD, Typeface.ITALIC)
    textPaint.textAlign = Paint.Align.CENTER
    val x = size / 2f
    val y = size / 2f - (textPaint.descent() + textPaint.ascent()) / 2f
    canvas.drawText(number, x, y, textPaint)

    return bitmap
}

/**
 * 创建圆形背景 Bitmap（精确匹配 iOS: Circle().fill(color)）
 */
private fun createCircleBitmap(sizePx: Int, color: Int): Bitmap {
    val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    paint.color = color
    val radius = sizePx / 2f
    canvas.drawCircle(radius, radius, radius, paint)
    return bitmap
}

/**
 * 设置 widget 背景（圆角纯色回退）
 */
private fun setWidgetBackground(rv: RemoteViews, viewId: Int, bgResId: Int, isDark: Boolean) {
    try {
        rv.setInt(viewId, "setBackgroundResource", R.drawable.bg_widget_rounded)
    } catch (_: Exception) {
        rv.setInt(viewId, "setBackgroundColor", android.graphics.Color.parseColor(
            if (isDark) "#FF1C1B1F" else "#FFF8F9FA"
        ))
    }
}

/**
 * 刷新所有四象限 widget（用于任务完成后刷新）
 */
fun refreshQuadrantWidgets(context: Context) {
    val appWidgetManager = AppWidgetManager.getInstance(context)

    val largeComponent = ComponentName(context, QuadrantWidgetLargeProvider::class.java)
    val largeIds = appWidgetManager.getAppWidgetIds(largeComponent)
    for (id in largeIds) {
        QuadrantWidgetLargeProvider.updateLargeWidget(context, appWidgetManager, id)
    }

    val smallComponent = ComponentName(context, QuadrantWidgetSmallProvider::class.java)
    val smallIds = appWidgetManager.getAppWidgetIds(smallComponent)
    for (id in smallIds) {
        QuadrantWidgetSmallProvider.updateSmallWidget(context, appWidgetManager, id)
    }
}

/** 绑定打开 App 首页的点击事件 */
private fun bindOpenAppClick(rv: RemoteViews, context: Context, viewId: Int, requestCode: Int) {
    val openIntent = WidgetActionUtils.createOpenAppIntent(context)
    val openPending = PendingIntent.getActivity(
        context, requestCode, openIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    rv.setOnClickPendingIntent(viewId, openPending)
}

/**
 * 把 pending 完成状态覆盖到从 DB 查到的任务上，
 * 让 widget UI 在 Flutter 写完 DB 之前也能即时反馈。
 */
private fun applyPendingCompletions(context: Context, groups: List<QuadrantGroup>): List<QuadrantGroup> {
    val pending = WidgetSettings.getPendingCompletions(context)
    if (pending.isEmpty()) return groups
    return groups.map { group ->
        val overlaid = group.tasks.map { task ->
            val target = pending[task.id]
            if (target == null || target == task.isCompleted) {
                task
            } else {
                task.copy(isCompleted = target)
            }
        }
        QuadrantGroup(group.priority, overlaid)
    }
}

/**
 * 刷新中号 widget
 */
fun refreshQuadrantSmallWidgets(context: Context) {
    val appWidgetManager = AppWidgetManager.getInstance(context)
    val component = ComponentName(context, QuadrantWidgetSmallProvider::class.java)
    val ids = appWidgetManager.getAppWidgetIds(component)
    for (id in ids) {
        QuadrantWidgetSmallProvider.updateSmallWidget(context, appWidgetManager, id)
    }
}
