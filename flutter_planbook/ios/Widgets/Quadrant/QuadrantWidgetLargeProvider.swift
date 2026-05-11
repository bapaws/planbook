//
//  QuadrantWidgetLargeProvider.swift
//  Widgets
//
//  大号四象限组件 AppIntentTimelineProvider
//

import WidgetKit
import AppIntents

struct QuadrantWidgetLargeProvider: AppIntentTimelineProvider {
    typealias Entry = QuadrantEntry
    typealias Intent = QuadrantConfigIntent

    func placeholder(in context: Context) -> QuadrantEntry {
        QuadrantEntry(date: Date(), groups: defaultGroups(), selectedPriority: .high, filterMode: .today)
    }

    func snapshot(for configuration: QuadrantConfigIntent, in context: Context) async -> QuadrantEntry {
        QuadrantEntry(date: Date(), groups: fetchGroups(filterMode: configuration.filterMode), selectedPriority: .high, filterMode: configuration.filterMode)
    }

    func timeline(for configuration: QuadrantConfigIntent, in context: Context) async -> Timeline<QuadrantEntry> {
        let entry = QuadrantEntry(
            date: Date(),
            groups: fetchGroups(filterMode: configuration.filterMode),
            selectedPriority: .high,
            filterMode: configuration.filterMode
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    /// 大号组件分别查询 4 个优先级，每个最多 10 条；
    /// 查到后用 `WidgetSettings` 的 pending 表覆盖 isCompleted，
    /// 保证 widget 上的勾选状态在 Flutter 写完 DB 之前也能即时反馈。
    private func fetchGroups(filterMode: TaskFilterMode) -> [QuadrantGroup] {
        let groups = WidgetDatabase.shared.fetchQuadrantTasks(filterMode: filterMode)
        return overlayPendingCompletions(on: groups)
    }

    private func defaultGroups() -> [QuadrantGroup] {
        TaskPriority.allCases.map { priority in
            QuadrantGroup(
                priority: priority,
                tasks: [
                    QuadrantTask(id: "1", title: "Task", priority: priority.rawValue, isCompleted: false, hasAlarm: true)
                ]
            )
        }
    }
}
