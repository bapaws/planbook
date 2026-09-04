//
//  TimeBlockLayout.swift
//  Widgets
//
//  移植 Flutter `buildTaskTimeBlockLayoutItems`：按窗口裁剪、重叠分列。
//

import Foundation
import GRDB

/// 时间块任务（仅渲染所需列）
@available(iOS 16.0, *)
struct TimeBlockTask: Identifiable, Equatable {
    let taskId: String
    let title: String
    let priority: TaskPriority
    let startAt: Date
    let endAt: Date
    let occurrenceAt: String?
    let isCompleted: Bool

    var id: String {
        if let occurrenceAt, !occurrenceAt.isEmpty {
            return "\(taskId)#\(occurrenceAt)"
        }
        return taskId
    }

    var startMinutes: Int { TimeBlockLayout.minutesFromMidnight(startAt) }
    var endMinutes: Int { TimeBlockLayout.minutesFromMidnight(endAt) }
}

@available(iOS 16.0, *)
extension TimeBlockTask: FetchableRecord {
    init(row: Row) {
        let id: String = row["id"]
        let title: String = row["title"]
        let priority: String? = row["priority"]
        let startRaw: String? = row["start_at"]
        let endRaw: String? = row["end_at"]
        let occurrenceAt: String? = row["occurrence_at"]
        let completedAt: String? = row["completed_at"]
        let activityDeletedAt: String? = row["activity_deleted_at"]

        let start = TimeBlockLayout.parseISODate(startRaw) ?? Date()
        var end = TimeBlockLayout.parseISODate(endRaw) ?? start.addingTimeInterval(3600)
        if end <= start {
            end = start.addingTimeInterval(15 * 60)
        }

        self.taskId = id
        self.title = title
        self.priority = TaskPriority(rawValue: priority ?? "none") ?? .none
        self.startAt = start
        self.endAt = end
        self.occurrenceAt = occurrenceAt
        self.isCompleted = completedAt != nil && activityDeletedAt == nil
    }
}

@available(iOS 16.0, *)
struct TimeBlockLayoutItem: Identifiable, Equatable {
    let task: TimeBlockTask
    let top: CGFloat
    let height: CGFloat
    let startMinutes: Int
    let endMinutes: Int
    let timeRangeLabel: String
    let columnCount: Int
    let columnIndex: Int
    let widthFactor: CGFloat

    var id: String { "\(task.id)-\(startMinutes)-\(columnIndex)" }

    func withColumn(count: Int, index: Int) -> TimeBlockLayoutItem {
        TimeBlockLayoutItem(
            task: task,
            top: top,
            height: height,
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            timeRangeLabel: timeRangeLabel,
            columnCount: count,
            columnIndex: index,
            widthFactor: 1 / CGFloat(count)
        )
    }
}

@available(iOS 16.0, *)
enum TimeBlockLayout {
    static let dayMinutes = 24 * 60
    static let defaultDurationMinutes = 60
    static let appHourHeight: CGFloat = 60
    static let appMinBlockHeight: CGFloat = 24

    static func minutesFromMidnight(_ date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let minutes = Int(date.timeIntervalSince(start) / 60)
        return min(max(minutes, 0), dayMinutes)
    }

    static func parseISODate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) { return date }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        if let date = plain.date(from: raw) { return date }
        let truncated = String(raw.prefix(19)) + "Z"
        return plain.date(from: truncated)
    }

    static func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }

    static func formatHourLabel(_ hour: Int) -> String {
        String(format: "%02d:00", hour)
    }

    static func mediumWindow(nowMinutes: Int, visibleMinutes: Int = 4 * 60) -> (start: Int, end: Int) {
        let maxStart = max(0, dayMinutes - visibleMinutes)
        let start = min(max(nowMinutes - visibleMinutes / 3, 0), maxStart)
        return (start, start + visibleMinutes)
    }

    /// 窗口内需要对齐的整点（分钟落在 `[windowStart, windowEnd)`）。
    /// 中号窗口不一定从整点开始，不能按 0,1,2… 均分高度。
    static func visibleHours(windowStart: Int, windowEnd: Int) -> [Int] {
        var hours: [Int] = []
        var hour = windowStart / 60
        if hour * 60 < windowStart { hour += 1 }
        while hour * 60 < windowEnd {
            hours.append(hour)
            hour += 1
        }
        return hours
    }

    static func yOffset(minutes: Int, windowStart: Int, hourHeight: CGFloat) -> CGFloat {
        CGFloat(minutes - windowStart) / 60 * hourHeight
    }

    static func minBlockHeight(hourHeight: CGFloat) -> CGFloat {
        max(14, hourHeight * (appMinBlockHeight / appHourHeight))
    }

    /// 对应 Dart `buildTaskTimeBlockLayoutItems`，先裁剪到窗口再分列。
    static func layout(
        tasks: [TimeBlockTask],
        windowStart: Int,
        windowEnd: Int,
        hourHeight: CGFloat
    ) -> [TimeBlockLayoutItem] {
        let minHeight = minBlockHeight(hourHeight: hourHeight)
        var items: [TimeBlockLayoutItem] = []

        for task in tasks {
            var start = max(task.startMinutes, windowStart)
            var end = min(task.endMinutes, windowEnd)
            if end <= start { continue }
            if end - start < 5 { end = min(start + 15, windowEnd) }
            if end <= start { continue }

            let top = CGFloat(start - windowStart) / 60 * hourHeight
            var height = CGFloat(end - start) / 60 * hourHeight
            if height < minHeight {
                height = minHeight
            }

            let startDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(TimeInterval(start * 60))
            let endDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(TimeInterval(end * 60))
            items.append(
                TimeBlockLayoutItem(
                    task: task,
                    top: top,
                    height: height,
                    startMinutes: start,
                    endMinutes: end,
                    timeRangeLabel: formatTimeRange(start: startDate, end: endDate),
                    columnCount: 1,
                    columnIndex: 0,
                    widthFactor: 1
                )
            )
        }

        items.sort { $0.top < $1.top }

        var clusters: [[TimeBlockLayoutItem]] = []
        for item in items {
            var added = false
            for i in clusters.indices {
                if let last = clusters[i].last, item.top < last.top + last.height {
                    clusters[i].append(item)
                    added = true
                    break
                }
            }
            if !added {
                clusters.append([item])
            }
        }

        var result: [TimeBlockLayoutItem] = []
        for cluster in clusters {
            var columns: [[TimeBlockLayoutItem]] = []
            for item in cluster {
                var placed = false
                for i in columns.indices {
                    if let last = columns[i].last, item.top >= last.top + last.height - 0.001 {
                        columns[i].append(item)
                        placed = true
                        break
                    }
                }
                if !placed {
                    columns.append([item])
                }
            }
            let columnCount = columns.count
            for (columnIndex, column) in columns.enumerated() {
                for item in column {
                    result.append(item.withColumn(count: columnCount, index: columnIndex))
                }
            }
        }

        result.sort { $0.top < $1.top }
        return result
    }

    static func overlayPending(on tasks: [TimeBlockTask]) -> [TimeBlockTask] {
        let pending = WidgetSettings.allPendingCompletions()
        if pending.isEmpty { return tasks }
        return tasks.map { task in
            guard let target = pending[task.taskId], target != task.isCompleted else {
                return task
            }
            return TimeBlockTask(
                taskId: task.taskId,
                title: task.title,
                priority: task.priority,
                startAt: task.startAt,
                endAt: task.endAt,
                occurrenceAt: task.occurrenceAt,
                isCompleted: target
            )
        }
    }
}
