//
//  WeekListWidget.swift
//  Widgets
//

import AppIntents
import SwiftUI
import WidgetKit

struct WeekListEntry: TimelineEntry {
    let date: Date
    let days: [Date]
    let tasksByDay: [String: [WeekTask]]
    let completedCount: Int
    let totalCount: Int
}

struct WeekListProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeekListEntry {
        makeEntry(at: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekListEntry) -> Void) {
        completion(makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekListEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(at: now)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry(at date: Date) -> WeekListEntry {
        let start = WeekCalendar.startOfWeek(for: date)
        let days = WeekCalendar.days(from: start, count: 7)
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? date
        let tasks = WeekCalendar.overlayPending(
            on: WidgetDatabase.shared.fetchWeekTasks(startDate: start, endDate: end)
        )
        let grouped = WeekCalendar.groupTasks(tasks, days: days)
        let progress = WeekCalendar.progress(tasks: tasks)
        return WeekListEntry(
            date: date,
            days: days,
            tasksByDay: grouped,
            completedCount: progress.completed,
            totalCount: progress.total
        )
    }
}

struct WeekListWidgetLarge: Widget {
    static let kind = kWeekListWidgetLargeKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: WeekListProvider()) { entry in
            WeekListView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetTiledBackground(config: WidgetBackgroundConfig.current())
                }
        }
        .contentMarginsDisabled()
        .configurationDisplayName(String(localized: "widget.weekList.large.name"))
        .description(String(localized: "widget.weekList.large.description"))
        .supportedFamilies([.systemLarge])
    }
}

struct WeekListView: View {
    var entry: WeekListEntry
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
            VStack(spacing: 4) {
                ForEach(entry.days, id: \.timeIntervalSince1970) { day in
                    weekRow(day: day)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(10)
        .widgetURL(weekTabURL(view: "list"))
    }

    private func weekRow(day: Date) -> some View {
        let key = WeekCalendar.dayKey(day)
        let tasks = entry.tasksByDay[key] ?? []
        let visible = Array(tasks.prefix(4))
        let extra = tasks.count - visible.count
        let theme = WeekCalendar.weekdayColorScheme(for: day, isDark: isDark)
        let isToday = WeekCalendar.isSameDay(day, Date())

        return HStack(alignment: .top, spacing: 6) {
            Link(destination: weekDayURL(day)) {
                VStack(spacing: 2) {
                    Text(WeekCalendar.shortWeekday(day))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isToday ? theme.onPrimaryColor : theme.primaryColor)
                    Text(WeekCalendar.dayNumber(day))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isToday ? theme.onPrimaryColor.opacity(0.9) : theme.outlineColor)
                }
                .frame(width: 40)
                .padding(.vertical, 4)
                .background(
                    isToday ? theme.primaryColor : theme.primaryContainerColor,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(stride(from: 0, to: visible.count, by: 2).enumerated()), id: \.offset) { _, start in
                    HStack(spacing: 4) {
                        WeekCompleteRow(
                            task: visible[start],
                            theme: visible[start].priority.getColorScheme(isDarkMode: isDark)
                        )
                        if start + 1 < visible.count {
                            WeekCompleteRow(
                                task: visible[start + 1],
                                theme: visible[start + 1].priority.getColorScheme(isDarkMode: isDark)
                            )
                        } else {
                            Spacer(minLength: 0)
                        }
                    }
                }
                if extra > 0 {
                    Text("+\(extra)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Colors.outlineColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct WeekCompleteRow: View {
    let task: WeekTask
    let theme: FlutterColorScheme

    var body: some View {
        Button(
            intent: CompleteTaskIntent(taskId: task.taskId, occurrenceAt: task.occurrenceAt)
        ) {
            HStack(spacing: 3) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(task.isCompleted ? theme.outlineColor : theme.primaryColor)
                Text(task.title)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(task.isCompleted ? theme.outlineColor : theme.onSurfaceVariantColor)
                    .strikethrough(task.isCompleted)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
