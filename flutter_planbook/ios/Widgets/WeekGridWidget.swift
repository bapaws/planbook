//
//  WeekGridWidget.swift
//  Widgets
//

import SwiftUI
import WidgetKit

struct WeekGridEntry: TimelineEntry {
    let date: Date
    let days: [Date]
    let tasksByDay: [String: [WeekTask]]
    let weeklyFocus: String?
    let completedCount: Int
    let totalCount: Int
}

struct WeekGridProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeekGridEntry {
        makeEntry(at: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekGridEntry) -> Void) {
        completion(makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekGridEntry>) -> Void) {
        let now = Date()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(15 * 60)
        completion(Timeline(entries: [makeEntry(at: now)], policy: .after(next)))
    }

    private func makeEntry(at date: Date) -> WeekGridEntry {
        let start = WeekCalendar.startOfWeek(for: date)
        let days = WeekCalendar.days(from: start, count: 7)
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? date
        let tasks = WeekCalendar.overlayPending(
            on: WidgetDatabase.shared.fetchWeekTasks(startDate: start, endDate: end)
        )
        let progress = WeekCalendar.progress(tasks: tasks)
        return WeekGridEntry(
            date: date,
            days: days,
            tasksByDay: WeekCalendar.groupTasks(tasks, days: days),
            weeklyFocus: WidgetDatabase.shared.fetchWeeklyFocus(startDate: start),
            completedCount: progress.completed,
            totalCount: progress.total
        )
    }
}

struct WeekGridWidgetLarge: Widget {
    static let kind = kWeekGridWidgetLargeKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: WeekGridProvider()) { entry in
            WeekGridView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetTiledBackground(config: WidgetBackgroundConfig.current())
                }
        }
        .contentMarginsDisabled()
        .configurationDisplayName(String(localized: "widget.weekGrid.large.name"))
        .description(String(localized: "widget.weekGrid.large.description"))
        .supportedFamilies([.systemLarge])
    }
}

struct WeekGridView: View {
    var entry: WeekGridEntry
    private let isDark = WidgetBackgroundConfig.current().isDarkMode

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WeekWidgetHeader(
                title: String(localized: "widget.week.title"),
                progressText: entry.totalCount == 0 ? nil : "\(entry.completedCount)/\(entry.totalCount)",
                emptyText: String(localized: "widget.week.empty"),
                capsuleText: WeekCalendar.weekRangeLabel(from: entry.days[0], dayCount: 7),
                showEmpty: entry.totalCount == 0
            )
            VStack(spacing: 1) {
                HStack(spacing: 1) {
                    focusCell
                    dayCell(entry.days[0])
                }
                HStack(spacing: 1) {
                    dayCell(entry.days[1])
                    dayCell(entry.days[2])
                }
                HStack(spacing: 1) {
                    dayCell(entry.days[3])
                    dayCell(entry.days[4])
                }
                HStack(spacing: 1) {
                    dayCell(entry.days[5])
                    dayCell(entry.days[6])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(10)
        .widgetURL(weekTabURL(view: "grid"))
    }

    private var focusCell: some View {
        let lines = focusLines
        return Link(destination: weekTabURL(view: "grid")) {
            VStack(alignment: .leading, spacing: 2) {
                cellHeader(
                    title: String(localized: "widget.week.focus"),
                    count: lines.count,
                    theme: AppFlutterColorSchemes.light,
                    isToday: false,
                    useAppTheme: true
                )
                if lines.isEmpty {
                    Text(String(localized: "widget.week.focusEmpty"))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Colors.outlineColor)
                        .lineLimit(3)
                } else {
                    ForEach(Array(lines.prefix(3).enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Colors.onSurfaceColor)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .buttonStyle(.plain)
    }

    private var focusLines: [String] {
        guard let content = entry.weeklyFocus, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        return content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func dayCell(_ day: Date) -> some View {
        let key = WeekCalendar.dayKey(day)
        let tasks = entry.tasksByDay[key] ?? []
        let visible = Array(tasks.prefix(3))
        let theme = WeekCalendar.weekdayColorScheme(for: day, isDark: isDark)
        let isToday = WeekCalendar.isSameDay(day, Date())
        return VStack(alignment: .leading, spacing: 2) {
            Link(destination: weekDayURL(day)) {
                cellHeader(
                    title: "\(WeekCalendar.shortWeekday(day)) \(WeekCalendar.dayNumber(day))",
                    count: tasks.count,
                    theme: theme,
                    isToday: isToday,
                    useAppTheme: false
                )
            }
            .buttonStyle(.plain)
            ForEach(visible) { task in
                WeekCompleteRow(task: task, theme: task.priority.getColorScheme(isDarkMode: isDark))
            }
            Spacer(minLength: 0)
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func cellHeader(
        title: String,
        count: Int,
        theme: FlutterColorScheme,
        isToday: Bool,
        useAppTheme: Bool
    ) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isToday ? theme.onPrimaryColor : (useAppTheme ? Colors.onPrimaryContainerColor : theme.onPrimaryContainerColor))
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    isToday
                        ? theme.primaryColor
                        : (useAppTheme ? Colors.primaryContainerColor : theme.primaryContainerColor),
                    in: Capsule(style: .continuous)
                )
            Spacer(minLength: 0)
            Text("\(count)")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Colors.outlineColor)
        }
    }
}
