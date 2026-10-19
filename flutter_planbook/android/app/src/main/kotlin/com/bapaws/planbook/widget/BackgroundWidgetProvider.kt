package com.bapaws.planbook.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.Log
import java.util.concurrent.Executors

/** 小组件读库与绘图共用串行后台队列，广播结束前保留 PendingResult。 */
abstract class BackgroundWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in setOf(
                AppWidgetManager.ACTION_APPWIDGET_UPDATE,
                AppWidgetManager.ACTION_APPWIDGET_OPTIONS_CHANGED,
                AppWidgetManager.ACTION_APPWIDGET_RESTORED,
            )
        ) {
            super.onReceive(context, intent)
            return
        }

        val pendingResult = goAsync()
        val appContext = context.applicationContext
        val ids = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
            ?.sorted()?.joinToString(",").orEmpty()
        val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        val key = "${javaClass.name}:${intent.action}:$ids:$id"
        widgetUpdateQueue.submit(
            key = key,
            action = {
                val started = SystemClock.elapsedRealtime()
                try {
                    super.onReceive(appContext, intent)
                } finally {
                    Log.d(
                        "PlanbookWidgetUpdate",
                        "Update finished: $key durationMs=${SystemClock.elapsedRealtime() - started}",
                    )
                }
            },
            onComplete = { pendingResult?.finish() },
        )
    }
}

/** 仅合并尚未执行的相同组件请求；执行中到来的新数据会再刷新一次。 */
private val widgetUpdateQueue = CoalescingWidgetUpdateQueue(
    Executors.newSingleThreadExecutor(),
) { key, error -> Log.e("PlanbookWidgetUpdate", "Update failed: $key", error) }

/** 点击后的刷新也走广播队列，避免与系统/Flutter 发起的更新交错绘制。 */
internal fun requestWidgetUpdate(context: Context, provider: Class<out AppWidgetProvider>) {
    val ids = AppWidgetManager.getInstance(context)
        .getAppWidgetIds(ComponentName(context, provider))
    if (ids.isEmpty()) return
    context.sendBroadcast(Intent(context, provider).apply {
        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
    })
}
