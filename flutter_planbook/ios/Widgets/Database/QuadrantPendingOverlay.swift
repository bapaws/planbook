//
//  QuadrantPendingOverlay.swift
//  Widgets
//
//  把 `WidgetSettings` 中保存的 pending 完成状态覆盖到从 DB 查到的任务上，
//  让 widget AppIntent 翻转后即使 Flutter 还没把 DB / Supabase 写完，
//  UI 也能立刻反馈。
//

import Foundation

/// 应用 pending 覆盖：对每个 task，pending 表里有就用 pending 的值替换 isCompleted。
@available(iOS 16.0, *)
func overlayPendingCompletions(on groups: [QuadrantGroup]) -> [QuadrantGroup] {
    let pending = WidgetSettings.allPendingCompletions()
    if pending.isEmpty { return groups }

    return groups.map { group in
        let overlaid = group.tasks.map { task -> QuadrantTask in
            guard let target = pending[task.id], target != task.isCompleted else {
                return task
            }
            return QuadrantTask(
                id: task.id,
                title: task.title,
                priority: task.priority.rawValue,
                isCompleted: target,
                hasAlarm: task.hasAlarm,
                tagNames: task.tagNames
            )
        }
        return QuadrantGroup(priority: group.priority, tasks: overlaid)
    }
}
