package com.bapaws.planbook.widget

import android.content.Context
import com.bapaws.planbook.R

/**
 * Widget 背景配置
 * 对应 iOS 端 WidgetBackground.swift
 */
data class WidgetBackgroundConfig(
    val assetName: String,
    val isDarkMode: Boolean
) {
    companion object {
        fun current(context: Context): WidgetBackgroundConfig {
            return WidgetBackgroundConfig(
                assetName = WidgetSettings.getBackgroundAsset(context),
                isDarkMode = WidgetSettings.isDarkMode(context)
            )
        }

        /** 安全地获取背景资源 ID，验证失败时回退到默认资源 */
        fun safeBackgroundResId(context: Context): Int {
            val config = current(context)
            val isSystemDark = context.resources.configuration.uiMode and
                    android.content.res.Configuration.UI_MODE_NIGHT_MASK ==
                    android.content.res.Configuration.UI_MODE_NIGHT_YES
            val isDark = isSystemDark || config.isDarkMode
            val suffix = if (isDark) "dark" else "light"
            val resName = "${config.assetName}_tile_${suffix}_repeat"
            val resId = try {
                context.resources.getIdentifier(resName, "drawable", context.packageName)
            } catch (_: Exception) {
                0
            }
            return if (resId != 0) {
                // 额外验证 drawable 能否加载
                try {
                    context.resources.getDrawable(resId, null)
                    resId
                } catch (_: Exception) {
                    R.drawable.bg_dot_tile_light_repeat
                }
            } else {
                R.drawable.bg_dot_tile_light_repeat
            }
        }
    }
}
