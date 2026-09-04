//
//  TimeBlockWidget.swift
//  Widgets
//

import SwiftUI
import WidgetKit

struct TimeBlockWidgetLarge: Widget {
    static let kind = kTimeBlockWidgetLargeKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: TimeBlockProvider()) { entry in
            TimeBlockView(entry: entry, family: .systemLarge)
                .containerBackground(for: .widget) {
                    WidgetTiledBackground(config: WidgetBackgroundConfig.current())
                }
        }
        .contentMarginsDisabled()
        .configurationDisplayName(String(localized: "widget.timeBlock.large.name"))
        .description(String(localized: "widget.timeBlock.large.description"))
        .supportedFamilies([.systemLarge])
    }
}

struct TimeBlockWidgetMedium: Widget {
    static let kind = kTimeBlockWidgetMediumKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: TimeBlockProvider()) { entry in
            TimeBlockView(entry: entry, family: .systemMedium)
                .containerBackground(for: .widget) {
                    WidgetTiledBackground(config: WidgetBackgroundConfig.current())
                }
        }
        .contentMarginsDisabled()
        .configurationDisplayName(String(localized: "widget.timeBlock.medium.name"))
        .description(String(localized: "widget.timeBlock.medium.description"))
        .supportedFamilies([.systemMedium])
    }
}
