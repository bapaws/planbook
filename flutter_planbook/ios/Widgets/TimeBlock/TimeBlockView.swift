//
//  TimeBlockView.swift
//  Widgets
//
//  大号：左右两列 0–12 / 12–24；中号：当前时刻附近约 4 小时。
//

import AppIntents
import SwiftUI
import WidgetKit

private let kTimeLabelWidth: CGFloat = 36
private let kHeaderHeight: CGFloat = 22
private let kOpenTimeBlockURL = URL(string: "planbook.bapaws://task/today?view=timeBlock")!
private let kPurchasesURL = URL(string: "planbook.bapaws://purchases")!

@available(iOS 16.0, *)
struct TimeBlockView: View {
    var entry: TimeBlockEntry
    var family: WidgetFamily

    private var isDarkMode: Bool {
        WidgetBackgroundConfig.current().isDarkMode
    }

    var body: some View {
        Group {
            if !entry.isPremium {
                lockedView
                    .widgetURL(kPurchasesURL)
            } else {
                scheduleView
                    .widgetURL(kOpenTimeBlockURL)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private var lockedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Colors.errorColor)
            Text(String(localized: "widget.timeBlock.locked"))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Colors.outlineColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var scheduleView: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            if family == .systemLarge {
                ZStack {
                    largeColumns
                    if entry.tasks.isEmpty {
                        emptyOverlay
                    }
                }
            } else {
                ZStack {
                    mediumColumn
                    if entry.tasks.isEmpty {
                        emptyOverlay
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text(String(localized: "widget.timeBlock.today"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Colors.onSurfaceColor)
            Spacer(minLength: 4)
            Text(headerDate)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Colors.outlineColor)
        }
        .frame(height: kHeaderHeight)
    }

    private var emptyOverlay: some View {
        Text(String(localized: "widget.timeBlock.empty"))
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Colors.outlineColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
    }

    private var headerDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: entry.date)
    }

    private var largeColumns: some View {
        GeometryReader { proxy in
            let hourHeight = proxy.size.height / 12
            HStack(spacing: 6) {
                column(
                    windowStart: 0,
                    windowEnd: 12 * 60,
                    hourHeight: hourHeight,
                    size: CGSize(width: (proxy.size.width - 6) / 2, height: proxy.size.height)
                )
                Rectangle()
                    .fill(Colors.surfaceContainerHighestColor.opacity(0.8))
                    .frame(width: 1)
                column(
                    windowStart: 12 * 60,
                    windowEnd: 24 * 60,
                    hourHeight: hourHeight,
                    size: CGSize(width: (proxy.size.width - 6) / 2, height: proxy.size.height)
                )
            }
        }
    }

    private var mediumColumn: some View {
        GeometryReader { proxy in
            let window = TimeBlockLayout.mediumWindow(nowMinutes: entry.nowMinutes)
            let hours = CGFloat(window.end - window.start) / 60
            let hourHeight = proxy.size.height / max(hours, 1)
            column(
                windowStart: window.start,
                windowEnd: window.end,
                hourHeight: hourHeight,
                size: proxy.size
            )
        }
    }

    private func column(
        windowStart: Int,
        windowEnd: Int,
        hourHeight: CGFloat,
        size: CGSize
    ) -> some View {
        let items = TimeBlockLayout.layout(
            tasks: entry.tasks,
            windowStart: windowStart,
            windowEnd: windowEnd,
            hourHeight: hourHeight
        )
        let hours = TimeBlockLayout.visibleHours(windowStart: windowStart, windowEnd: windowEnd)
        let showNow = entry.nowMinutes >= windowStart && entry.nowMinutes < windowEnd
        let nowTop = TimeBlockLayout.yOffset(
            minutes: entry.nowMinutes,
            windowStart: windowStart,
            hourHeight: hourHeight
        )
        let gridWidth = size.width - kTimeLabelWidth

        return ZStack(alignment: .topLeading) {
            ForEach(hours, id: \.self) { hour in
                TimeBlockHourMark(
                    hour: hour,
                    y: TimeBlockLayout.yOffset(
                        minutes: hour * 60,
                        windowStart: windowStart,
                        hourHeight: hourHeight
                    ),
                    isWindowStart: hour * 60 == windowStart
                )
            }

            ForEach(items) { item in
                TimeBlockItemView(
                    item: item,
                    parentWidth: gridWidth,
                    isDark: isDarkMode
                )
                .offset(x: kTimeLabelWidth, y: item.top)
            }

            if showNow {
                currentTimeLine(top: nowTop, width: size.width)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    private func currentTimeLine(top: CGFloat, width: CGFloat) -> some View {
        let hour = entry.nowMinutes / 60
        let minute = entry.nowMinutes % 60
        let text = String(format: "%02d:%02d", hour, minute)

        return HStack(spacing: 0) {
            Text(text)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Colors.onErrorColor)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Colors.errorColor, in: RoundedRectangle(cornerRadius: 3))
                .frame(width: kTimeLabelWidth)
            Circle()
                .fill(Colors.errorColor)
                .frame(width: 6, height: 6)
            Rectangle()
                .fill(Colors.errorColor)
                .frame(height: 2)
        }
        .frame(width: width, alignment: .leading)
        .offset(y: top - 7)
        .allowsHitTesting(false)
    }
}

@available(iOS 16.0, *)
private struct TimeBlockHourMark: View {
    let hour: Int
    let y: CGFloat
    let isWindowStart: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(TimeBlockLayout.formatHourLabel(hour))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Colors.outlineColor)
                .frame(width: kTimeLabelWidth, alignment: .top)
            Rectangle()
                .fill(Colors.surfaceContainerHighestColor)
                .frame(height: isWindowStart ? 1 : 0.5)
                .frame(maxWidth: .infinity, alignment: .top)
        }
        .offset(y: y)
    }
}

@available(iOS 16.0, *)
private struct TimeBlockItemView: View {
    let item: TimeBlockLayoutItem
    let parentWidth: CGFloat
    let isDark: Bool

    var body: some View {
        let theme = item.task.priority.getColorScheme(isDarkMode: isDark)
        let width = parentWidth * item.widthFactor
        let left = parentWidth * (CGFloat(item.columnIndex) / CGFloat(item.columnCount))
        let showTime = item.height >= 28

        return HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text(item.task.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(item.task.isCompleted ? theme.outlineColor : theme.primaryColor)
                    .strikethrough(item.task.isCompleted)
                    .lineLimit(showTime ? 1 : 2)
                if showTime {
                    Text(item.timeRangeLabel)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(item.task.isCompleted ? theme.outlineColor : theme.primaryColor)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 4)
            .padding(.top, 3)
            Spacer(minLength: 0)
            Button(
                intent: CompleteTaskIntent(
                    taskId: item.task.taskId,
                    occurrenceAt: item.task.occurrenceAt
                )
            ) {
                Image(systemName: item.task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(item.task.isCompleted ? theme.outlineColor : theme.primaryColor)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .frame(width: width, height: item.height, alignment: .topLeading)
        .background(theme.primaryContainerColor, in: RoundedRectangle(cornerRadius: 5))
        .offset(x: left)
    }
}
