//
//  QuadrantWidgetSmallProvider.swift
//  Widgets
//
//  中号四象限组件 AppIntentTimelineProvider
//

import WidgetKit
import AppIntents

struct QuadrantWidgetSmallProvider: AppIntentTimelineProvider {
    typealias Entry = QuadrantEntry
    typealias Intent = QuadrantConfigIntent

    func placeholder(in context: Context) -> QuadrantEntry {
        QuadrantEntry(date: Date(), groups: defaultGroups(), selectedPriority: .high, filterMode: .today)
    }

    func snapshot(for configuration: QuadrantConfigIntent, in context: Context) async -> QuadrantEntry {
        QuadrantEntry(
            date: Date(),
            groups: fetchGroups(filterMode: configuration.filterMode),
            selectedPriority: currentPriority(),
            filterMode: configuration.filterMode
        )
    }

    func timeline(for configuration: QuadrantConfigIntent, in context: Context) async -> Timeline<QuadrantEntry> {
        let priority = currentPriority()
        let entry = QuadrantEntry(
            date: Date(),
            groups: fetchGroups(filterMode: configuration.filterMode),
            selectedPriority: priority,
            filterMode: configuration.filterMode
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    /// 优先从 UserDefaults 读取切换后的象限，没有则默认 high
    private func currentPriority() -> TaskPriority {
        WidgetSettings.selectedPriority
    }

    /// 中号组件只需查询当前选中优先级的任务，其他象限留空；
    /// 查到后用 `WidgetSettings` 的 pending 表覆盖 isCompleted。
    private func fetchGroups(filterMode: TaskFilterMode) -> [QuadrantGroup] {
        let selected = currentPriority()
        let priorities: [TaskPriority] = [.high, .medium, .low, .none]
        let groups: [QuadrantGroup] = priorities.map { priority in
            if priority == selected {
                let tasks = WidgetDatabase.shared.fetchTasks(
                    forPriority: priority,
                    filterMode: filterMode,
                    limit: 10
                )
                return QuadrantGroup(priority: priority, tasks: tasks)
            } else {
                return QuadrantGroup(priority: priority, tasks: [])
            }
        }
        return overlayPendingCompletions(on: groups)
    }

    private func defaultGroups() -> [QuadrantGroup] {
        TaskPriority.allCases.map { QuadrantGroup(priority: $0, tasks: []) }
    }
}
