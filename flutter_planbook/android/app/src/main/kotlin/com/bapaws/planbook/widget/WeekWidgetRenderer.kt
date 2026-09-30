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
import java.util.Calendar

enum class WeekWidgetKind { LIST, GRID, MONTH }

data class WeekHit(
    val left: Float,
    val top: Float,
    val width: Float,
    val height: Float,
    val task: WeekTask? = null,
    val dateKey: String? = null,
)

object WeekWidgetRenderer {

    fun render(
        context: Context,
        widthPx: Int,
        heightPx: Int,
        kind: WeekWidgetKind,
        twoWeeks: Boolean,
        isDark: Boolean,
        tasks: List<WeekTask>,
        weeklyFocus: String?,
    ): Triple<Bitmap, List<WeekHit>, List<WeekHit>> {
        val bitmap = Bitmap.createBitmap(widthPx.coerceAtLeast(1), heightPx.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val density = context.resources.displayMetrics.density
        val colorScheme = WidgetSettings.getCurrentColorScheme(context)
        val start = WeekCalendar.startOfWeek()
        val dayCount = if (kind == WeekWidgetKind.MONTH && twoWeeks) 14 else 7
        val days = WeekCalendar.days(start, dayCount)
        val grouped = WeekCalendar.groupTasks(tasks, days)
        val (completed, total) = WeekCalendar.progress(tasks)
        val pad = 10f * density
        val headerH = 22f * density
        val completeHits = mutableListOf<WeekHit>()
        val dayHits = mutableListOf<WeekHit>()

        drawHeader(
            context, canvas, pad, pad, widthPx - pad * 2f, headerH, density, colorScheme,
            title = context.getString(
                if (twoWeeks) R.string.widget_week_two_weeks else R.string.widget_week_title,
            ),
            progress = if (total == 0) null else "$completed/$total",
            empty = if (total == 0) context.getString(R.string.widget_week_empty) else null,
            capsule = WeekCalendar.weekRangeLabel(context, days, twoWeeks),
        )

        val contentTop = pad + headerH + 6f * density
        val contentBottom = heightPx - pad
        val contentLeft = pad
        val contentRight = widthPx - pad
        when (kind) {
            WeekWidgetKind.LIST -> drawList(
                canvas, days, grouped, contentLeft, contentTop,
                contentRight - contentLeft, contentBottom - contentTop,
                density, isDark, colorScheme, completeHits, dayHits,
            )
            WeekWidgetKind.GRID -> drawGrid(
                context, canvas, days, grouped, weeklyFocus, contentLeft, contentTop,
                contentRight - contentLeft, contentBottom - contentTop,
                density, isDark, colorScheme, completeHits, dayHits,
            )
            WeekWidgetKind.MONTH -> drawMonth(
                canvas, days, grouped, contentLeft, contentTop,
                contentRight - contentLeft, contentBottom - contentTop,
                density, isDark, colorScheme, dayHits,
            )
        }
        return Triple(bitmap, completeHits, dayHits)
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
        title: String,
        progress: String?,
        empty: String?,
        capsule: String,
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
        val accentPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = colorScheme.primaryColor() }
        canvas.drawRoundRect(
            RectF(left, centerY - accentHeight / 2f, left + accentWidth, centerY + accentHeight / 2f),
            accentWidth / 2f, accentWidth / 2f, accentPaint,
        )
        val titleLeft = left + 8f * density
        canvas.drawText(title, titleLeft, titleY, titlePaint)

        val createButtonSize = 20f * density
        val createButtonRight = left + width
        val createButtonLeft = createButtonRight - createButtonSize
        val dateHorizontalPadding = 6f * density
        val dateVerticalPadding = 3f * density
        val dateW = datePaint.measureText(capsule)
        val dateHeight = datePaint.descent() - datePaint.ascent() + dateVerticalPadding * 2f
        val dateRight = createButtonLeft - 6f * density
        val dateLeft = dateRight - dateW - dateHorizontalPadding * 2f
        val dateBackgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.surfaceContainerHighestColor()
            alpha = 184
        }
        canvas.drawRoundRect(
            RectF(dateLeft, centerY - dateHeight / 2f, dateRight, centerY + dateHeight / 2f),
            dateHeight / 2f, dateHeight / 2f, dateBackgroundPaint,
        )
        val dateY = centerY - (datePaint.ascent() + datePaint.descent()) / 2f
        canvas.drawText(capsule, dateLeft + dateHorizontalPadding, dateY, datePaint)

        val createBackgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.primaryContainerColor()
            alpha = 224
        }
        val createCenterX = (createButtonLeft + createButtonRight) / 2f
        canvas.drawCircle(createCenterX, centerY, createButtonSize / 2f, createBackgroundPaint)
        val createPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.primaryColor()
            strokeWidth = 1.5f * density
            strokeCap = Paint.Cap.ROUND
        }
        val plusRadius = 3.5f * density
        canvas.drawLine(createCenterX - plusRadius, centerY, createCenterX + plusRadius, centerY, createPaint)
        canvas.drawLine(createCenterX, centerY - plusRadius, createCenterX, centerY + plusRadius, createPaint)

        val side = empty ?: progress
        if (side != null) {
            val emptyPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = colorScheme.outlineColor()
                textSize = 10f * density
            }
            val titleW = titlePaint.measureText(title)
            val emptyLeft = titleLeft + titleW + 5f * density
            val availableWidth = (dateLeft - 8f * density - emptyLeft).coerceAtLeast(0f)
            if (availableWidth > 0f) {
                val text = TextUtils.ellipsize(side, emptyPaint, availableWidth, TextUtils.TruncateAt.END)
                canvas.drawText(text.toString(), emptyLeft, titleY, emptyPaint)
            }
        }
    }

    private fun drawList(
        canvas: Canvas,
        days: List<Calendar>,
        grouped: Map<String, List<WeekTask>>,
        left: Float,
        top: Float,
        width: Float,
        height: Float,
        density: Float,
        isDark: Boolean,
        colorScheme: FlutterColorScheme,
        completeHits: MutableList<WeekHit>,
        dayHits: MutableList<WeekHit>,
    ) {
        val rowH = height / 7f
        val chipW = 40f * density
        days.forEachIndexed { index, day ->
            val rowTop = top + index * rowH
            val theme = weekdayColorScheme(day.get(Calendar.DAY_OF_WEEK), isDark)
            val today = WeekCalendar.isToday(day)
            val chipRect = RectF(left, rowTop + 2f * density, left + chipW, rowTop + rowH - 2f * density)
            val chipPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (today) theme.primaryColor() else theme.primaryContainerColor()
            }
            canvas.drawRoundRect(chipRect, 8f * density, 8f * density, chipPaint)
            val weekdayPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (today) theme.onPrimaryColor() else theme.primaryColor()
                textSize = 10f * density
                typeface = Typeface.DEFAULT_BOLD
                textAlign = Paint.Align.CENTER
            }
            val numberPaint = TextPaint(weekdayPaint).apply {
                color = if (today) theme.onPrimaryColor() else theme.outlineColor()
                typeface = Typeface.DEFAULT
            }
            canvas.drawText(WeekCalendar.shortWeekday(day), chipRect.centerX(), chipRect.centerY() - 4f * density, weekdayPaint)
            canvas.drawText(WeekCalendar.dayNumber(day), chipRect.centerX(), chipRect.centerY() + 8f * density, numberPaint)
            dayHits.add(WeekHit(chipRect.left, chipRect.top, chipRect.width(), chipRect.height(), dateKey = WeekCalendar.dayKey(day)))

            val tasks = grouped[WeekCalendar.dayKey(day)].orEmpty()
            val visible = tasks.take(4)
            val colW = (width - chipW - 6f * density) / 2f
            val taskLeft = left + chipW + 6f * density
            visible.forEachIndexed { i, task ->
                val col = i % 2
                val row = i / 2
                val tLeft = taskLeft + col * colW
                val tTop = rowTop + row * (rowH / 2f)
                completeHits.add(drawTaskRow(canvas, task, tLeft, tTop, colW - 4f * density, rowH / 2f - 2f * density, density, isDark))
            }
            if (tasks.size > 4) {
                val extraPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = colorScheme.outlineColor()
                    textSize = 10f * density
                }
                canvas.drawText("+${tasks.size - 4}", taskLeft, rowTop + rowH - 4f * density, extraPaint)
            }
        }
    }

    private fun drawGrid(
        context: Context,
        canvas: Canvas,
        days: List<Calendar>,
        grouped: Map<String, List<WeekTask>>,
        weeklyFocus: String?,
        left: Float,
        top: Float,
        width: Float,
        height: Float,
        density: Float,
        isDark: Boolean,
        colorScheme: FlutterColorScheme,
        completeHits: MutableList<WeekHit>,
        dayHits: MutableList<WeekHit>,
    ) {
        val colW = width / 2f
        val rowH = height / 4f
        val cells = listOf<Calendar?>(null) + days
        cells.forEachIndexed { index, day ->
            val col = index % 2
            val row = index / 2
            val cellLeft = left + col * colW
            val cellTop = top + row * rowH
            if (day == null) {
                drawFocusCell(context, canvas, weeklyFocus, cellLeft, cellTop, colW, rowH, density, colorScheme)
            } else {
                val theme = weekdayColorScheme(day.get(Calendar.DAY_OF_WEEK), isDark)
                val today = WeekCalendar.isToday(day)
                val header = "${WeekCalendar.shortWeekday(day)} ${WeekCalendar.dayNumber(day)}"
                val tasks = grouped[WeekCalendar.dayKey(day)].orEmpty()
                drawPill(canvas, header, cellLeft + 4f * density, cellTop + 2f * density, density, theme, today)
                val countPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = colorScheme.outlineColor()
                    textSize = 9f * density
                    textAlign = Paint.Align.RIGHT
                }
                canvas.drawText("${tasks.size}", cellLeft + colW - 6f * density, cellTop + 14f * density, countPaint)
                dayHits.add(WeekHit(cellLeft, cellTop, colW, 18f * density, dateKey = WeekCalendar.dayKey(day)))
                tasks.take(3).forEachIndexed { i, task ->
                    val tTop = cellTop + 18f * density + i * 14f * density
                    completeHits.add(drawTaskRow(canvas, task, cellLeft + 4f * density, tTop, colW - 8f * density, 14f * density, density, isDark))
                }
            }
        }
    }

    private fun drawFocusCell(
        context: Context,
        canvas: Canvas,
        weeklyFocus: String?,
        left: Float,
        top: Float,
        width: Float,
        height: Float,
        density: Float,
        colorScheme: FlutterColorScheme,
    ) {
        val pillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = colorScheme.primaryContainerColor() }
        val pillH = 16f * density
        canvas.drawRoundRect(
            RectF(left + 4f * density, top + 2f * density, left + 72f * density, top + 2f * density + pillH),
            pillH / 2f, pillH / 2f, pillPaint,
        )
        val titlePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.onPrimaryContainerColor()
            textSize = 10f * density
            typeface = Typeface.DEFAULT_BOLD
        }
        canvas.drawText(
            context.getString(R.string.widget_week_focus),
            left + 10f * density,
            top + 2f * density + pillH / 2f - (titlePaint.ascent() + titlePaint.descent()) / 2f,
            titlePaint,
        )
        val lines = weeklyFocus
            ?.replace("\r\n", "\n")
            ?.lines()
            ?.map { it.trim() }
            ?.filter { it.isNotEmpty() }
            .orEmpty()
        val bodyPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (lines.isEmpty()) colorScheme.outlineColor() else colorScheme.onSurfaceColor()
            textSize = 10f * density
        }
        val body = if (lines.isEmpty()) {
            listOf(context.getString(R.string.widget_week_focus_empty))
        } else {
            lines.take(3)
        }
        body.forEachIndexed { i, line ->
            val text = TextUtils.ellipsize(line, bodyPaint, width - 12f * density, TextUtils.TruncateAt.END)
            canvas.drawText(text.toString(), left + 6f * density, top + 24f * density + i * 12f * density, bodyPaint)
        }
    }

    private fun drawMonth(
        canvas: Canvas,
        days: List<Calendar>,
        grouped: Map<String, List<WeekTask>>,
        left: Float,
        top: Float,
        width: Float,
        height: Float,
        density: Float,
        isDark: Boolean,
        colorScheme: FlutterColorScheme,
        dayHits: MutableList<WeekHit>,
    ) {
        val weeks = days.chunked(7)
        val headerH = 14f * density
        val weekH = (height - headerH) / weeks.size.coerceAtLeast(1)
        val colW = width / 7f
        val weekdayPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorScheme.outlineColor()
            textSize = 9f * density
            textAlign = Paint.Align.CENTER
        }
        weeks.firstOrNull()?.forEachIndexed { i, day ->
            canvas.drawText(
                WeekCalendar.shortWeekday(day),
                left + (i + 0.5f) * colW,
                top + 10f * density,
                weekdayPaint,
            )
        }
        weeks.forEachIndexed { w, week ->
            val weekTop = top + headerH + w * weekH
            week.forEachIndexed { i, day ->
                val cellLeft = left + i * colW
                val today = WeekCalendar.isToday(day)
                val numPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = if (today) colorScheme.onPrimaryColor() else colorScheme.onSurfaceColor()
                    textSize = 10f * density
                    typeface = Typeface.DEFAULT_BOLD
                    textAlign = Paint.Align.CENTER
                }
                val cx = cellLeft + 10f * density
                val cy = weekTop + 10f * density
                if (today) {
                    val circle = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = colorScheme.primaryColor() }
                    canvas.drawCircle(cx, cy, 8f * density, circle)
                }
                canvas.drawText(WeekCalendar.dayNumber(day), cx, cy - (numPaint.ascent() + numPaint.descent()) / 2f, numPaint)
                dayHits.add(WeekHit(cellLeft, weekTop, colW, weekH, dateKey = WeekCalendar.dayKey(day)))
                val tasks = grouped[WeekCalendar.dayKey(day)].orEmpty()
                val visible = tasks.take(3)
                visible.forEachIndexed { ti, task ->
                    val theme = task.priority.getColorScheme(isDark)
                    val barTop = weekTop + 20f * density + ti * 14f * density
                    val bar = RectF(cellLeft + 2f * density, barTop, cellLeft + colW - 2f * density, barTop + 12f * density)
                    val bg = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        color = if (task.isCompleted) theme.surfaceContainerColor() else theme.primaryContainerColor()
                    }
                    canvas.drawRoundRect(bar, 2f * density, 2f * density, bg)
                    val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                        color = if (task.isCompleted) theme.outlineColor() else colorScheme.onSurfaceColor()
                        textSize = 8f * density
                    }
                    val text = TextUtils.ellipsize(task.title, textPaint, bar.width() - 6f * density, TextUtils.TruncateAt.END)
                    canvas.drawText(text.toString(), bar.left + 3f * density, bar.centerY() - (textPaint.ascent() + textPaint.descent()) / 2f, textPaint)
                }
                if (tasks.size > 3) {
                    val extraPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                        color = colorScheme.outlineColor()
                        textSize = 8f * density
                    }
                    canvas.drawText("+${tasks.size - 3}", cellLeft + 4f * density, weekTop + 20f * density + 3 * 14f * density, extraPaint)
                }
            }
        }
    }

    private fun drawPill(
        canvas: Canvas,
        title: String,
        left: Float,
        top: Float,
        density: Float,
        theme: FlutterColorScheme,
        today: Boolean,
    ) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (today) theme.primaryColor() else theme.primaryContainerColor()
        }
        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (today) theme.onPrimaryColor() else theme.onPrimaryContainerColor()
            textSize = 10f * density
            typeface = Typeface.DEFAULT_BOLD
        }
        val w = textPaint.measureText(title) + 12f * density
        val h = 16f * density
        canvas.drawRoundRect(RectF(left, top, left + w, top + h), h / 2f, h / 2f, paint)
        canvas.drawText(title, left + 6f * density, top + h / 2f - (textPaint.ascent() + textPaint.descent()) / 2f, textPaint)
    }

    private fun drawTaskRow(
        canvas: Canvas,
        task: WeekTask,
        left: Float,
        top: Float,
        width: Float,
        height: Float,
        density: Float,
        isDark: Boolean,
    ): WeekHit {
        val theme = task.priority.getColorScheme(isDark)
        val accent = if (task.isCompleted) theme.outlineColor() else theme.primaryColor()
        val cx = left + 6f * density
        val cy = top + height / 2f
        val circle = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = accent
            style = if (task.isCompleted) Paint.Style.FILL else Paint.Style.STROKE
            strokeWidth = 1.2f * density
        }
        canvas.drawCircle(cx, cy, 5f * density, circle)
        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (task.isCompleted) theme.outlineColor() else theme.onSurfaceVariantColor()
            textSize = 11f * density
            isStrikeThruText = task.isCompleted
        }
        val text = TextUtils.ellipsize(task.title, textPaint, width - 16f * density, TextUtils.TruncateAt.END)
        canvas.drawText(text.toString(), left + 14f * density, cy - (textPaint.ascent() + textPaint.descent()) / 2f, textPaint)
        return WeekHit(left, top, width, height, task = task)
    }
}
