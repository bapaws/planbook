//
//  WidgetSettings.swift
//  Widgets
//
//  Widget 配置统一管理
//  所有通过 UserDefaults (App Group) 持久化的配置项，统一封装为类型安全的计算属性
//

import Foundation

@available(iOS 16.0, *)
enum WidgetSettings {
    private static var defaults: UserDefaults { .appGroup }

    // MARK: - Keys

    private enum Keys {
        static let selectedPriority = "widget_quadrant_selected_priority"
        static let backgroundAsset = "widget_background_asset"
        static let widgetTheme = "widget_theme"
        static let lightColorScheme = "__settings_light_color_scheme_key__"
        static let darkColorScheme = "__settings_dark_color_scheme_key__"
        /// 四象限自定义配置（名称），Flutter 端通过 home_widget 写入，
        /// 与 `SettingsRepository.kSettingsQuadrantConfigs` 保持一致。
        static let quadrantConfigs = "widget_quadrant_configs"
        /// pending 完成状态：widget AppIntent 翻转后写入这里，UI 立刻反馈；
        /// Flutter 端真正改完 DB 后会通过 MethodChannel 清除这一项。
        /// 字典格式：[taskId: completed]。
        static let pendingCompletionStates = "widget_pending_completion_states"
        /// 当前登录用户 ID。Flutter 端登录 / 注销时通过 home_widget 写入 / 清除，
        /// 必须与 `packages/planbook_repository/lib/users/users_repository.dart` 中
        /// 的 `kUserId` 常量保持一致。
        static let currentUserId = "__supabase_user_id__"
        /// 会员状态。Flutter 端通过 home_widget 写入；缺省视为非会员。
        static let isPremium = "widget_is_premium"
    }

    // MARK: - 象限优先级

    /// 当前选中的象限优先级（中号组件切换）
    static var selectedPriority: TaskPriority {
        get {
            guard let rawValue = defaults.string(forKey: Keys.selectedPriority),
                  let priority = TaskPriority(rawValue: rawValue) else {
                return .high
            }
            return priority
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.selectedPriority)
        }
    }

    // MARK: - 背景

    /// 背景资源名称（Flutter 同步写入）
    static var backgroundAsset: String {
        defaults.string(forKey: Keys.backgroundAsset) ?? "bg_dot"
    }

    /// 是否为深色模式（从 widget_theme 解析）
    static var isDarkMode: Bool {
        guard let themeJson = defaults.string(forKey: Keys.widgetTheme),
              let data = themeJson.data(using: .utf8),
              let theme = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        return theme["isDarkMode"] as? Bool ?? false
    }

    // MARK: - 四象限自定义配置

    /// 四象限自定义名称（仅包含非空名称）
    static var quadrantConfigs: [String: String] {
        guard let json = defaults.string(forKey: Keys.quadrantConfigs),
              let data = json.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return [:]
        }
        var result: [String: String] = [:]
        for item in array {
            guard let priority = item["priority"] as? String,
                  let name = item["name"] as? String,
                  !name.isEmpty else { continue }
            result[priority] = name
        }
        return result
    }

    /// 读取某个象限的自定义名称；未配置或为空时返回 nil
    static func customQuadrantName(for priority: TaskPriority) -> String? {
        quadrantConfigs[priority.rawValue]
    }

    // MARK: - 主题颜色

    /// 亮色主题颜色方案 JSON
    static var lightColorSchemeJSON: String? {
        defaults.string(forKey: Keys.lightColorScheme)
    }

    /// 暗色主题颜色方案 JSON
    static var darkColorSchemeJSON: String? {
        defaults.string(forKey: Keys.darkColorScheme)
    }

    // MARK: - Pending 完成状态（Widget 乐观 UI）
    //
    // 工作流：
    //   1. 用户在 widget 上勾选任务 → `CompleteTaskIntent` 把翻转后的目标状态
    //      写到 `pendingCompletionStates[taskId]` 并 reload timeline。
    //   2. Provider 在拼装 entry 时把 pending 覆盖到 DB 查到的 `isCompleted`，
    //      让 widget UI 立刻反馈（哪怕主 App 还没启动）。
    //   3. AppIntent 链到主 App 跑 Flutter 完整业务，DB / Supabase 写完后
    //      Flutter 通过 MethodChannel 调过来清除该 taskId 的 pending，
    //      之后 widget 重新刷新就读到权威 DB 状态，pending 不再生效。
    //
    // 注意：写 DB 的责任完全在 Flutter 端，widget 进程不再直接改 DB。

    /// 取出当前所有 pending 状态。值为 `[taskId: completed]`。
    static func allPendingCompletions() -> [String: Bool] {
        guard let raw = defaults.dictionary(forKey: Keys.pendingCompletionStates) else {
            return [:]
        }
        var result: [String: Bool] = [:]
        for (key, value) in raw {
            if let bool = value as? Bool {
                result[key] = bool
            }
        }
        return result
    }

    /// 读取单个任务的 pending 状态；不存在返回 nil。
    static func pendingCompletion(forTaskId taskId: String) -> Bool? {
        guard let dict = defaults.dictionary(forKey: Keys.pendingCompletionStates),
              let value = dict[taskId] as? Bool else {
            return nil
        }
        return value
    }

    /// 写入或更新某个任务的 pending 状态。
    static func setPendingCompletion(taskId: String, completed: Bool) {
        var dict = defaults.dictionary(forKey: Keys.pendingCompletionStates) ?? [:]
        dict[taskId] = completed
        defaults.set(dict, forKey: Keys.pendingCompletionStates)
    }

    /// 清除某个任务的 pending 状态（Flutter 端 DB 写完后调用）。
    static func clearPendingCompletion(forTaskId taskId: String) {
        var dict = defaults.dictionary(forKey: Keys.pendingCompletionStates) ?? [:]
        guard dict.removeValue(forKey: taskId) != nil else { return }
        if dict.isEmpty {
            defaults.removeObject(forKey: Keys.pendingCompletionStates)
        } else {
            defaults.set(dict, forKey: Keys.pendingCompletionStates)
        }
    }

    // MARK: - 当前登录用户

    /// 当前登录的 Supabase 用户 ID，未登录或值为空时返回 nil。
    ///
    /// widget 进程需要据此把 SQL 过滤拼成 `tasks.user_id IS NULL`（未登录）或
    /// `tasks.user_id = ?`（已登录），与 Flutter 端 DatabaseTaskTodayApi /
    /// InboxApi / OverdueApi 的查询语义对齐，避免切换账号后看到上一个用户的数据。
    static var currentUserId: String? {
        let raw = defaults.string(forKey: Keys.currentUserId)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let raw, !raw.isEmpty else { return nil }
        return raw
    }

    // MARK: - 会员

    /// 时间块小组件是否按会员渲染。从未写入时视为非会员，避免泄露日程。
    ///
    /// Flutter `home_widget` 经 StandardMessageCodec 写入的 Bool 在
    /// UserDefaults 里是 `NSNumber`，`as? Bool` 会失败，必须用 `bool(forKey:)`。
    static var isPremium: Bool {
        defaults.bool(forKey: Keys.isPremium)
    }
}
