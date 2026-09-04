package com.bapaws.planbook.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.text.TextPaint
import android.text.TextUtils
import com.bapaws.planbook.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object TimeBlockRenderer {

    fun render(
        context: Context,
        widthPx: Int,
        heightPx: Int,
        isLarge: Boolean,
        isPremium: Boolean,
        tasks: List<TimeBlockTask>,
        isDark: Boolean,
    ): Pair<Bitmap, List<TimeBlockHit>> {
        val bitmap = Bitmap.createBitmap(widthPx.coerceAtLeast(1), heightPx.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val density = context.resources.displayMetrics.density
        val colorScheme = WidgetSettings.getCurrentColorScheme(context)

        if (!isPremium) {
            drawLocked(context, canvas, widthPx, heightPx, density, colorScheme)
            return bitmap to emptyList()
        }

        val pad = 8f * density
        val headerH = TimeBlockLayout.HEADER_HEIGHT_DP * density
        val contentTop = pad + headerH + 4f * density
        val contentLeft = pad
        val contentRight = widthPx - pad
        val contentBottom = heightPx - pad
        val contentH = (contentBottom - contentTop).coerceAtLeast(1f)
        val contentW = (contentRight - contentLeft).coerceAtLeast(1f)
        val nowMinutes = TimeBlockLayout.nowMinutes()

        drawHeader(context, canvas, contentLeft, pad, contentW, headerH, density, colorScheme)

        val hits = mutableListOf<TimeBlockHit>()
        if (isLarge) {
            val gap = 6f * density
            val colW = (contentW - gap) / 2f
            hits += drawColumn(
                canvas, tasks, 0, 12 * 60,
                contentLeft, contentTop, colW, contentH, density, isDark, colorScheme, nowMinutes,
            )
            val dividerX = contentLeft + colW + gap / 2f
            val dividerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = colorScheme.surfaceContainerHighestColor()
                strokeWidth = 1f * density
            }
            canvas.drawLine(dividerX, contentTop, dividerX, contentBottom, dividerPaint)
            hits += drawColumn(
                canvas, tasks, 12 * 60, 24 * 60,
                contentLeft + colW + gap, contentTop, colW, contentH, density, isDark, colorScheme, nowMinutes,
            )
        } else {
            val window = TimeBlockLayout.mediumWindow(nowMinutes)
            hits += drawColumn(
                canvas, tasks, window.first, window.second,
                contentLeft, contentTop, contentW, contentH, density, isDark, colorScheme, nowMinutes,
            )
        }

        if (tasks.isEmpty()) {
            val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = colorScheme.outlineColor()
                textSize = 12f * density
                textAlign = Paint.Align.CENTER
            }
            canvas.drawText(
                context.getString(R.string.widget_time_block_empty),
                widthPx / 2f,
                contentTop + contentH / 2f,
                textPaint,
            )
        }

        return bitmap to hits
    }

    private fun drawHeader(
        context: Context,
        canvas: Canvas,
        left: Float,
        top: Float,
        width: Float,
        height: Float,
        density: Float,
        colorScheme: FlutterColorScheme,
    ) {
        val titlePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.onSurfaceColor()
            textSize = 13f * density
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        val datePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.outlineColor()
            textSize = 11f * density
        }
        val titleY = top + height - titlePaint.descent()
        canvas.drawText(context.getString(R.string.widget_time_block_today), left, titleY, titlePaint)
        val dateFmt = SimpleDateFormat("MMM d", Locale.getDefault())
        val date = dateFmt.format(Date())
        val dateW = datePaint.measureText(date)
        canvas.drawText(date, left + width - dateW, titleY, datePaint)
    }

    private fun drawColumn(
        canvas: Canvas,
        tasks: List<TimeBlockTask>,
        windowStart: Int,
        windowEnd: Int,
        left: Float,
        top: Float,
        width: Float,
        height: Float,
        density: Float,
        isDark: Boolean,
        colorScheme: FlutterColorScheme,
        nowMinutes: Int,
    ): List<TimeBlockHit> {
        val hours = ((windowEnd - windowStart) / 60f).coerceAtLeast(1f)
        val hourHeight = height / hours
        val labelW = TimeBlockLayout.TIME_LABEL_WIDTH_DP * density
        val gridLeft = left + labelW
        val gridW = (width - labelW).coerceAtLeast(1f)
        val labelPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.outlineColor()
            textSize = 9f * density
            textAlign = Paint.Align.CENTER
        }
        val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.surfaceContainerHighestColor()
            strokeWidth = 0.5f * density
        }

        for (hour in TimeBlockLayout.visibleHours(windowStart, windowEnd)) {
            val y = top + (hour * 60 - windowStart) / 60f * hourHeight
            canvas.drawText(
                TimeBlockLayout.formatHourLabel(hour),
                left + labelW / 2f,
                y + 10f * density,
                labelPaint,
            )
            canvas.drawLine(gridLeft, y, left + width, y, linePaint)
        }

        val items = TimeBlockLayout.layout(tasks, windowStart, windowEnd, hourHeight)
        val hits = mutableListOf<TimeBlockHit>()
        for (item in items) {
            val theme = item.task.priority.getColorScheme(isDark)
            val blockW = gridW * item.widthFactor
            val blockLeft = gridLeft + gridW * (item.columnIndex / item.columnCount.toFloat())
            val blockTop = top + item.top
            val rect = RectF(blockLeft, blockTop, blockLeft + blockW - 2f * density, blockTop + item.height)
            val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = theme.primaryContainerColor()
            }
            canvas.drawRoundRect(rect, 5f * density, 5f * density, bgPaint)

            val titlePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (item.task.isCompleted) theme.outlineColor() else theme.primaryColor()
                textSize = 10f * density
                isStrikeThruText = item.task.isCompleted
            }
            val title = TextUtils.ellipsize(
                item.task.title,
                titlePaint,
                (rect.width() - 16f * density).coerceAtLeast(8f),
                TextUtils.TruncateAt.END,
            ).toString()
            canvas.drawText(title, rect.left + 4f * density, rect.top + 12f * density, titlePaint)
            if (item.height >= 28f) {
                val timePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = if (item.task.isCompleted) theme.outlineColor() else theme.primaryColor()
                    textSize = 8f * density
                    typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                }
                canvas.drawText(
                    item.timeRangeLabel,
                    rect.left + 4f * density,
                    rect.top + 22f * density,
                    timePaint,
                )
            }
            hits.add(
                TimeBlockHit(
                    task = item.task,
                    left = blockLeft,
                    top = blockTop,
                    width = blockW,
                    height = item.height,
                ),
            )
        }

        if (nowMinutes in windowStart until windowEnd) {
            val nowY = top + (nowMinutes - windowStart) / 60f * hourHeight
            val error = colorScheme.errorColor()
            val onError = colorScheme.onErrorColor()
            val nowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = error }
            val label = TimeBlockLayout.formatNowLabel(nowMinutes)
            val nowText = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = onError
                textSize = 8f * density
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                textAlign = Paint.Align.CENTER
            }
            val badgeW = nowText.measureText(label) + 6f * density
            val badgeH = 12f * density
            val badgeRect = RectF(
                left + (labelW - badgeW) / 2f,
                nowY - badgeH / 2f,
                left + (labelW + badgeW) / 2f,
                nowY + badgeH / 2f,
            )
            canvas.drawRoundRect(badgeRect, 3f * density, 3f * density, nowPaint)
            canvas.drawText(label, badgeRect.centerX(), nowY + 3f * density, nowText)
            canvas.drawCircle(gridLeft, nowY, 3f * density, nowPaint)
            canvas.drawRect(gridLeft, nowY - density, left + width, nowY + density, nowPaint)
        }

        return hits
    }

    private fun drawLocked(
        context: Context,
        canvas: Canvas,
        width: Int,
        height: Int,
        density: Float,
        colorScheme: FlutterColorScheme,
    ) {
        val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = colorScheme.errorColor() }
        val cx = width / 2f
        val cy = height / 2f - 16f * density
        canvas.drawCircle(cx, cy, 14f * density, iconPaint)
        val lockPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.onErrorColor()
            textSize = 14f * density
            textAlign = Paint.Align.CENTER
            typeface = Typeface.DEFAULT_BOLD
        }
        canvas.drawText("🔒", cx, cy + 5f * density, lockPaint)
        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.outlineColor()
            textSize = 12f * density
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(
            context.getString(R.string.widget_time_block_locked),
            cx,
            cy + 32f * density,
            textPaint,
        )
    }
}
