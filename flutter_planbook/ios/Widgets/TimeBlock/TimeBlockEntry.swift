//
//  TimeBlockEntry.swift
//  Widgets
//

import WidgetKit

@available(iOS 16.0, *)
struct TimeBlockEntry: TimelineEntry {
    let date: Date
    let isPremium: Bool
    let tasks: [TimeBlockTask]
    let nowMinutes: Int
}
