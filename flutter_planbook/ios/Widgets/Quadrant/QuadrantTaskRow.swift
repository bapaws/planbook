//
//  QuadrantTaskRow.swift
//  Widgets
//
//  四象限任务行（公共组件）
//

import AppIntents
import SwiftUI
import SwiftUIX
import WidgetKit

struct QuadrantTaskRow: View {
    let task: QuadrantTask
    let theme: FlutterColorScheme

    @Environment(\.widgetFamily) var family

    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    var body: some View {
        HStack(spacing: 0) {
            Button(intent: CompleteTaskIntent(taskId: task.id)) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(iconColor)
                    .padding(.leading, family == .systemSmall ? .extraSmall : .small)
                    .padding(.horizontal, .small)
                    .padding(.vertical, .extraSmall)
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(.footnote))
                .lineLimit(1)
                .strikethrough(task.isCompleted)
                .foregroundStyle(textColor)

            Spacer(minLength: 0)
        }
    }

    private var iconColor: Color {
        if widgetRenderingMode == .fullColor {
            task.isCompleted ? theme.outlineVariantColor : theme.outlineColor
        } else {
            task.isCompleted ? .secondary : .primary
        }
    }

    private var textColor: Color {
        if widgetRenderingMode == .fullColor {
            task.isCompleted ? theme.outlineColor : theme.onSurfaceVariantColor
        } else {
            task.isCompleted ? .secondary : .primary
        }
    }
}
