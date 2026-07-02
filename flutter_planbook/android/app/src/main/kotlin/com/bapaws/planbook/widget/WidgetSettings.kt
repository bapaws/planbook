package com.bapaws.planbook.widget

import android.content.Context
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

/**
 * Widget 配置统一管理
 * 对应 iOS 端 WidgetSettings.swift
 */
object WidgetSettings {
    private const val PREFERENCES = "HomeWidgetPreferences"

    private const val KEY_SELECTED_PRIORITY = "widget_quadrant_selected_priority"
    private const val KEY_BACKGROUND_ASSET = "widget_background_asset"
    private const val KEY_WIDGET_THEME = "widget_theme"
    private const val KEY_LIGHT_COLOR_SCHEME = "__settings_light_color_scheme_key__"
    private const val KEY_DARK_COLOR_SCHEME = "__settings_dark_color_scheme_key__"
    private const val KEY_FILTER_MODE_PREFIX = "widget_filter_mode_"

    // 与 Flutter SettingsRepository.kSettingsQuadrantConfigs 保持一致
    private const val KEY_QUADRANT_CONFIGS = "widget_quadrant_configs"

    // 与 Flutter SettingsRepository.kSettingsTaskAutoNoteRulesKey 保持一致
    private const val KEY_TASK_AUTO_NOTE_RULES = "__settings_task_auto_note_rules_key__"

    /// pending 完成状态：widget 点击后写入，UI 立刻反馈；
    /// Flutter 端真正改完 DB 后清除这一项。
    /// 字典格式（JSON）：{"taskId": true/false}。
    private const val KEY_PENDING_COMPLETION_STATES = "widget_pending_completion_states"

    /**
     * 当前登录用户 ID 在 SharedPreferences 中的 key。
     * 必须与 Flutter 端 `packages/planbook_repository/lib/users/users_repository.dart`
     * 中的 `kUserId` 保持一致——Flutter 在登录 / 注销时通过 home_widget 写入 / 清除。
     */
    private const val KEY_CURRENT_USER_ID = "__supabase_user_id__"

    private fun getPrefs(context: Context): SharedPreferences {
        return HomeWidgetPlugin.getData(context)
    }

    /** 当前过滤模式（按 widget 实例隔离） */
    fun getFilterMode(context: Context, appWidgetId: Int): TaskFilterMode {
        val rawValue = getPrefs(context).getString("$KEY_FILTER_MODE_PREFIX$appWidgetId", null)
        return TaskFilterMode.fromRawValue(rawValue)
    }

    fun saveFilterMode(context: Context, appWidgetId: Int, mode: TaskFilterMode) {
        getPrefs(context).edit().putString("$KEY_FILTER_MODE_PREFIX$appWidgetId", mode.rawValue).apply()
    }

    /**
     * 当前登录的 Supabase 用户 ID；未登录或值为空字符串时返回 null。
     *
     * 与 Flutter 端 DatabaseTaskTodayApi / InboxApi / OverdueApi 的查询语义对齐：
     *   未登录 → 仅展示 `tasks.user_id IS NULL` 的任务
     *   已登录 → 仅展示 `tasks.user_id = ?` 的任务
     */
    fun getCurrentUserId(context: Context): String? {
        val raw = getPrefs(context).getString(KEY_CURRENT_USER_ID, null)?.trim()
        return if (raw.isNullOrEmpty()) null else raw
    }

    /** 当前选中的象限优先级（中号组件切换） */
    fun getSelectedPriority(context: Context): TaskPriority {
        val rawValue = getPrefs(context).getString(KEY_SELECTED_PRIORITY, null)
        return TaskPriority.fromRawValue(rawValue)
    }

    fun setSelectedPriority(context: Context, priority: TaskPriority) {
        getPrefs(context).edit().putString(KEY_SELECTED_PRIORITY, priority.rawValue).apply()
    }

    /**
     * 四象限自定义名称（仅包含非空名称）。
     * Flutter 端 jsonEncode 写入 [{"priority","name"}, ...]。
     */
    fun getQuadrantConfigs(context: Context): Map<String, String> {
        val json = getPrefs(context).getString(KEY_QUADRANT_CONFIGS, null) ?: return emptyMap()
        return try {
            val arr = JSONArray(json)
            val result = mutableMapOf<String, String>()
            for (i in 0 until arr.length()) {
                val obj = arr.optJSONObject(i) ?: continue
                val priority = obj.optString("priority", "")
                if (priority.isEmpty()) continue
                val name = if (obj.isNull("name")) null else obj.optString("name", null)
                if (!name.isNullOrEmpty()) {
                    result[priority] = name
                }
            }
            result
        } catch (_: Exception) {
            emptyMap()
        }
    }

    /** 读取某个象限的自定义名称；未配置或为空时返回 null */
    fun getCustomQuadrantName(context: Context, priority: TaskPriority): String? {
        return getQuadrantConfigs(context)[priority.rawValue]
    }

    /** 背景资源名称（Flutter 同步写入） */
    fun getBackgroundAsset(context: Context): String {
        return getPrefs(context).getString(KEY_BACKGROUND_ASSET, "bg_dot") ?: "bg_dot"
    }

    /** 是否为深色模式（从 widget_theme 解析） */
    fun isDarkMode(context: Context): Boolean {
        val themeJson = getPrefs(context).getString(KEY_WIDGET_THEME, null) ?: return false
        return try {
            val theme = org.json.JSONObject(themeJson)
            theme.optBoolean("isDarkMode", false)
        } catch (_: Exception) {
            false
        }
    }

    /** 亮色主题颜色方案 JSON */
    fun getLightColorSchemeJSON(context: Context): String? {
        return getPrefs(context).getString(KEY_LIGHT_COLOR_SCHEME, null)
    }

    /** 暗色主题颜色方案 JSON */
    fun getDarkColorSchemeJSON(context: Context): String? {
        return getPrefs(context).getString(KEY_DARK_COLOR_SCHEME, null)
    }

    // ============================================
    // Pending 完成状态（Widget 乐观 UI）
    //
    // 工作流：
    //   1. 用户在 widget 上点击任务行 → WidgetClickReceiver 把翻转后的目标状态
    //      写到 pending map 并刷新 widget。
    //   2. Provider 在拼装 RemoteViews 时把 pending 覆盖到 DB 查到的 isCompleted，
    //      让 widget UI 立刻反馈（哪怕主 App 还没启动）。
    //   3. Flutter 端跑完业务后 WidgetClickReceiver 清除对应 taskId 的 pending，
    //      之后 widget 重新刷新就读到权威 DB 状态，pending 不再生效。
    // ============================================

    /** 读取所有 pending 状态 */
    fun getPendingCompletions(context: Context): Map<String, Boolean> {
        val json = getPrefs(context).getString(KEY_PENDING_COMPLETION_STATES, null) ?: return emptyMap()
        return try {
            val obj = org.json.JSONObject(json)
            val result = mutableMapOf<String, Boolean>()
            obj.keys().forEach { key ->
                result[key] = obj.optBoolean(key, false)
            }
            result
        } catch (_: Exception) {
            emptyMap()
        }
    }

    /** 写入某个任务的 pending 状态 */
    fun setPendingCompletion(context: Context, taskId: String, completed: Boolean) {
        val map = getPendingCompletions(context).toMutableMap()
        map[taskId] = completed
        val obj = org.json.JSONObject()
        map.forEach { (k, v) -> obj.put(k, v) }
        getPrefs(context).edit().putString(KEY_PENDING_COMPLETION_STATES, obj.toString()).apply()
    }

    /** 清除某个任务的 pending 状态 */
    fun clearPendingCompletion(context: Context, taskId: String) {
        val map = getPendingCompletions(context).toMutableMap()
        if (map.remove(taskId) == null) return
        if (map.isEmpty()) {
            getPrefs(context).edit().remove(KEY_PENDING_COMPLETION_STATES).apply()
        } else {
            val obj = org.json.JSONObject()
            map.forEach { (k, v) -> obj.put(k, v) }
            getPrefs(context).edit().putString(KEY_PENDING_COMPLETION_STATES, obj.toString()).apply()
        }
    }

    /** 获取单个任务的 pending 状态；不存在返回 null */
    fun pendingCompletion(context: Context, taskId: String): Boolean? {
        return getPendingCompletions(context)[taskId]
    }

    // ============================================
    // 任务自动创建笔记规则
    //
    // 规则在 Flutter 端用 jsonEncode 写入：
    // [
    //   { "type": "create"|"edit"|"createAndEdit"|"none",
    //     "tag": {...} | null,
    //     "priority": 1|2|3|4 | null,   // value，与 TaskPriority 的 value 对齐
    //     "is_subtask": true | false }
    // ]
    //
    // priority value 对照（见 packages/planbook_api/.../task_priority.dart）：
    //   1 = high, 2 = medium, 3 = low, 4 = none
    //
    // 小部件端无法弹出"编辑笔记"页面，所以 edit / createAndEdit 都退化为 create。
    // ============================================

    enum class TaskAutoNoteType {
        NONE, CREATE, EDIT, CREATE_AND_EDIT;

        val shouldCreate: Boolean
            get() = this == CREATE || this == CREATE_AND_EDIT
    }

    /**
     * 根据任务的 priority（数据库里的字符串 high/medium/low/none）和 isSubtask
     * 找到匹配的自动笔记规则类型；找不到时返回 NONE。
     */
    fun getTaskAutoNoteType(
        context: Context,
        taskPriorityRaw: String?,
        isSubtask: Boolean,
    ): TaskAutoNoteType {
        val json = getPrefs(context).getString(KEY_TASK_AUTO_NOTE_RULES, null) ?: return TaskAutoNoteType.NONE
        return try {
            val arr = JSONArray(json)
            for (i in 0 until arr.length()) {
                val rule = arr.optJSONObject(i) ?: continue
                val typeName = rule.optString("type", "none")
                val matches = if (isSubtask) {
                    rule.optBoolean("is_subtask", false)
                } else {
                    val priorityValue = if (rule.isNull("priority")) null else rule.optInt("priority")
                    !rule.optBoolean("is_subtask", false) &&
                        priorityValue != null &&
                        priorityValueToRaw(priorityValue) == (taskPriorityRaw ?: "none")
                }
                if (matches) {
                    return when (typeName) {
                        "create" -> TaskAutoNoteType.CREATE
                        "edit" -> TaskAutoNoteType.EDIT
                        "createAndEdit" -> TaskAutoNoteType.CREATE_AND_EDIT
                        else -> TaskAutoNoteType.NONE
                    }
                }
            }
            TaskAutoNoteType.NONE
        } catch (_: Exception) {
            TaskAutoNoteType.NONE
        }
    }

    private fun priorityValueToRaw(value: Int): String = when (value) {
        1 -> "high"
        2 -> "medium"
        3 -> "low"
        else -> "none"
    }

    /** 获取当前主题颜色方案 */
    fun getCurrentColorScheme(context: Context): FlutterColorScheme {
        val isSystemDark = context.resources.configuration.uiMode and
                android.content.res.Configuration.UI_MODE_NIGHT_MASK ==
                android.content.res.Configuration.UI_MODE_NIGHT_YES
        val isDark = isSystemDark || isDarkMode(context)
        val json = if (isDark) getDarkColorSchemeJSON(context) else getLightColorSchemeJSON(context)
        return try {
            json?.let { AppFlutterColorSchemes.decode(it) }
                ?: if (isDark) AppFlutterColorSchemes.redDark else AppFlutterColorSchemes.redLight
        } catch (_: Exception) {
            if (isDark) AppFlutterColorSchemes.redDark else AppFlutterColorSchemes.redLight
        }
    }
}
