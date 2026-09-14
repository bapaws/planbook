package com.bapaws.planbook.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import com.bapaws.planbook.R
import java.text.DateFormat
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

        val pad = 10f * density
        val compact = widthPx / density < 220f
        val headerH = TimeBlockLayout.HEADER_HEIGHT_DP * density
        val contentTop = pad + headerH + 6f * density
        val contentLeft = if (compact) 0f else pad
        val contentRight = widthPx - pad
        val contentBottom = heightPx - pad
        val contentH = (contentBottom - contentTop).coerceAtLeast(1f)
        val contentW = (contentRight - contentLeft).coerceAtLeast(1f)
        val nowMinutes = TimeBlockLayout.nowMinutes()

        drawHeader(
            context, canvas, pad, pad,
            widthPx - pad * 2f, headerH, density, colorScheme,
            showEmpty = tasks.isEmpty(),
            compact = compact,
        )

        val hits = mutableListOf<TimeBlockHit>()
        if (isLarge) {
            val gap = 10f * density
            val colW = (contentW - gap) / 2f
            hits += drawColumn(
                canvas, tasks, 0, 12 * 60,
                contentLeft, contentTop, colW, contentH, density, isDark, colorScheme, nowMinutes,
            )
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
        showEmpty: Boolean,
        compact: Boolean,
    ) {
        val titlePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.onSurfaceColor()
            textSize = 14f * density
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        val datePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.outlineColor()
            textSize = 10f * density
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        val centerY = top + height / 2f
        val titleY = centerY - (titlePaint.ascent() + titlePaint.descent()) / 2f
        val accentWidth = 3f * density
        val accentHeight = 14f * density
        val accentPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.primaryColor()
        }
        canvas.drawRoundRect(
            RectF(
                left,
                centerY - accentHeight / 2f,
                left + accentWidth,
                centerY + accentHeight / 2f,
            ),
            accentWidth / 2f,
            accentWidth / 2f,
            accentPaint,
        )

        val titleLeft = left + 8f * density
        val title = context.getString(R.string.widget_time_block_today)
        canvas.drawText(title, titleLeft, titleY, titlePaint)

        val dateFmt = DateFormat.getDateInstance(DateFormat.MEDIUM, Locale.getDefault())
        val date = dateFmt.format(Date())
        val dateHorizontalPadding = 6f * density
        val dateVerticalPadding = 3f * density
        val dateW = if (compact) 0f else datePaint.measureText(date)
        val dateHeight = datePaint.descent() - datePaint.ascent() + dateVerticalPadding * 2f
        val createButtonSize = 20f * density
        val createButtonGap = 6f * density
        val createButtonRight = left + width
        val createButtonLeft = createButtonRight - createButtonSize
        val dateRight = createButtonLeft - createButtonGap
        val dateLeft = if (compact) {
            createButtonLeft
        } else {
            dateRight - dateW - dateHorizontalPadding * 2f
        }
        if (!compact) {
            val dateBackgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = colorScheme.surfaceContainerHighestColor()
                alpha = 184
            }
            canvas.drawRoundRect(
                RectF(
                    dateLeft,
                    centerY - dateHeight / 2f,
                    dateRight,
                    centerY + dateHeight / 2f,
                ),
                dateHeight / 2f,
                dateHeight / 2f,
                dateBackgroundPaint,
            )
            val dateY = centerY - (datePaint.ascent() + datePaint.descent()) / 2f
            canvas.drawText(date, dateLeft + dateHorizontalPadding, dateY, datePaint)
        }

        val createBackgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.primaryContainerColor()
            alpha = 224
        }
        val createCenterX = (createButtonLeft + createButtonRight) / 2f
        canvas.drawCircle(
            createCenterX,
            centerY,
            createButtonSize / 2f,
            createBackgroundPaint,
        )
        val createPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.primaryColor()
            strokeWidth = 1.5f * density
            strokeCap = Paint.Cap.ROUND
        }
        val plusRadius = 3.5f * density
        canvas.drawLine(
            createCenterX - plusRadius,
            centerY,
            createCenterX + plusRadius,
            centerY,
            createPaint,
        )
        canvas.drawLine(
            createCenterX,
            centerY - plusRadius,
            createCenterX,
            centerY + plusRadius,
            createPaint,
        )

        if (!compact && showEmpty) {
            val emptyPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = colorScheme.outlineColor()
                textSize = 10f * density
            }
            val titleW = titlePaint.measureText(title)
            val emptyLeft = titleLeft + titleW + 5f * density
            val availableWidth = (dateLeft - 8f * density - emptyLeft).coerceAtLeast(0f)
            if (availableWidth > 0f) {
                val empty = TextUtils.ellipsize(
                    context.getString(R.string.widget_time_block_empty),
                    emptyPaint,
                    availableWidth,
                    TextUtils.TruncateAt.END,
                )
                canvas.drawText(empty.toString(), emptyLeft, titleY, emptyPaint)
            }
        }
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
        val gridTopInset = TimeBlockLayout.GRID_TOP_INSET_DP * density
        val hourHeight = (height - gridTopInset).coerceAtLeast(1f) / hours
        val labelW = TimeBlockLayout.TIME_LABEL_WIDTH_DP * density
        val gridLeft = left + labelW
        val gridW = (width - labelW).coerceAtLeast(1f)
        val labelPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.outlineColor()
            textSize = 8f * density
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
            textAlign = Paint.Align.CENTER
        }
        val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.surfaceContainerHighestColor()
            strokeWidth = 0.5f * density
        }

        for (hour in TimeBlockLayout.visibleHours(windowStart, windowEnd)) {
            val labelTop = top + (hour * 60 - windowStart) / 60f * hourHeight
            val lineY = labelTop + gridTopInset
            val fm = labelPaint.fontMetrics
            canvas.drawText(
                TimeBlockLayout.formatHourLabel(hour),
                left + labelW / 2f,
                labelTop - fm.ascent,
                labelPaint,
            )
            linePaint.strokeWidth = if (hour == 0 || hour == 12) density else 0.5f * density
            canvas.drawLine(gridLeft, lineY, left + width, lineY, linePaint)
        }

        val items = TimeBlockLayout.layout(tasks, windowStart, windowEnd, hourHeight)
        val hits = mutableListOf<TimeBlockHit>()
        for (item in items) {
            val theme = item.task.priority.getColorScheme(isDark)
            val blockW = gridW * item.widthFactor
            val blockLeft = gridLeft + gridW * (item.columnIndex / item.columnCount.toFloat())
            val blockTop = top + gridTopInset + item.top
            val rect = RectF(blockLeft, blockTop, blockLeft + blockW, blockTop + item.height)
            val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = theme.primaryContainerColor()
                alpha = 235
            }
            canvas.drawRoundRect(rect, 6f * density, 6f * density, bgPaint)

            val accent = if (item.task.isCompleted) theme.outlineColor() else theme.primaryColor()
            val titlePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (item.task.isCompleted) theme.outlineColor() else theme.primaryColor()
                textSize = 9f * density
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                isStrikeThruText = item.task.isCompleted
            }
            val completeSize = 11f * density
            val completeTrailing = 3f * density
            val completeTop = 2f * density
            val completeCx = rect.right - completeTrailing - completeSize / 2f
            val completeCy = rect.top + completeTop + completeSize / 2f
            val completePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = accent
                strokeWidth = 1.4f * density
                style = if (item.task.isCompleted) Paint.Style.FILL else Paint.Style.STROKE
            }
            canvas.drawCircle(completeCx, completeCy, completeSize / 2f, completePaint)
            if (item.task.isCompleted) {
                val checkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = theme.primaryContainerColor()
                    strokeWidth = 1.4f * density
                    strokeCap = Paint.Cap.ROUND
                    style = Paint.Style.STROKE
                }
                canvas.drawLine(
                    completeCx - 2.4f * density,
                    completeCy,
                    completeCx - 0.4f * density,
                    completeCy + 2.2f * density,
                    checkPaint,
                )
                canvas.drawLine(
                    completeCx - 0.4f * density,
                    completeCy + 2.2f * density,
                    completeCx + 2.8f * density,
                    completeCy - 2.2f * density,
                    checkPaint,
                )
            }

            val titleLeft = rect.left + 5f * density
            val titleMaxWidth = (
                completeCx - completeSize / 2f - 2f * density - titleLeft
            ).coerceAtLeast(8f)
            val title = TextUtils.ellipsize(
                item.task.title,
                titlePaint,
                titleMaxWidth,
                TextUtils.TruncateAt.END,
            ).toString()
            canvas.drawText(title, titleLeft, rect.top + 11f * density, titlePaint)
            if (item.height >= 32f) {
                val timePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = accent
                    textSize = 8f * density
                }
                canvas.drawText(
                    item.timeRangeLabel,
                    titleLeft,
                    rect.top + 21f * density,
                    timePaint,
                )
            }
            val completeHitSize = maxOf(17f * density, completeSize)
                .coerceAtMost(item.height)
                .coerceAtMost(blockW)
            hits.add(
                TimeBlockHit(
                    task = item.task,
                    left = blockLeft,
                    top = blockTop,
                    width = (blockW - completeHitSize).coerceAtLeast(8f),
                    height = item.height,
                    completeLeft = rect.right - completeHitSize,
                    completeTop = blockTop,
                    completeWidth = completeHitSize,
                    completeHeight = completeHitSize,
                ),
            )
        }

        if (nowMinutes in windowStart until windowEnd) {
            val nowY = top + gridTopInset + (nowMinutes - windowStart) / 60f * hourHeight
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
            val badgeH = 11f * density
            val badgeRect = RectF(
                left + (labelW - badgeW) / 2f,
                nowY - badgeH / 2f,
                left + (labelW + badgeW) / 2f,
                nowY + badgeH / 2f,
            )
            canvas.drawRoundRect(badgeRect, 4f * density, 4f * density, nowPaint)
            canvas.drawText(label, badgeRect.centerX(), nowY - (nowText.fontMetrics.ascent + nowText.fontMetrics.descent) / 2f, nowText)
            canvas.drawCircle(gridLeft, nowY, 2.5f * density, nowPaint)
            canvas.drawRect(gridLeft, nowY - 0.75f * density, left + width, nowY + 0.75f * density, nowPaint)
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
        val cx = width / 2f
        val cy = height / 2f - 11f * density
        val lockPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.errorColor()
            strokeWidth = 2.2f * density
            strokeCap = Paint.Cap.ROUND
            style = Paint.Style.STROKE
        }
        canvas.drawArc(
            RectF(cx - 5f * density, cy - 10f * density, cx + 5f * density, cy),
            180f,
            180f,
            false,
            lockPaint,
        )
        lockPaint.style = Paint.Style.FILL
        canvas.drawRoundRect(
            RectF(cx - 8f * density, cy - 2f * density, cx + 8f * density, cy + 9f * density),
            2.5f * density,
            2.5f * density,
            lockPaint,
        )
        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.outlineColor()
            textSize = 12f * density
        }
        @Suppress("DEPRECATION")
        val textLayout = StaticLayout(
            context.getString(R.string.widget_time_block_locked),
            textPaint,
            (width - 20f * density).toInt().coerceAtLeast(1),
            Layout.Alignment.ALIGN_CENTER,
            1f,
            0f,
            false,
        )
        canvas.save()
        canvas.translate(10f * density, cy + 17f * density)
        textLayout.draw(canvas)
        canvas.restore()
    }
}
