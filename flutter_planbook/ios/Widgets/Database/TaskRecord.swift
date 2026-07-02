//
//  TaskRecord.swift
//  Widgets
//
//  仅包含 Widget 渲染所需的必要列，减少内存占用
//

import AppIntents
import Foundation
import GRDB
import SQLite3
import SwiftUI

/// 任务优先级（对应 Flutter TaskPriority）
@available(iOS 16.0, *)
enum TaskPriority: String, CaseIterable, AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "config.parameter.priority"

    static var caseDisplayRepresentations: [TaskPriority: DisplayRepresentation] = [
        .high: "quadrant.high",
        .medium: "quadrant.medium",
        .low: "quadrant.low",
        .none: "quadrant.none",
    ]

    case high
    case medium
    case low
    case none

    /// 四象限标题（从 Localizable.xcstrings 读取）
    var quadrantTitle: String {
        switch self {
        case .high:
            String(localized: "quadrant.high")
        case .medium:
            String(localized: "quadrant.medium")
        case .low:
            String(localized: "quadrant.low")
        case .none:
            String(localized: "quadrant.none")
        }
    }

    /// 最终展示的象限名称（用户自定义优先，回退本地化）
    var displayTitle: String {
        WidgetSettings.customQuadrantName(for: self) ?? quadrantTitle
    }

    /// 当前主题下的优先级主色（对应 Flutter ColorScheme.primary）
    func color(for isDarkMode: Bool) -> Color {
        getColorScheme(isDarkMode: isDarkMode).primaryColor
    }

    var isImportant: Bool {
        switch self {
        case .high, .medium: return true
        case .low, .none: return false
        }
    }

    var isUrgent: Bool {
        switch self {
        case .high, .low: return true
        case .medium, .none: return false
        }
    }

    var index: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        case .none: return 3
        }
    }

    /// 获取优先级对应的 Flutter ColorScheme
    /// 与 Flutter `TaskPriority.getColorScheme()` 保持一致：
    /// high → red, medium → blue, low → amber, none → lightGreen
    func getColorScheme(isDarkMode: Bool) -> FlutterColorScheme {
        switch (self, isDarkMode) {
        case (.high, true): return AppFlutterColorSchemes.redDark
        case (.high, false): return AppFlutterColorSchemes.redLight
        case (.medium, true): return AppFlutterColorSchemes.blueDark
        case (.medium, false): return AppFlutterColorSchemes.blueLight
        case (.low, true): return AppFlutterColorSchemes.amberDark
        case (.low, false): return AppFlutterColorSchemes.amberLight
        case (.none, true): return AppFlutterColorSchemes.lightGreenDark
        case (.none, false): return AppFlutterColorSchemes.lightGreenLight
        }
    }
}

/// 四象限任务记录（仅必要列）
@available(iOS 16.0, *)
struct QuadrantTask: Identifiable {
    let id: String
    let title: String
    let priority: TaskPriority
    let isCompleted: Bool
    let hasAlarm: Bool
    let tagNames: [String]

    init(id: String, title: String, priority: String?, isCompleted: Bool, hasAlarm: Bool, tagNames: [String] = []) {
        self.id = id
        self.title = title
        self.priority = TaskPriority(rawValue: priority ?? "none") ?? .none
        self.isCompleted = isCompleted
        self.hasAlarm = hasAlarm
        self.tagNames = tagNames
    }
}

/// 任务过滤模式（对应 Flutter 的任务视图类型）
@available(iOS 16.0, *)
enum TaskFilterMode: String, CaseIterable, AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "config.parameter.filterMode"

    static var caseDisplayRepresentations: [TaskFilterMode: DisplayRepresentation] = [
        .today: "filter.mode.today",
        .inbox: "filter.mode.inbox",
        .overdue: "filter.mode.overdue",
    ]

    case today
    case inbox
    case overdue

    var title: String {
        switch self {
        case .today: return String(localized: "filter.mode.today")
        case .inbox: return String(localized: "filter.mode.inbox")
        case .overdue: return String(localized: "filter.mode.overdue")
        }
    }
}

/// 按象限分组的结果
@available(iOS 16.0, *)
struct QuadrantGroup: Identifiable {
    let id = UUID()
    let priority: TaskPriority
    var tasks: [QuadrantTask]

    var title: String { priority.displayTitle }
    func color(for isDarkMode: Bool) -> Color {
        priority.color(for: isDarkMode)
    }
}

// MARK: - GRDB FetchableRecord

@available(iOS 16.0, *)
extension QuadrantTask: FetchableRecord {
    init(row: Row) {
        let id: String = row["id"]
        let title: String = row["title"]
        let priority: String? = row["priority"]
        let completedAt: String? = row["completed_at"]
        let activityDeletedAt: String? = row["activity_deleted_at"]
        let alarms: String? = row["alarms"]

        let isCompleted = completedAt != nil && activityDeletedAt == nil
        let hasAlarm = alarms != nil && !alarms!.isEmpty

        self.init(
            id: id,
            title: title,
            priority: priority,
            isCompleted: isCompleted,
            hasAlarm: hasAlarm,
            tagNames: []
        )
    }
}
