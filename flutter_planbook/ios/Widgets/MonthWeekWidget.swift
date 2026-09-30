//
//  MonthWeekWidget.swift
//  Widgets
//

import SwiftUI
import WidgetKit

struct MonthWeekEntry: TimelineEntry {
    let date: Date
    let days: [Date]
    let tasksByDay: [String: [WeekTask]]
    let completedCount: Int
    let totalCount: Int
    let isTwoWeeks: Bool
}

struct MonthWeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthWeekEntry {
        makeEntry(at: Date(), dayCount: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthWeekEntry) -> Void) {
        completion(makeEntry(at: Date(), dayCount: context.family == .systemLarge ? 14 : 7))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthWeekEntry>) -> Void) {
        let now = Date()
        let dayCount = context.family == .systemLarge ? 14 : 7
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(15 * 60)
        completion(Timeline(entries: [makeEntry(at: now, dayCount: dayCount)], policy: .after(next)))
    }

    private func makeEntry(at date: Date, dayCount: Int) -> MonthWeekEntry {
        let start = WeekCalendar.startOfWeek(for: date)
        let days = WeekCalendar.days(from: start, count: dayCount)
        let end = Calendar.current.date(byAdding: .day, value: dayCount, to: start) ?? date
        let tasks = WeekCalendar.overlayPending(
            on: WidgetDatabase.shared.fetchWeekTasks(startDate: start, endDate: end)
        )
        let progress = WeekCalendar.progress(tasks: tasks)
        return MonthWeekEntry(
            date: date,
            days: days,
            tasksByDay: WeekCalendar.groupTasks(tasks, days: days),
            completedCount: progress.completed,
            totalCount: progress.total,
            isTwoWeeks: dayCount > 7
        )
    }
}

struct MonthWeekWidgetMedium: Widget {
    static let kind = kMonthWeekWidgetMediumKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: MonthWeekProvider()) { entry in
            MonthWeekView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetTiledBackground(config: WidgetBackgroundConfig.current())
                }
        }
        .contentMarginsDisabled()
        .configurationDisplayName(String(localized: "widget.monthWeek.medium.name"))
        .description(String(localized: "widget.monthWeek.medium.description"))
        .supportedFamilies([.systemMedium])
    }
}

struct MonthWeekWidgetLarge: Widget {
    static let kind = kMonthWeekWidgetLargeKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: MonthWeekProvider()) { entry in
            MonthWeekView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetTiledBackground(config: WidgetBackgroundConfig.current())
                }
        }
        .contentMarginsDisabled()
        .configurationDisplayName(String(localized: "widget.monthWeek.large.name"))
        .description(String(localized: "widget.monthWeek.large.description"))
        .supportedFamilies([.systemLarge])
    }
}

struct MonthWeekView: View {
    var entry: MonthWeekEntry
    private let isDark = WidgetBackgroundConfig.current().isDarkMode

    var body: some View {
        let weeks = stride(from: 0, to: entry.days.count, by: 7).map { start in
            Array(entry.days[start ..< min(start + 7, entry.days.count)])
        }
        return VStack(alignment: .leading, spacing: 4) {
            WeekWidgetHeader(
                title: String(localized: entry.isTwoWeeks ? "widget.week.twoWeeks" : "widget.week.title"),
                progressText: entry.totalCount == 0 ? nil : "\(entry.completedCount)/\(entry.totalCount)",
                emptyText: String(localized: "widget.week.empty"),
                capsuleText: WeekCalendar.weekRangeLabel(
                    from: entry.days[0],
                    dayCount: entry.days.count
                ),
                showEmpty: entry.totalCount == 0
            )
            weekdayHeader(weeks.first ?? [])
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(alignment: .top, spacing: 2) {
                    ForEach(week, id: \.timeIntervalSince1970) { day in
                        monthDayColumn(day)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .padding(10)
        .widgetURL(weekTabURL(view: "list"))
    }

    private func weekdayHeader(_ week: [Date]) -> some View {
        HStack(spacing: 2) {
            ForEach(week, id: \.timeIntervalSince1970) { day in
                Text(WeekCalendar.shortWeekday(day))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Colors.outlineColor)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func monthDayColumn(_ day: Date) -> some View {
        let key = WeekCalendar.dayKey(day)
        let tasks = entry.tasksByDay[key] ?? []
        let visible = Array(tasks.prefix(3))
        let extra = tasks.count - visible.count
        let isToday = WeekCalendar.isSameDay(day, Date())
        return Link(destination: weekDayURL(day)) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text(WeekCalendar.dayNumber(day))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isToday ? Colors.onPrimaryColor : Colors.onSurfaceColor)
                        .frame(width: 16, height: 16)
                        .background(
                            isToday ? Colors.primaryColor : Color.clear,
                            in: Circle()
                        )
                    Spacer(minLength: 0)
                }
                ForEach(visible) { task in
                    let theme = task.priority.getColorScheme(isDarkMode: isDark)
                    HStack(spacing: 2) {
                        Circle()
                            .stroke(theme.primaryColor, lineWidth: 1)
                            .frame(width: 6, height: 6)
                        Text(task.title)
                            .font(.system(size: 8, weight: .regular))
                            .foregroundStyle(task.isCompleted ? theme.outlineColor : Colors.onSurfaceColor)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 2)
                    .frame(maxWidth: .infinity, minHeight: 12, alignment: .leading)
                    .background(
                        task.isCompleted ? theme.surfaceContainerColor : theme.primaryContainerColor,
                        in: RoundedRectangle(cornerRadius: 2, style: .continuous)
                    )
                }
                if extra > 0 {
                    Text("+\(extra)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Colors.outlineColor)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .buttonStyle(.plain)
    }
}
