package com.bapaws.planbook.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.Button
import com.bapaws.planbook.R

/**
 * Widget 配置界面
 * 支持选择过滤模式：今天 / 收集箱 / 已逾期
 */
class WidgetConfigureActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 设置结果为 CANCEL，防止用户直接返回时添加 widget
        setResult(RESULT_CANCELED)

        // 获取 widget ID
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.activity_widget_configure)

        val radioGroup = findViewById<RadioGroup>(R.id.filter_mode_group)
        val saveButton = findViewById<Button>(R.id.save_button)

        // 读取当前 widget 实例保存的过滤模式
        val currentMode = WidgetSettings.getFilterMode(this, appWidgetId)
        when (currentMode) {
            TaskFilterMode.TODAY -> radioGroup.check(R.id.mode_today)
            TaskFilterMode.INBOX -> radioGroup.check(R.id.mode_inbox)
            TaskFilterMode.OVERDUE -> radioGroup.check(R.id.mode_overdue)
        }

        saveButton.setOnClickListener {
            val selectedMode = when (radioGroup.checkedRadioButtonId) {
                R.id.mode_inbox -> TaskFilterMode.INBOX
                R.id.mode_overdue -> TaskFilterMode.OVERDUE
                else -> TaskFilterMode.TODAY
            }

            // 保存过滤模式（按 widget 实例隔离）
            WidgetSettings.saveFilterMode(this, appWidgetId, selectedMode)

            // 更新 widget
            val appWidgetManager = AppWidgetManager.getInstance(this)
            QuadrantWidgetLargeProvider.updateLargeWidget(this, appWidgetManager, appWidgetId)
            QuadrantWidgetSmallProvider.updateSmallWidget(this, appWidgetManager, appWidgetId)

            // 返回成功结果
            val resultValue = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }
}
