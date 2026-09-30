//
//  WeekModels.swift
//  Widgets
//
//  一周任务小组件的数据、日历与顶栏。
//

import SwiftUI
import WidgetKit

private let kCreateTaskURL = URL(string: "planbook.bapaws://task/new?dueAt=today")!

@available(iOS 16.0, *)
enum WeekCalendar {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func startOfWeek(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    static func days(from start: Date, count: Int, calendar: Calendar = .current) -> [Date] {
        (0 ..< count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        dayFormatter.string(from: calendar.startOfDay(for: date))
    }

    static func weekdayColorScheme(for date: Date, isDark: Bool) -> FlutterColorScheme {
        switch calendarWeekday(date) {
        case 2: isDark ? AppFlutterColorSchemes.greyDark : AppFlutterColorSchemes.greyLight
        case 3: isDark ? AppFlutterColorSchemes.indigoDark : AppFlutterColorSchemes.indigoLight
        case 4: isDark ? AppFlutterColorSchemes.pinkDark : AppFlutterColorSchemes.pinkLight
        case 5: isDark ? AppFlutterColorSchemes.purpleDark : AppFlutterColorSchemes.purpleLight
        case 6: isDark ? AppFlutterColorSchemes.blueDark : AppFlutterColorSchemes.blueLight
        case 7: isDark ? AppFlutterColorSchemes.redDark : AppFlutterColorSchemes.redLight
        default: isDark ? AppFlutterColorSchemes.amberDark : AppFlutterColorSchemes.amberLight
        }
    }

    /// Calendar: 1=Sunday … 7=Saturday
    static func calendarWeekday(_ date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.weekday, from: date)
    }

    static func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }

    static func dayNumber(_ date: Date, calendar: Calendar = .current) -> String {
        String(calendar.component(.day, from: date))
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func weekRangeLabel(from start: Date, dayCount: Int, calendar: Calendar = .current) -> String {
        let days = days(from: start, count: dayCount, calendar: calendar)
        guard let first = days.first, let last = days.last else { return "" }
        if dayCount > 7 {
            let firstWeek = calendar.component(.weekOfYear, from: first)
            let lastWeek = calendar.component(.weekOfYear, from: last)
            return String(format: String(localized: "widget.week.weeksCapsule"), firstWeek, lastWeek)
        }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMMd")
        let startText = formatter.string(from: first)
        formatter.setLocalizedDateFormatFromTemplate("d")
        let endText = formatter.string(from: last)
        return "\(startText)–\(endText)"
    }

    static func groupTasks(_ tasks: [WeekTask], days: [Date], calendar: Calendar = .current) -> [String: [WeekTask]] {
        var grouped: [String: [WeekTask]] = [:]
        for day in days {
            grouped[dayKey(day, calendar: calendar)] = []
        }
        for task in tasks {
            for key in dayKeys(for: task, days: days, calendar: calendar) {
                grouped[key, default: []].append(task)
            }
        }
        return grouped
    }

    static func overlayPending(on tasks: [WeekTask]) -> [WeekTask] {
        let pending = WidgetSettings.allPendingCompletions()
        if pending.isEmpty { return tasks }
        return tasks.map { task in
            guard let target = pending[task.taskId], target != task.isCompleted else {
                return task
            }
            return task.overlayCompleted(target)
        }
    }

    static func progress(tasks: [WeekTask]) -> (completed: Int, total: Int) {
        var seen = Set<String>()
        var unique: [WeekTask] = []
        for task in tasks where seen.insert(task.id).inserted {
            unique.append(task)
        }
        let completed = unique.filter(\.isCompleted).count
        return (completed, unique.count)
    }

    private static func dayKeys(for task: WeekTask, days: [Date], calendar: Calendar) -> [String] {
        let rangeKeys = Set(days.map { dayKey($0, calendar: calendar) })
        if let dueAt = task.dueAt {
            let key = dayKey(dueAt, calendar: calendar)
            return rangeKeys.contains(key) ? [key] : []
        }
        if let startAt = task.startAt, let endAt = task.endAt {
            return days.compactMap { day in
                let start = calendar.startOfDay(for: day)
                guard let next = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
                if startAt < next && endAt >= start {
                    return dayKey(day, calendar: calendar)
                }
                return nil
            }
        }
        if let startAt = task.startAt {
            let key = dayKey(startAt, calendar: calendar)
            return rangeKeys.contains(key) ? [key] : []
        }
        if let occurrenceAt = task.occurrenceAt, let date = TimeBlockLayout.parseISODate(occurrenceAt) {
            let key = dayKey(date, calendar: calendar)
            return rangeKeys.contains(key) ? [key] : []
        }
        return []
    }
}

@available(iOS 16.0, *)
struct WeekWidgetHeader: View {
    let title: String
    let progressText: String?
    let emptyText: String?
    let capsuleText: String
    let showEmpty: Bool

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Colors.primaryColor)
                    .frame(width: 3, height: 14)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Colors.onSurfaceColor)
                if showEmpty, let emptyText {
                    Text(emptyText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Colors.outlineColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                } else if let progressText {
                    Text(progressText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Colors.outlineColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 4)
            Text(capsuleText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Colors.outlineColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Colors.surfaceContainerHighestColor.opacity(0.72),
                    in: Capsule(style: .continuous)
                )
            Link(destination: kCreateTaskURL) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Colors.primaryColor)
                    .frame(width: 20, height: 20)
                    .background(
                        Colors.primaryContainerColor.opacity(0.88),
                        in: Circle()
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "widget.task.new"))
        }
        .frame(height: 22, alignment: .center)
    }
}

func weekDayURL(_ date: Date) -> URL {
    var components = URLComponents()
    components.scheme = "planbook.bapaws"
    components.host = "task"
    components.path = "/today"
    components.queryItems = [
        URLQueryItem(name: "date", value: WeekCalendar.dayKey(date)),
    ]
    return components.url ?? URL(string: "planbook.bapaws://task/today")!
}

func weekTabURL(view: String) -> URL {
    URL(string: "planbook.bapaws://task/week?view=\(view)")!
}
