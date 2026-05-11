//
//  QuadrantWidgetLargeView.swift
//  Widgets
//
//  大号四象限组件 View（2x2 网格）
//

import AppIntents
import SwiftUI
import SwiftUIX
import WidgetKit

private let kQuadrantLargeSpacing: CGFloat = 12

struct QuadrantWidgetLargeView: View {
    var entry: QuadrantEntry

    private var isDarkMode: Bool {
        WidgetBackgroundConfig.current().isDarkMode
    }

    var body: some View {
        GeometryReader { geometry in
            let halfWidth = (geometry.size.width - kQuadrantLargeSpacing) / 2
            let halfHeight = (geometry.size.height) / 2

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    QuadrantView(entry: entry, group: entry.groups[0], size: CGSize(width: halfWidth, height: halfHeight), isDark: isDarkMode)
                    QuadrantView(entry: entry, group: entry.groups[1], size: CGSize(width: halfWidth, height: halfHeight), isDark: isDarkMode)
                }
                HStack(spacing: 0) {
                    QuadrantView(entry: entry, group: entry.groups[2], size: CGSize(width: halfWidth, height: halfHeight), isDark: isDarkMode)
                    QuadrantView(entry: entry, group: entry.groups[3], size: CGSize(width: halfWidth, height: halfHeight), isDark: isDarkMode)
                }
            }
        }
        .padding(.top, kQuadrantLargeSpacing)
    }
}

struct QuadrantColorHeader: View {
    let priority: TaskPriority
    let theme: FlutterColorScheme

    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text("\(priority.index + 1). ")
                .font(.system(size: 14, weight: .bold))
                .italic()
            Text(priority.quadrantTitle)
                .font(.system(size: 11, weight: .regular))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
            Spacer(minLength: 0)
        }
        .foregroundStyle(theme.onPrimaryContainerColor)
        .padding(.leading, .small)
        .padding(.trailing, .extraSmall)
        .height(20)
        .background(headerBackground)
        .clipShape(.rect(cornerRadius: 8, style: .continuous))
    }

    private var headerBackground: Color {
        widgetRenderingMode == .fullColor ? theme.primaryContainerColor : theme.primaryContainerColor.opacity(0.12)
    }
}

struct QuadrantFlagHeader: View {
    let priority: TaskPriority
    let theme: FlutterColorScheme

    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    var body: some View {
        HStack(spacing: 6) {
            Text("\(priority.index + 1)")
                .font(.system(size: 14, weight: .bold))
                .italic()
                .foregroundStyle(theme.onPrimaryContainerColor)
                .frame(width: 20, height: 20, alignment: .center)
                .background(widgetRenderingMode == .fullColor ? theme.primaryContainerColor : theme.primaryContainerColor.opacity(0.12))
                .clipShape(.rect(cornerRadius: 8, style: .continuous))
            Text(priority.quadrantTitle)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .foregroundStyle(theme.primaryColor)
            Spacer()
        }
    }
}

struct QuadrantView: View {
    let entry: QuadrantEntry
    let group: QuadrantGroup
    let size: CGSize
    let isDark: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    var body: some View {
        let theme = group.priority.getColorScheme(isDarkMode: isDark)
        VStack(alignment: .leading, spacing: 4) {
            // 象限标题
            QuadrantColorHeader(priority: group.priority, theme: theme)
                .padding(.leading, kQuadrantLargeSpacing)

            // 任务列表
            if group.tasks.isEmpty {
                Spacer()
            } else {
                ForEach(group.tasks.prefix(5)) { task in
                    QuadrantTaskRow(task: task, theme: theme)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
