//
//  TimeBlockProvider.swift
//  Widgets
//

import WidgetKit

@available(iOS 16.0, *)
struct TimeBlockProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimeBlockEntry {
        TimeBlockEntry(
            date: Date(),
            isPremium: true,
            tasks: [],
            nowMinutes: TimeBlockLayout.minutesFromMidnight(Date())
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeBlockEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeBlockEntry>) -> Void) {
        let now = Date()
        var entries: [TimeBlockEntry] = [makeEntry(at: now)]

        let calendar = Calendar.current
        for offset in 1 ... 8 {
            if let date = calendar.date(byAdding: .minute, value: offset * 15, to: now) {
                entries.append(makeEntry(at: date))
            }
        }
        if let midnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) {
            entries.append(makeEntry(at: midnight))
        }

        let next = calendar.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(15 * 60)
        completion(Timeline(entries: entries, policy: .after(next)))
    }

    private func makeEntry(at date: Date = Date()) -> TimeBlockEntry {
        let isPremium = WidgetSettings.isPremium
        let tasks: [TimeBlockTask]
        if isPremium {
            tasks = TimeBlockLayout.overlayPending(on: WidgetDatabase.shared.fetchTimeBlockTasks())
        } else {
            tasks = []
        }
        return TimeBlockEntry(
            date: date,
            isPremium: isPremium,
            tasks: tasks,
            nowMinutes: TimeBlockLayout.minutesFromMidnight(date)
        )
    }
}
