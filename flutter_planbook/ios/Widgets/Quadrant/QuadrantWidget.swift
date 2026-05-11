//
//  QuadrantWidgetDefinitions.swift
//  Widgets
//
//  四象限组件注册（大号 + 中号）
//

import SwiftUI
import WidgetKit

// MARK: - 大号组件

struct QuadrantWidgetLarge: Widget {
    static let kind = "QuadrantWidgetLarge"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: QuadrantConfigIntent.self,
            provider: QuadrantWidgetLargeProvider()
        ) { entry in
            QuadrantWidgetLargeView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetTiledBackground(config: WidgetBackgroundConfig.current())
                }
        }
        .contentMarginsDisabled()
        .configurationDisplayName(String(localized: "widget.large.name"))
        .description(String(localized: "widget.large.description"))
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - 中号组件

struct QuadrantWidgetSmall: Widget {
    static let kind = "QuadrantWidgetSmall"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: QuadrantConfigIntent.self,
            provider: QuadrantWidgetSmallProvider()
        ) { entry in
            QuadrantWidgetSmallView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetTiledBackground(config: WidgetBackgroundConfig.current())
                }
        }
        .contentMarginsDisabled()
        .configurationDisplayName(String(localized: "widget.medium.name"))
        .description(String(localized: "widget.medium.description"))
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Previews

#Preview(as: .systemLarge) {
    QuadrantWidgetLarge()
} timeline: {
    QuadrantEntry(
        date: .now,
        groups: [
            QuadrantGroup(priority: .high, tasks: [
                QuadrantTask(id: "1", title: "完成设计文档", priority: "high", isCompleted: false, hasAlarm: true),
                QuadrantTask(id: "2", title: "回复客户邮件", priority: "high", isCompleted: false, hasAlarm: false),
            ]),
            QuadrantGroup(priority: .medium, tasks: [
                QuadrantTask(id: "3", title: "健身计划", priority: "medium", isCompleted: false, hasAlarm: false),
                QuadrantTask(id: "3", title: "健身计划", priority: "medium", isCompleted: true, hasAlarm: false),
                QuadrantTask(id: "3", title: "健身计划", priority: "medium", isCompleted: true, hasAlarm: false),
                QuadrantTask(id: "3", title: "健身计划", priority: "medium", isCompleted: false, hasAlarm: false),
                QuadrantTask(id: "3", title: "健身计划", priority: "medium", isCompleted: false, hasAlarm: false),
                QuadrantTask(id: "3", title: "健身计划", priority: "medium", isCompleted: false, hasAlarm: false),
                QuadrantTask(id: "3", title: "健身计划", priority: "medium", isCompleted: false, hasAlarm: false),
                QuadrantTask(id: "3", title: "健身计划", priority: "medium", isCompleted: false, hasAlarm: false),
            ]),
            QuadrantGroup(priority: .low, tasks: [
                QuadrantTask(id: "4", title: "取快递", priority: "low", isCompleted: true, hasAlarm: false),
            ]),
            QuadrantGroup(priority: .none, tasks: [
                QuadrantTask(id: "1", title: "完成设计文档", priority: "high", isCompleted: false, hasAlarm: true),
                QuadrantTask(id: "2", title: "回复客户邮件", priority: "high", isCompleted: false, hasAlarm: false),
                QuadrantTask(id: "1", title: "完成设计文档", priority: "high", isCompleted: false, hasAlarm: true),
                QuadrantTask(id: "2", title: "回复客户邮件", priority: "high", isCompleted: false, hasAlarm: false),
                QuadrantTask(id: "1", title: "完成设计文档", priority: "high", isCompleted: false, hasAlarm: true),
                QuadrantTask(id: "2", title: "回复客户邮件", priority: "high", isCompleted: false, hasAlarm: false),
                QuadrantTask(id: "1", title: "完成设计文档", priority: "high", isCompleted: false, hasAlarm: true),
                QuadrantTask(id: "2", title: "回复客户邮件", priority: "high", isCompleted: false, hasAlarm: false),
            ]),
        ],
        selectedPriority: .high,
        filterMode: .today
    )
}

// #Preview(as: .systemSmall) {
//    QuadrantWidgetSmall()
// } timeline: {
//    QuadrantEntry(
//        date: .now,
//        groups: [
//            QuadrantGroup(priority: .high, tasks: [
//                QuadrantTask(id: "1", title: "完成设计文档", priority: "high", isCompleted: false, hasAlarm: true),
//                QuadrantTask(id: "2", title: "回复客户邮件", priority: "high", isCompleted: true, hasAlarm: false),
//                QuadrantTask(id: "5", title: "准备会议资料", priority: "high", isCompleted: true, hasAlarm: true),
//                QuadrantTask(id: "2", title: "回复客户邮件", priority: "high", isCompleted: false, hasAlarm: false),
//                QuadrantTask(id: "5", title: "准备会议资料", priority: "high", isCompleted: false, hasAlarm: true),
//            ]),
//            QuadrantGroup(priority: .medium, tasks: [
//                QuadrantTask(id: "3", title: "健身计划", priority: "medium", isCompleted: false, hasAlarm: false),
//            ]),
//            QuadrantGroup(priority: .low, tasks: []),
//            QuadrantGroup(priority: .none, tasks: []),
//        ],
//        selectedPriority: .high,
//        filterMode: .today
//    )
// }
