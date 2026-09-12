//
//  TimeBlockView.swift
//  Widgets
//
//  大号：左右两列 0–12 / 12–24；中号和小号：当前整点起 4 小时。
//

import AppIntents
import SwiftUI
import WidgetKit

// 与 Flutter 时间块的 48pt 时间栏保持相同语义；小组件内适度压缩，
// 但仍需完整容纳 `HH:00` 和当前时间徽标。
private let kTimeLabelWidth: CGFloat = 36
private let kHeaderHeight: CGFloat = 22
private let kColumnGutter: CGFloat = 10
private let kGridTopInset: CGFloat = 6
private let kOpenTimeBlockURL = URL(string: "planbook.bapaws://task/today?view=timeBlock")!
private let kCreateTaskURL = URL(string: "planbook.bapaws://task/new")!
private let kPurchasesURL = URL(string: "planbook.bapaws://purchases")!

@available(iOS 16.0, *)
struct TimeBlockView: View {
    var entry: TimeBlockEntry

    @Environment(\.widgetFamily) private var family

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
        .padding(.leading, family == .systemSmall ? 0 : 10)
        .padding(.trailing, 10)
        .padding(.vertical, 10)
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
        VStack(alignment: .leading, spacing: 6) {
            header
            Group {
                if family == .systemLarge {
                    largeColumns
                } else {
                    mediumColumn
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Colors.primaryColor)
                    .frame(width: 3, height: 14)
                Text(String(localized: "widget.timeBlock.today"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Colors.onSurfaceColor)
                if family != .systemSmall && entry.tasks.isEmpty {
                    Text(String(localized: "widget.timeBlock.empty"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Colors.outlineColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 4)
            if family != .systemSmall {
                Text(headerDate)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Colors.outlineColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Colors.surfaceContainerHighestColor.opacity(0.72),
                        in: Capsule(style: .continuous)
                    )
            }
            Link(destination: kCreateTaskURL) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Colors.primaryColor)
                    .frame(width: 20, height: 20)
                    .background(
                        Colors.primaryContainerColor.opacity(0.88),
                        in: Circle()
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "widget.task.new"))
        }
        .frame(height: kHeaderHeight, alignment: .center)
        .padding(.leading, family == .systemSmall ? 10 : 0)
    }

    private var headerDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: entry.date)
    }

    private var largeColumns: some View {
        GeometryReader { proxy in
            let drawableHeight = max(proxy.size.height, 1)
            let hourHeight = max(drawableHeight - kGridTopInset, 1) / 12
            let columnWidth = (proxy.size.width - kColumnGutter) / 2
            HStack(alignment: .top, spacing: kColumnGutter) {
                column(
                    windowStart: 0,
                    windowEnd: 12 * 60,
                    hourHeight: hourHeight,
                    size: CGSize(width: columnWidth, height: drawableHeight)
                )
                column(
                    windowStart: 12 * 60,
                    windowEnd: 24 * 60,
                    hourHeight: hourHeight,
                    size: CGSize(width: columnWidth, height: drawableHeight)
                )
            }
        }
    }

    private var mediumColumn: some View {
        GeometryReader { proxy in
            let window = TimeBlockLayout.mediumWindow(nowMinutes: entry.nowMinutes)
            let hours = CGFloat(window.end - window.start) / 60
            let drawableHeight = max(proxy.size.height, 1)
            let hourHeight = max(drawableHeight - kGridTopInset, 1) / max(hours, 1)
            column(
                windowStart: window.start,
                windowEnd: window.end,
                hourHeight: hourHeight,
                size: CGSize(width: proxy.size.width, height: drawableHeight)
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
        let gridWidth = max(size.width - kTimeLabelWidth, 1)

        return ZStack(alignment: .topLeading) {
            ForEach(hours, id: \.self) { hour in
                let y = TimeBlockLayout.yOffset(
                    minutes: hour * 60,
                    windowStart: windowStart,
                    hourHeight: hourHeight
                )
                TimeBlockHourMark(
                    hour: hour,
                    width: size.width
                )
                .frame(width: size.width, height: 0, alignment: .topLeading)
                .offset(y: y)
            }

            ForEach(items) { item in
                TimeBlockItemView(
                    item: item,
                    parentWidth: gridWidth,
                    isDark: isDarkMode
                )
                .offset(x: kTimeLabelWidth, y: kGridTopInset + item.top)
            }

            if showNow {
                currentTimeLine(top: kGridTopInset + nowTop, width: size.width)
            }
        }
        // offset 不参与布局，必须顶对齐，否则整列会被垂直居中，下午/上午后半段被裁切。
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .clipped()
    }

    private func currentTimeLine(top: CGFloat, width: CGFloat) -> some View {
        let hour = entry.nowMinutes / 60
        let minute = entry.nowMinutes % 60
        let text = String(format: "%02d:%02d", hour, minute)

        return HStack(spacing: 0) {
            Text(text)
                .font(.system(size: 8, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Colors.onErrorColor)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Colors.errorColor, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .frame(width: kTimeLabelWidth)
            Circle()
                .fill(Colors.errorColor)
                .frame(width: 5, height: 5)
            Rectangle()
                .fill(Colors.errorColor)
                .frame(height: 1.5)
        }
        .frame(width: width, height: 0, alignment: .leading)
        .offset(y: top)
        .allowsHitTesting(false)
    }
}

@available(iOS 16.0, *)
private struct TimeBlockHourMark: View {
    let hour: Int
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(TimeBlockLayout.formatHourLabel(hour))
                .font(.system(size: 8, weight: .regular))
                .monospacedDigit()
                .foregroundStyle(Colors.outlineColor)
                .frame(width: kTimeLabelWidth, alignment: .center)

            Rectangle()
                .fill(Colors.surfaceContainerHighestColor)
                .frame(width: width - kTimeLabelWidth, height: hour == 0 || hour == 12 ? 1 : 0.5)
                .offset(x: kTimeLabelWidth, y: kGridTopInset)
        }
        .frame(width: width, height: 12, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

@available(iOS 16.0, *)
private struct TimeBlockItemView: View {
    let item: TimeBlockLayoutItem
    let parentWidth: CGFloat
    let isDark: Bool

    private var taskDetailURL: URL {
        var components = URLComponents()
        components.scheme = "planbook.bapaws"
        components.host = "task"
        components.path = "/detail"
        components.queryItems = [
            URLQueryItem(name: "taskId", value: item.task.taskId)
        ]
        if let occurrenceAt = item.task.occurrenceAt, !occurrenceAt.isEmpty {
            components.queryItems?.append(
                URLQueryItem(name: "occurrenceAt", value: occurrenceAt)
            )
        }
        return components.url ?? kOpenTimeBlockURL
    }

    var body: some View {
        let theme = item.task.priority.getColorScheme(isDarkMode: isDark)
        let width = max(parentWidth * item.widthFactor, 8)
        let left = parentWidth * (CGFloat(item.columnIndex) / CGFloat(item.columnCount))
        let showTime = item.height >= 32
        let accent = item.task.isCompleted ? theme.outlineColor : theme.primaryColor
        let titleColor = item.task.isCompleted ? theme.outlineColor : theme.primaryColor

        return HStack(alignment: .top, spacing: 0) {
            Link(destination: taskDetailURL) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.task.title)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(titleColor)
                        .strikethrough(item.task.isCompleted)
                        .lineLimit(showTime ? 1 : 2)
                    if showTime {
                        Text(item.timeRangeLabel)
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(accent.opacity(0.9))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, 5)
                .padding(.trailing, 2)
                .padding(.top, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button(
                intent: CompleteTaskIntent(
                    taskId: item.task.taskId,
                    occurrenceAt: item.task.occurrenceAt
                )
            ) {
                Image(systemName: item.task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(accent)
                    .padding(.trailing, 3)
                    .padding(.top, 2)
            }
            .buttonStyle(.plain)
        }
        .frame(width: width, height: item.height, alignment: .topLeading)
        .background(theme.primaryContainerColor.opacity(0.92), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .offset(x: left)
    }
}
