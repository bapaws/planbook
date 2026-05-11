//
//  QuadrantWidgetSmallView.swift
//  Widgets
//
//  中号四象限组件 View（左侧切换 + 右侧列表）
//

import AppIntents
import SwiftUI
import SwiftUIX
import WidgetKit

struct QuadrantWidgetSmallView: View {
    var entry: QuadrantEntry

    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    private var selectedGroup: QuadrantGroup? {
        entry.groups.first { $0.priority == entry.selectedPriority }
    }

    private var isDarkMode: Bool {
        WidgetBackgroundConfig.current().isDarkMode
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 左侧象限切换栏
            let headerHeight: Double = 36
            GeometryReader { proxy in
                HStack(spacing: 0) {
                    ForEach(entry.groups) { group in
                        quadrantButton(group)
                    }
                    .width(proxy.size.width / 4)
                }
            }
            .padding(.top, .extraSmall)
            .padding(.horizontal, .small)
            .height(headerHeight)

            // 右侧任务列表
            if let group = selectedGroup {
                let theme = group.priority.getColorScheme(isDarkMode: isDarkMode)
                if group.tasks.isEmpty {
                    Spacer()
                } else {
                    ForEach(group.tasks.prefix(4)) { task in
                        QuadrantTaskRow(task: task, theme: theme)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func quadrantButton(_ group: QuadrantGroup) -> some View {
        let isSelected = group.priority == entry.selectedPriority
        let theme = group.priority.getColorScheme(isDarkMode: isDarkMode)

        return Button(intent: SwitchQuadrantIntent(priority: group.priority)) {
            Text("\(group.priority.index + 1)")
                .font(.system(size: 14, weight: .bold))
                .italic()
                .foregroundStyle(theme.primaryColor)
                .frame(width: 21, height: 21, alignment: .center)
                .background(widgetRenderingMode == .fullColor ? theme.primaryContainerColor : theme.primaryContainerColor.opacity(0.12))
                .modify(if: isSelected) {
                    $0.border(cornerRadius: 8, style: .init())
                }
                .modify(if: !isSelected) {
                    $0.clipShape(.rect(cornerRadius: 8, style: .continuous))
                }
        }
        .buttonStyle(.plain)
        .frame(height: 36)
    }
}
