package com.bapaws.planbook.widget

import android.content.Context
import android.content.Intent

/**
 * Widget 工具类
 */
object WidgetActionUtils {

    /** 获取指定 widget 实例的过滤模式 */
    fun getFilterMode(context: Context, appWidgetId: Int): TaskFilterMode {
        return WidgetSettings.getFilterMode(context, appWidgetId)
    }

    /** 创建打开 App 的 Intent */
    fun createOpenAppIntent(context: Context, deepLink: String? = null): Intent {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent()
        if (deepLink != null) {
            intent.action = Intent.ACTION_VIEW
            intent.data = android.net.Uri.parse(deepLink)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return intent
    }
}
