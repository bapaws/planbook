//
//  QuickNoteWidget.swift
//  Widgets
//
//  快速笔记小组件（小号 1×1）
//

import SwiftUI
import WidgetKit

struct QuickNoteEntry: TimelineEntry {
    let date: Date
}

struct QuickNoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickNoteEntry {
        QuickNoteEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickNoteEntry) -> ()) {
        completion(QuickNoteEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickNoteEntry>) -> ()) {
        // 静态组件，不需要刷新
        let entry = QuickNoteEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct QuickNoteWidgetView: View {
    var entry: QuickNoteEntry

    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    private var iconColor: Color {
        widgetRenderingMode == .fullColor ? AppFlutterColorSchemes.light.primaryColor : .primary
    }

    private var iconBackgroundColor: Color {
        widgetRenderingMode == .fullColor ? AppFlutterColorSchemes.light.primaryContainerColor : .primary.opacity(0.2)
    }

    private var textColor: Color {
        widgetRenderingMode == .fullColor ? AppFlutterColorSchemes.light.outlineColor : .primary
    }

    private var accessoryIconBackgroundColor: Color {
        widgetRenderingMode == .fullColor ? iconBackgroundColor : .primary.opacity(0.14)
    }

    var body: some View {
        Group {
            if widgetFamily == .accessoryCircular {
                Image("feather-pointed-solid")
                    .renderingMode(.template)
                    .padding()
                    .foregroundStyle(iconColor)
                    .background(Circle().fill(accessoryIconBackgroundColor))
            } else {
                VStack {
                    Image("feather-pointed-solid")
                        .renderingMode(.template)
                        .foregroundStyle(iconColor)
                        .padding()
                        .background(Circle().fill(accessoryIconBackgroundColor))
                    Text(String(localized: "intent.createNote.title"))
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .lineLimit(1)
                        .foregroundStyle(textColor)
                }
            }
        }
        .widgetURL(URL(string: "planbook.bapaws://note/new")!)
    }
}

struct QuickNoteWidget: Widget {
    static let kind = "QuickNoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: QuickNoteProvider()) { entry in
            QuickNoteWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetTiledBackground(config: WidgetBackgroundConfig.current())
                }
        }
        .configurationDisplayName(String(localized: "intent.createNote.title"))
        .description(String(localized: "intent.createNote.description"))
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

#Preview(as: .systemSmall) {
    QuickNoteWidget()
} timeline: {
    QuickNoteEntry(date: .now)
}
