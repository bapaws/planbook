//
//  QuadrantEntry.swift
//  Widgets
//
//  四象限组件 TimelineEntry
//

import WidgetKit

struct QuadrantEntry: TimelineEntry {
    let date: Date
    let groups: [QuadrantGroup]
    let selectedPriority: TaskPriority // 中号组件使用
    let filterMode: TaskFilterMode
}

extension QuadrantEntry {
    /// 生成创建任务的 deep link URL
    func taskNewURL(priority: TaskPriority) -> URL {
        var components = URLComponents()
        components.scheme = "planbook.bapaws"
        components.host = "task"
        components.path = "/new"

        var queryItems = [URLQueryItem(name: "priority", value: priority.rawValue)]

        switch filterMode {
        case .today:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            queryItems.append(URLQueryItem(name: "dueAt", value: formatter.string(from: date)))
        case .overdue, .inbox:
            break
        }

        components.queryItems = queryItems
        return components.url!
    }
}
