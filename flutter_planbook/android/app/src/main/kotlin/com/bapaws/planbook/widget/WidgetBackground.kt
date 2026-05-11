package com.bapaws.planbook.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.glance.GlanceModifier
import androidx.glance.ImageProvider
import androidx.glance.background
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
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

/**
 * 小组件背景
 * 使用纯色背景，兼容所有 ROM（包括 MIUI）
 * Glance 的 Image/background(ImageProvider) 在部分国产 ROM 上存在兼容性问题
 */
@Composable
fun WidgetTiledBackground(resId: Int) {
    // 暂时使用纯色背景，避免 MIUI 等 ROM 上图片背景渲染异常
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(Color(0xFFF8F9FA)),
        content = {}
    )
}
