# iOS 小组件完整实现

本文档包含 Planbook 所有小组件的完整实现代码。

## 文件结构

```
ios/PlanbookWidgets/
├── PlanbookWidgetsBundle.swift
├── Models/
│   ├── WidgetModels.swift
│   └── WidgetTheme.swift
├── Utils/
│   ├── WidgetDataProvider.swift
│   └── ColorExtensions.swift
├── TodayWidget/
│   ├── TodayWidget.swift
│   ├── TodayWidgetProvider.swift
│   └── TodayWidgetView.swift
├── QuadrantWidget/
│   ├── QuadrantWidget.swift
│   ├── QuadrantWidgetProvider.swift
│   └── QuadrantWidgetView.swift
├── InboxWidget/
│   ├── InboxWidget.swift
│   ├── InboxWidgetProvider.swift
│   └── InboxWidgetView.swift
├── TagFilterWidget/
│   ├── TagFilterWidget.swift
│   ├── TagFilterWidgetProvider.swift
│   └── TagFilterWidgetView.swift
└── QuickCaptureWidget/
    ├── QuickCaptureWidget.swift
    ├── QuickCaptureWidgetProvider.swift
    └── QuickCaptureWidgetView.swift
```

---

## 1. 共享代码

### 1.1 WidgetModels.swift（更新版）

```swift
// ios/PlanbookWidgets/Models/WidgetModels.swift

import Foundation

// MARK: - 基础模型

struct WidgetTask: Codable, Identifiable {
    let id: String
    let title: String
    let isCompleted: Bool
    let priority: TaskPriority
    let dueAt: Date?
    let tags: [WidgetTag]
    
    enum TaskPriority: String, Codable {
        case high = "high"
        case medium = "medium"
        case low = "low"
        case none = "none"
    }
}

struct WidgetTag: Codable {
    let id: String
    let name: String
    let color: String?
}

// MARK: - 主题配置

struct WidgetThemeConfig: Codable {
    let themeId: String
    let isDarkMode: Bool
    let priorityColors: PriorityColors?
    
    struct PriorityColors: Codable {
        let importantUrgent: String
        let importantNotUrgent: String
        let urgentUnimportant: String
        let notUrgentUnimportant: String
    }
}

// MARK: - 数据容器

struct WidgetDataContainer: Codable {
    let timestamp: Date
    let todayTasks: [WidgetTask]
    let inboxTasks: [WidgetTask]
    let quadrantCounts: QuadrantCounts
    let selectedTag: WidgetTag?
    let themeConfig: WidgetThemeConfig
}

struct QuadrantCounts: Codable {
    let importantUrgent: Int
    let importantNotUrgent: Int
    let urgentUnimportant: Int
    let notUrgentUnimportant: Int
    
    var total: Int {
        importantUrgent + importantNotUrgent + urgentUnimportant + notUrgentUnimportant
    }
}

// MARK: - 预览数据

extension WidgetTask {
    static let sampleTasks: [WidgetTask] = [
        WidgetTask(id: "1", title: "完成项目汇报", isCompleted: false, priority: .high, dueAt: Date(), tags: []),
        WidgetTask(id: "2", title: "回复客户邮件", isCompleted: false, priority: .medium, dueAt: Date(), tags: []),
        WidgetTask(id: "3", title: "团队周会", isCompleted: true, priority: .medium, dueAt: Date(), tags: []),
        WidgetTask(id: "4", title: "阅读技术文档", isCompleted: false, priority: .low, dueAt: Date(), tags: []),
    ]
    
    static let sampleInboxTasks: [WidgetTask] = [
        WidgetTask(id: "5", title: "学习 Flutter 新特性", isCompleted: false, priority: .none, dueAt: nil, tags: []),
        WidgetTask(id: "6", title: "购买办公用品", isCompleted: false, priority: .none, dueAt: nil, tags: []),
        WidgetTask(id: "7", title: "预约牙医", isCompleted: false, priority: .none, dueAt: nil, tags: []),
    ]
}

extension QuadrantCounts {
    static let sample = QuadrantCounts(
        importantUrgent: 2,
        importantNotUrgent: 3,
        urgentUnimportant: 1,
        notUrgentUnimportant: 0
    )
}
```

### 1.2 WidgetDataProvider.swift（更新版）

```swift
// ios/PlanbookWidgets/Utils/WidgetDataProvider.swift

import Foundation
import WidgetKit

class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    private let appGroupId = "group.GM4766U38W.com.bapaws.habits"
    private let widgetDataKey = "widget_data"
    private let themeIdKey = "widget_theme_id"
    private let isDarkModeKey = "widget_is_dark_mode"
    
    private func getDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }
    
    func loadWidgetData() -> WidgetDataContainer? {
        guard let defaults = getDefaults() else { return nil }
        
        let themeConfig = loadThemeConfig()
        
        if let jsonString = defaults.string(forKey: widgetDataKey),
           let jsonData = jsonString.data(using: .utf8),
           var container = try? JSONDecoder().decode(WidgetDataContainer.self, from: jsonData) {
            return WidgetDataContainer(
                timestamp: container.timestamp,
                todayTasks: container.todayTasks,
                inboxTasks: container.inboxTasks,
                quadrantCounts: container.quadrantCounts,
                selectedTag: container.selectedTag,
                themeConfig: themeConfig
            )
        }
        
        // 返回默认数据
        return WidgetDataContainer(
            timestamp: Date(),
            todayTasks: WidgetTask.sampleTasks,
            inboxTasks: WidgetTask.sampleInboxTasks,
            quadrantCounts: QuadrantCounts.sample,
            selectedTag: nil,
            themeConfig: themeConfig
        )
    }
    
    func loadThemeConfig() -> WidgetThemeConfig {
        guard let defaults = getDefaults() else {
            return WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
        }
        
        let themeId = defaults.string(forKey: themeIdKey) ?? "red"
        let isDarkMode = defaults.bool(forKey: isDarkModeKey)
        
        return WidgetThemeConfig(themeId: themeId, isDarkMode: isDarkMode, priorityColors: nil)
    }
    
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

---

## 2. 今天任务小组件（TodayWidget）

### 2.1 TodayWidget.swift

```swift
// ios/PlanbookWidgets/TodayWidget/TodayWidget.swift

import WidgetKit
import SwiftUI

struct TodayWidget: Widget {
    let kind: String = "TodayWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayWidgetProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("今天任务")
        .description("查看今天需要完成的任务列表")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(
        date: .now,
        tasks: WidgetTask.sampleTasks,
        completedCount: 1,
        totalCount: 4,
        themeConfig: WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
    )
}

#Preview(as: .systemMedium) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(
        date: .now,
        tasks: WidgetTask.sampleTasks,
        completedCount: 1,
        totalCount: 4,
        themeConfig: WidgetThemeConfig(themeId: "blue", isDarkMode: false, priorityColors: nil)
    )
}
```

### 2.2 TodayWidgetProvider.swift

```swift
// ios/PlanbookWidgets/TodayWidget/TodayWidgetProvider.swift

import WidgetKit

struct TodayWidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let completedCount: Int
    let totalCount: Int
    let themeConfig: WidgetThemeConfig
}

struct TodayWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> TodayWidgetEntry {
        TodayWidgetEntry(
            date: Date(),
            tasks: WidgetTask.sampleTasks,
            completedCount: 1,
            totalCount: 4,
            themeConfig: WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TodayWidgetEntry) -> Void) {
        let data = WidgetDataProvider.shared.loadWidgetData()
        let entry = TodayWidgetEntry(
            date: Date(),
            tasks: data?.todayTasks ?? WidgetTask.sampleTasks,
            completedCount: data?.todayTasks.filter { $0.isCompleted }.count ?? 0,
            totalCount: data?.todayTasks.count ?? 0,
            themeConfig: data?.themeConfig ?? WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWidgetEntry>) -> Void) {
        getSnapshot(in: context) { entry in
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}
```

### 2.3 TodayWidgetView.swift

```swift
// ios/PlanbookWidgets/TodayWidget/TodayWidgetView.swift

import SwiftUI
import WidgetKit

struct TodayWidgetView: View {
    var entry: TodayWidgetEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var systemColorScheme
    
    var body: some View {
        let config = entry.themeConfig
        let colorScheme = WidgetThemeManager.getColorScheme(from: config)
        let priorityColors = WidgetThemeManager.getPriorityColors(from: config)
        
        switch family {
        case .systemSmall:
            TodaySmallView(entry: entry, colorScheme: colorScheme)
        case .systemMedium:
            TodayMediumView(entry: entry, colorScheme: colorScheme, priorityColors: priorityColors)
        case .systemLarge:
            TodayLargeView(entry: entry, colorScheme: colorScheme, priorityColors: priorityColors)
        default:
            TodayMediumView(entry: entry, colorScheme: colorScheme, priorityColors: priorityColors)
        }
    }
}

// MARK: - Small

struct TodaySmallView: View {
    let entry: TodayWidgetEntry
    let colorScheme: AppColorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "checklist")
                .font(.system(size: 28))
                .foregroundColor(colorScheme.primaryColor)
            
            Text("\(entry.completedCount)/\(entry.totalCount)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(colorScheme.labelColor)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorScheme.tertiaryBackgroundColor)
                        .frame(height: 4)
                    
                    if entry.totalCount > 0 {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorScheme.primaryColor)
                            .frame(
                                width: geo.size.width * CGFloat(entry.completedCount) / CGFloat(max(entry.totalCount, 1)),
                                height: 4
                            )
                    }
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 12)
            
            Text("今天待办")
                .font(.caption2)
                .foregroundColor(colorScheme.secondaryLabelColor)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme.backgroundColor)
    }
}

// MARK: - Medium

struct TodayMediumView: View {
    let entry: TodayWidgetEntry
    let colorScheme: AppColorScheme
    let priorityColors: PriorityColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(colorScheme.primaryColor)
                    Text("今天待办")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(colorScheme.labelColor)
                
                Spacer()
                
                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(colorScheme.secondaryLabelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorScheme.tertiaryBackgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(colorScheme.secondaryBackgroundColor)
            
            Divider()
                .background(colorScheme.outlineColor)
            
            // Task List
            if entry.tasks.isEmpty {
                EmptyTaskView(colorScheme: colorScheme)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entry.tasks.prefix(4).enumerated()), id: \.element.id) { index, task in
                        TaskRowView(task: task, colorScheme: colorScheme, priorityColors: priorityColors)
                        
                        if index < min(entry.tasks.count, 4) - 1 {
                            Divider()
                                .padding(.leading, 40)
                                .background(colorScheme.outlineColor)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .background(colorScheme.backgroundColor)
    }
}

// MARK: - Large

struct TodayLargeView: View {
    let entry: TodayWidgetEntry
    let colorScheme: AppColorScheme
    let priorityColors: PriorityColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(colorScheme.primaryColor)
                    Text("今天待办")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(colorScheme.labelColor)
                
                Spacer()
                
                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(colorScheme.secondaryLabelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorScheme.tertiaryBackgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(colorScheme.secondaryBackgroundColor)
            
            Divider()
                .background(colorScheme.outlineColor)
            
            if entry.tasks.isEmpty {
                EmptyTaskView(colorScheme: colorScheme)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entry.tasks.prefix(8).enumerated()), id: \.element.id) { index, task in
                        TaskRowView(task: task, colorScheme: colorScheme, priorityColors: priorityColors)
                        
                        if index < min(entry.tasks.count, 8) - 1 {
                            Divider()
                                .padding(.leading, 40)
                                .background(colorScheme.outlineColor)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .background(colorScheme.backgroundColor)
    }
}

// MARK: - Subviews

struct TaskRowView: View {
    let task: WidgetTask
    let colorScheme: AppColorScheme
    let priorityColors: PriorityColors
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(task.isCompleted ? Color.green : priorityColor)
                .frame(width: 24)
            
            Text(task.title)
                .font(.system(size: 14))
                .lineLimit(1)
                .strikethrough(task.isCompleted, color: colorScheme.secondaryLabelColor)
                .foregroundColor(task.isCompleted ? colorScheme.secondaryLabelColor : colorScheme.labelColor)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    var priorityColor: Color {
        switch task.priority {
        case .high: return priorityColors.importantUrgentColor
        case .medium: return priorityColors.importantNotUrgentColor
        case .low: return priorityColors.urgentUnimportantColor
        case .none: return priorityColors.notUrgentUnimportantColor
        }
    }
}

struct EmptyTaskView: View {
    let colorScheme: AppColorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 36))
                .foregroundColor(colorScheme.tertiaryLabelColor)
            
            Text("今天没有任务")
                .font(.system(size: 14))
                .foregroundColor(colorScheme.secondaryLabelColor)
            
            Text("好好休息一下吧")
                .font(.system(size: 12))
                .foregroundColor(colorScheme.tertiaryLabelColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
    }
}
```

---

## 3. 四象限小组件（QuadrantWidget）

### 3.1 QuadrantWidget.swift

```swift
// ios/PlanbookWidgets/QuadrantWidget/QuadrantWidget.swift

import WidgetKit
import SwiftUI

struct QuadrantWidget: Widget {
    let kind: String = "QuadrantWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuadrantWidgetProvider()) { entry in
            QuadrantWidgetView(entry: entry)
        }
        .configurationDisplayName("四象限")
        .description("查看任务在四象限中的分布")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    QuadrantWidget()
} timeline: {
    QuadrantWidgetEntry(
        date: .now,
        counts: QuadrantCounts.sample,
        tasks: WidgetTask.sampleTasks,
        themeConfig: WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
    )
}

#Preview(as: .systemLarge) {
    QuadrantWidget()
} timeline: {
    QuadrantWidgetEntry(
        date: .now,
        counts: QuadrantCounts.sample,
        tasks: WidgetTask.sampleTasks,
        themeConfig: WidgetThemeConfig(themeId: "blue", isDarkMode: false, priorityColors: nil)
    )
}
```

### 3.2 QuadrantWidgetProvider.swift

```swift
// ios/PlanbookWidgets/QuadrantWidget/QuadrantWidgetProvider.swift

import WidgetKit

struct QuadrantWidgetEntry: TimelineEntry {
    let date: Date
    let counts: QuadrantCounts
    let tasks: [WidgetTask]
    let themeConfig: WidgetThemeConfig
}

struct QuadrantWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> QuadrantWidgetEntry {
        QuadrantWidgetEntry(
            date: Date(),
            counts: QuadrantCounts.sample,
            tasks: WidgetTask.sampleTasks,
            themeConfig: WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuadrantWidgetEntry) -> Void) {
        let data = WidgetDataProvider.shared.loadWidgetData()
        let entry = QuadrantWidgetEntry(
            date: Date(),
            counts: data?.quadrantCounts ?? QuadrantCounts.sample,
            tasks: data?.todayTasks ?? WidgetTask.sampleTasks,
            themeConfig: data?.themeConfig ?? WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuadrantWidgetEntry>) -> Void) {
        getSnapshot(in: context) { entry in
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}
```

### 3.3 QuadrantWidgetView.swift

```swift
// ios/PlanbookWidgets/QuadrantWidget/QuadrantWidgetView.swift

import SwiftUI
import WidgetKit

struct QuadrantWidgetView: View {
    var entry: QuadrantWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        let colorScheme = WidgetThemeManager.getColorScheme(from: entry.themeConfig)
        let priorityColors = WidgetThemeManager.getPriorityColors(from: entry.themeConfig)
        
        switch family {
        case .systemMedium:
            QuadrantMediumView(entry: entry, colorScheme: colorScheme, priorityColors: priorityColors)
        case .systemLarge:
            QuadrantLargeView(entry: entry, colorScheme: colorScheme, priorityColors: priorityColors)
        default:
            QuadrantMediumView(entry: entry, colorScheme: colorScheme, priorityColors: priorityColors)
        }
    }
}

// MARK: - Medium Size

struct QuadrantMediumView: View {
    let entry: QuadrantWidgetEntry
    let colorScheme: AppColorScheme
    let priorityColors: PriorityColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2")
                        .foregroundColor(colorScheme.primaryColor)
                    Text("四象限")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(colorScheme.labelColor)
                
                Spacer()
                
                Text("\(entry.counts.total)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(colorScheme.secondaryLabelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorScheme.tertiaryBackgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            
            // Quadrant Grid
            HStack(spacing: 8) {
                VStack(spacing: 8) {
                    QuadrantCell(
                        title: "重要且紧急",
                        count: entry.counts.importantUrgent,
                        color: priorityColors.importantUrgentColor,
                        icon: "exclamationmark.circle.fill",
                        colorScheme: colorScheme
                    )
                    QuadrantCell(
                        title: "紧急不重要",
                        count: entry.counts.urgentUnimportant,
                        color: priorityColors.urgentUnimportantColor,
                        icon: "bell.fill",
                        colorScheme: colorScheme
                    )
                }
                
                VStack(spacing: 8) {
                    QuadrantCell(
                        title: "重要不紧急",
                        count: entry.counts.importantNotUrgent,
                        color: priorityColors.importantNotUrgentColor,
                        icon: "star.fill",
                        colorScheme: colorScheme
                    )
                    QuadrantCell(
                        title: "不紧急不重要",
                        count: entry.counts.notUrgentUnimportant,
                        color: priorityColors.notUrgentUnimportantColor,
                        icon: "arrow.down.circle.fill",
                        colorScheme: colorScheme
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .background(colorScheme.backgroundColor)
    }
}

// MARK: - Large Size

struct QuadrantLargeView: View {
    let entry: QuadrantWidgetEntry
    let colorScheme: AppColorScheme
    let priorityColors: PriorityColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2")
                        .foregroundColor(colorScheme.primaryColor)
                    Text("四象限")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(colorScheme.labelColor)
                
                Spacer()
                
                Text("\(entry.counts.total)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(colorScheme.secondaryLabelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorScheme.tertiaryBackgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            
            // Quadrant Grid with Tasks
            HStack(spacing: 8) {
                // Column 1
                VStack(spacing: 8) {
                    QuadrantDetailCell(
                        title: "重要且紧急",
                        tasks: entry.tasks.filter { $0.priority == .high && !$0.isCompleted },
                        color: priorityColors.importantUrgentColor,
                        icon: "exclamationmark.circle.fill",
                        colorScheme: colorScheme
                    )
                    
                    QuadrantDetailCell(
                        title: "紧急不重要",
                        tasks: entry.tasks.filter { $0.priority == .low && !$0.isCompleted },
                        color: priorityColors.urgentUnimportantColor,
                        icon: "bell.fill",
                        colorScheme: colorScheme
                    )
                }
                
                // Column 2
                VStack(spacing: 8) {
                    QuadrantDetailCell(
                        title: "重要不紧急",
                        tasks: entry.tasks.filter { $0.priority == .medium && !$0.isCompleted },
                        color: priorityColors.importantNotUrgentColor,
                        icon: "star.fill",
                        colorScheme: colorScheme
                    )
                    
                    QuadrantDetailCell(
                        title: "不紧急不重要",
                        tasks: entry.tasks.filter { $0.priority == .none && !$0.isCompleted },
                        color: priorityColors.notUrgentUnimportantColor,
                        icon: "arrow.down.circle.fill",
                        colorScheme: colorScheme
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .background(colorScheme.backgroundColor)
    }
}

// MARK: - Subviews

struct QuadrantCell: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    let colorScheme: AppColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text("\(count)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(colorScheme.labelColor)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(colorScheme.secondaryLabelColor)
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(color.opacity(0.12))
        .cornerRadius(8)
    }
}

struct QuadrantDetailCell: View {
    let title: String
    let tasks: [WidgetTask]
    let color: Color
    let icon: String
    let colorScheme: AppColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(colorScheme.secondaryLabelColor)
                Spacer()
                Text("\(tasks.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            
            if tasks.isEmpty {
                Text("无任务")
                    .font(.system(size: 11))
                    .foregroundColor(colorScheme.tertiaryLabelColor)
                    .padding(.top, 4)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(tasks.prefix(2)) { task in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(color)
                                .frame(width: 4, height: 4)
                            Text(task.title)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .foregroundColor(colorScheme.labelColor)
                        }
                    }
                    
                    if tasks.count > 2 {
                        Text("+\(tasks.count - 2) 更多")
                            .font(.system(size: 10))
                            .foregroundColor(colorScheme.tertiaryLabelColor)
                            .padding(.leading, 8)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }
}
```

---

## 4. 收集箱小组件（InboxWidget）

### 4.1 InboxWidget.swift

```swift
// ios/PlanbookWidgets/InboxWidget/InboxWidget.swift

import WidgetKit
import SwiftUI

struct InboxWidget: Widget {
    let kind: String = "InboxWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InboxWidgetProvider()) { entry in
            InboxWidgetView(entry: entry)
        }
        .configurationDisplayName("收集箱")
        .description("快速查看未分类任务")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    InboxWidget()
} timeline: {
    InboxWidgetEntry(
        date: .now,
        tasks: WidgetTask.sampleInboxTasks,
        totalCount: 12,
        themeConfig: WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
    )
}

#Preview(as: .systemMedium) {
    InboxWidget()
} timeline: {
    InboxWidgetEntry(
        date: .now,
        tasks: WidgetTask.sampleInboxTasks,
        totalCount: 12,
        themeConfig: WidgetThemeConfig(themeId: "blue", isDarkMode: false, priorityColors: nil)
    )
}
```

### 4.2 InboxWidgetProvider.swift

```swift
// ios/PlanbookWidgets/InboxWidget/InboxWidgetProvider.swift

import WidgetKit

struct InboxWidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let totalCount: Int
    let themeConfig: WidgetThemeConfig
}

struct InboxWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> InboxWidgetEntry {
        InboxWidgetEntry(
            date: Date(),
            tasks: WidgetTask.sampleInboxTasks,
            totalCount: 12,
            themeConfig: WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (InboxWidgetEntry) -> Void) {
        let data = WidgetDataProvider.shared.loadWidgetData()
        let entry = InboxWidgetEntry(
            date: Date(),
            tasks: data?.inboxTasks ?? WidgetTask.sampleInboxTasks,
            totalCount: data?.inboxTasks.count ?? 12,
            themeConfig: data?.themeConfig ?? WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<InboxWidgetEntry>) -> Void) {
        getSnapshot(in: context) { entry in
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}
```

### 4.3 InboxWidgetView.swift

```swift
// ios/PlanbookWidgets/InboxWidget/InboxWidgetView.swift

import SwiftUI
import WidgetKit

struct InboxWidgetView: View {
    var entry: InboxWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        let colorScheme = WidgetThemeManager.getColorScheme(from: entry.themeConfig)
        
        switch family {
        case .systemSmall:
            InboxSmallView(entry: entry, colorScheme: colorScheme)
        case .systemMedium:
            InboxMediumView(entry: entry, colorScheme: colorScheme)
        default:
            InboxSmallView(entry: entry, colorScheme: colorScheme)
        }
    }
}

// MARK: - Small

struct InboxSmallView: View {
    let entry: InboxWidgetEntry
    let colorScheme: AppColorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(colorScheme.primaryColor)
            
            Text("\(entry.totalCount)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(colorScheme.labelColor)
            
            Text("待整理")
                .font(.caption)
                .foregroundColor(colorScheme.secondaryLabelColor)
            
            Text("收集箱")
                .font(.caption2)
                .foregroundColor(colorScheme.tertiaryLabelColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme.backgroundColor)
    }
}

// MARK: - Medium

struct InboxMediumView: View {
    let entry: InboxWidgetEntry
    let colorScheme: AppColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tray")
                        .foregroundColor(colorScheme.primaryColor)
                    Text("收集箱")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(colorScheme.labelColor)
                
                Spacer()
                
                Text("\(entry.totalCount)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(colorScheme.secondaryLabelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorScheme.tertiaryBackgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(colorScheme.secondaryBackgroundColor)
            
            Divider()
                .background(colorScheme.outlineColor)
            
            // Task List
            if entry.tasks.isEmpty {
                VStack(spacing: 4) {
                    Text("收集箱为空")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme.secondaryLabelColor)
                    Text("快速记录你的想法")
                        .font(.system(size: 12))
                        .foregroundColor(colorScheme.tertiaryLabelColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entry.tasks.prefix(3).enumerated()), id: \.element.id) { index, task in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorScheme.tertiaryLabelColor)
                                .frame(width: 4, height: 4)
                            
                            Text(task.title)
                                .font(.system(size: 14))
                                .lineLimit(1)
                                .foregroundColor(colorScheme.labelColor)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        
                        if index < min(entry.tasks.count, 3) - 1 {
                            Divider()
                                .padding(.leading, 24)
                                .background(colorScheme.outlineColor)
                        }
                    }
                }
            }
            
            // Quick Add Hint
            HStack {
                Image(systemName: "plus.circle")
                    .font(.caption)
                    .foregroundColor(colorScheme.tertiaryLabelColor)
                Text("快速添加任务...")
                    .font(.system(size: 11))
                    .foregroundColor(colorScheme.tertiaryLabelColor)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(colorScheme.secondaryBackgroundColor.opacity(0.5))
        }
        .background(colorScheme.backgroundColor)
    }
}
```

---

## 5. 标签过滤小组件（TagFilterWidget）

### 5.1 TagFilterWidget.swift

```swift
// ios/PlanbookWidgets/TagFilterWidget/TagFilterWidget.swift

import WidgetKit
import SwiftUI

struct TagFilterWidget: Widget {
    let kind: String = "TagFilterWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TagFilterIntent.self,
            provider: TagFilterWidgetProvider()
        ) { entry in
            TagFilterWidgetView(entry: entry)
        }
        .configurationDisplayName("标签任务")
        .description("按标签筛选查看任务")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// App Intent for configuration
struct TagFilterIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "选择标签"
    static var description: IntentDescription = "选择要显示的标签"
    
    @Parameter(title: "标签")
    var selectedTag: String?
    
    init() {}
    
    init(selectedTag: String) {
        self.selectedTag = selectedTag
    }
}

#Preview(as: .systemSmall) {
    TagFilterWidget()
} timeline: {
    TagFilterWidgetEntry(
        date: .now,
        tag: WidgetTag(id: "1", name: "工作", color: "#2196F3"),
        tasks: WidgetTask.sampleTasks,
        themeConfig: WidgetThemeConfig(themeId: "blue", isDarkMode: false, priorityColors: nil)
    )
}

#Preview(as: .systemMedium) {
    TagFilterWidget()
} timeline: {
    TagFilterWidgetEntry(
        date: .now,
        tag: WidgetTag(id: "1", name: "工作", color: "#2196F3"),
        tasks: WidgetTask.sampleTasks,
        themeConfig: WidgetThemeConfig(themeId: "blue", isDarkMode: false, priorityColors: nil)
    )
}
```

### 5.2 TagFilterWidgetProvider.swift

```swift
// ios/PlanbookWidgets/TagFilterWidget/TagFilterWidgetProvider.swift

import WidgetKit
import AppIntents

struct TagFilterWidgetEntry: TimelineEntry {
    let date: Date
    let tag: WidgetTag?
    let tasks: [WidgetTask]
    let themeConfig: WidgetThemeConfig
}

struct TagFilterWidgetProvider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> TagFilterWidgetEntry {
        TagFilterWidgetEntry(
            date: Date(),
            tag: WidgetTag(id: "1", name: "工作", color: "#2196F3"),
            tasks: WidgetTask.sampleTasks,
            themeConfig: WidgetThemeConfig(themeId: "blue", isDarkMode: false, priorityColors: nil)
        )
    }
    
    func snapshot(for configuration: TagFilterIntent, in context: Context) async -> TagFilterWidgetEntry {
        let data = WidgetDataProvider.shared.loadWidgetData()
        
        // 从配置中获取选中的标签
        let selectedTagId = configuration.selectedTag
        let selectedTag = data?.todayTasks.flatMap { $0.tags }.first { $0.id == selectedTagId }
            ?? WidgetTag(id: "1", name: "工作", color: "#2196F3")
        
        // 过滤任务
        let filteredTasks = data?.todayTasks.filter { task in
            task.tags.contains { $0.id == selectedTagId }
        } ?? WidgetTask.sampleTasks
        
        return TagFilterWidgetEntry(
            date: Date(),
            tag: selectedTag,
            tasks: filteredTasks,
            themeConfig: data?.themeConfig ?? WidgetThemeConfig(themeId: "blue", isDarkMode: false, priorityColors: nil)
        )
    }
    
    func timeline(for configuration: TagFilterIntent, in context: Context) async -> Timeline<TagFilterWidgetEntry> {
        let entry = await snapshot(for: configuration, in: context)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}
```

### 5.3 TagFilterWidgetView.swift

```swift
// ios/PlanbookWidgets/TagFilterWidget/TagFilterWidgetView.swift

import SwiftUI
import WidgetKit

struct TagFilterWidgetView: View {
    var entry: TagFilterWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        let colorScheme = WidgetThemeManager.getColorScheme(from: entry.themeConfig)
        let tagColor = entry.tag?.color.flatMap { Color(hex: $0) } ?? colorScheme.primaryColor
        
        switch family {
        case .systemSmall:
            TagFilterSmallView(entry: entry, colorScheme: colorScheme, tagColor: tagColor)
        case .systemMedium:
            TagFilterMediumView(entry: entry, colorScheme: colorScheme, tagColor: tagColor)
        default:
            TagFilterSmallView(entry: entry, colorScheme: colorScheme, tagColor: tagColor)
        }
    }
}

// MARK: - Small

struct TagFilterSmallView: View {
    let entry: TagFilterWidgetEntry
    let colorScheme: AppColorScheme
    let tagColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            // Tag Icon
            ZStack {
                Circle()
                    .fill(tagColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "tag.fill")
                    .font(.system(size: 20))
                    .foregroundColor(tagColor)
            }
            
            // Tag Name
            Text(entry.tag?.name ?? "标签")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(colorScheme.labelColor)
                .lineLimit(1)
            
            // Task Count
            let completed = entry.tasks.filter { $0.isCompleted }.count
            let total = entry.tasks.count
            Text("\(completed)/\(total)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(tagColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme.backgroundColor)
    }
}

// MARK: - Medium

struct TagFilterMediumView: View {
    let entry: TagFilterWidgetEntry
    let colorScheme: AppColorScheme
    let tagColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .foregroundColor(tagColor)
                    Text(entry.tag?.name ?? "标签")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(colorScheme.labelColor)
                
                Spacer()
                
                let completed = entry.tasks.filter { $0.isCompleted }.count
                let total = entry.tasks.count
                Text("\(completed)/\(total)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(tagColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(tagColor.opacity(0.12))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(colorScheme.secondaryBackgroundColor)
            
            Divider()
                .background(colorScheme.outlineColor)
            
            // Task List
            if entry.tasks.isEmpty {
                VStack(spacing: 4) {
                    Text("该标签暂无任务")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme.secondaryLabelColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entry.tasks.prefix(4).enumerated()), id: \.element.id) { index, task in
                        HStack(spacing: 10) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundColor(task.isCompleted ? Color.green : tagColor)
                            
                            Text(task.title)
                                .font(.system(size: 14))
                                .lineLimit(1)
                                .strikethrough(task.isCompleted, color: colorScheme.secondaryLabelColor)
                                .foregroundColor(task.isCompleted ? colorScheme.secondaryLabelColor : colorScheme.labelColor)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        
                        if index < min(entry.tasks.count, 4) - 1 {
                            Divider()
                                .padding(.leading, 40)
                                .background(colorScheme.outlineColor)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .background(colorScheme.backgroundColor)
    }
}
```

---

## 6. 快速记录小组件（QuickCaptureWidget）

### 6.1 QuickCaptureWidget.swift

```swift
// ios/PlanbookWidgets/QuickCaptureWidget/QuickCaptureWidget.swift

import WidgetKit
import SwiftUI

struct QuickCaptureWidget: Widget {
    let kind: String = "QuickCaptureWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickCaptureWidgetProvider()) { entry in
            QuickCaptureWidgetView(entry: entry)
        }
        .configurationDisplayName("快速记录")
        .description("快速添加任务或笔记")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    QuickCaptureWidget()
} timeline: {
    QuickCaptureWidgetEntry(
        date: .now,
        themeConfig: WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
    )
}

#Preview(as: .systemMedium) {
    QuickCaptureWidget()
} timeline: {
    QuickCaptureWidgetEntry(
        date: .now,
        themeConfig: WidgetThemeConfig(themeId: "green", isDarkMode: false, priorityColors: nil)
    )
}
```

### 6.2 QuickCaptureWidgetProvider.swift

```swift
// ios/PlanbookWidgets/QuickCaptureWidget/QuickCaptureWidgetProvider.swift

import WidgetKit

struct QuickCaptureWidgetEntry: TimelineEntry {
    let date: Date
    let themeConfig: WidgetThemeConfig
}

struct QuickCaptureWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> QuickCaptureWidgetEntry {
        QuickCaptureWidgetEntry(
            date: Date(),
            themeConfig: WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickCaptureWidgetEntry) -> Void) {
        let data = WidgetDataProvider.shared.loadWidgetData()
        let entry = QuickCaptureWidgetEntry(
            date: Date(),
            themeConfig: data?.themeConfig ?? WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickCaptureWidgetEntry>) -> Void) {
        getSnapshot(in: context) { entry in
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}
```

### 6.3 QuickCaptureWidgetView.swift

```swift
// ios/PlanbookWidgets/QuickCaptureWidget/QuickCaptureWidgetView.swift

import SwiftUI
import WidgetKit

struct QuickCaptureWidgetView: View {
    var entry: QuickCaptureWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        let colorScheme = WidgetThemeManager.getColorScheme(from: entry.themeConfig)
        
        switch family {
        case .systemSmall:
            QuickCaptureSmallView(colorScheme: colorScheme)
        case .systemMedium:
            QuickCaptureMediumView(colorScheme: colorScheme)
        default:
            QuickCaptureSmallView(colorScheme: colorScheme)
        }
    }
}

// MARK: - Small

struct QuickCaptureSmallView: View {
    let colorScheme: AppColorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(colorScheme.primaryColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(colorScheme.primaryColor)
            }
            
            Text("快速记录")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(colorScheme.labelColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme.backgroundColor)
    }
}

// MARK: - Medium

struct QuickCaptureMediumView: View {
    let colorScheme: AppColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(colorScheme.primaryColor)
                    Text("快速记录")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(colorScheme.labelColor)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(colorScheme.secondaryBackgroundColor)
            
            Divider()
                .background(colorScheme.outlineColor)
            
            // Input Area
            VStack(spacing: 12) {
                // Text Input Placeholder
                HStack {
                    Text("输入想法、任务或笔记...")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme.tertiaryLabelColor)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(colorScheme.tertiaryBackgroundColor)
                .cornerRadius(8)
                .padding(.horizontal, 12)
                
                // Action Buttons
                HStack(spacing: 12) {
                    QuickActionButton(
                        icon: "checklist",
                        title: "任务",
                        color: colorScheme.primaryColor,
                        colorScheme: colorScheme
                    )
                    
                    QuickActionButton(
                        icon: "note.text",
                        title: "笔记",
                        color: colorScheme.primaryColor,
                        colorScheme: colorScheme
                    )
                    
                    QuickActionButton(
                        icon: "lightbulb",
                        title: "想法",
                        color: colorScheme.primaryColor,
                        colorScheme: colorScheme
                    )
                }
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 12)
            
            Spacer()
        }
        .background(colorScheme.backgroundColor)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let colorScheme: AppColorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(colorScheme.secondaryLabelColor)
        }
        .frame(maxWidth: .infinity)
    }
}
```

---

## 7. Widget Bundle（更新版）

```swift
// ios/PlanbookWidgets/PlanbookWidgetsBundle.swift

import WidgetKit
import SwiftUI

@main
struct PlanbookWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        QuadrantWidget()
        InboxWidget()
        TagFilterWidget()
        QuickCaptureWidget()
    }
}
```

---

## 8. Flutter 端同步服务（完整版）

```dart
// lib/services/ios_widget_sync_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:home_widget/home_widget.dart';

class IOSWidgetSyncService {
  static const _appGroupId = 'group.GM4766U38W.com.bapaws.habits';
  
  // Keys
  static const _widgetDataKey = 'widget_data';
  static const _themeIdKey = 'widget_theme_id';
  static const _isDarkModeKey = 'widget_is_dark_mode';
  
  /// 初始化
  static Future<void> initialize() async {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(_appGroupId);
    }
  }
  
  /// 同步所有数据
  static Future<void> syncAll({
    required List<Map<String, dynamic>> todayTasks,
    required List<Map<String, dynamic>> inboxTasks,
    required Map<String, int> quadrantCounts,
    required String themeId,
    required bool isDarkMode,
  }) async {
    if (!Platform.isIOS) return;
    
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'todayTasks': todayTasks,
      'inboxTasks': inboxTasks,
      'quadrantCounts': quadrantCounts,
      'themeConfig': {
        'themeId': themeId,
        'isDarkMode': isDarkMode,
      },
    };
    
    await HomeWidget.saveWidgetData(_widgetDataKey, jsonEncode(data));
    await HomeWidget.saveWidgetData(_themeIdKey, themeId);
    await HomeWidget.saveWidgetData(_isDarkModeKey, isDarkMode);
    
    await _reloadAllWidgets();
  }
  
  /// 同步主题
  static Future<void> syncTheme({
    required String themeId,
    required bool isDarkMode,
  }) async {
    if (!Platform.isIOS) return;
    
    await HomeWidget.saveWidgetData(_themeIdKey, themeId);
    await HomeWidget.saveWidgetData(_isDarkModeKey, isDarkMode);
    await _reloadAllWidgets();
  }
  
  /// 刷新所有小组件
  static Future<void> _reloadAllWidgets() async {
    await HomeWidget.updateWidget(iOSName: 'TodayWidget');
    await HomeWidget.updateWidget(iOSName: 'QuadrantWidget');
    await HomeWidget.updateWidget(iOSName: 'InboxWidget');
    await HomeWidget.updateWidget(iOSName: 'TagFilterWidget');
    await HomeWidget.updateWidget(iOSName: 'QuickCaptureWidget');
  }
  
  /// 测试数据
  static Future<void> sendTestData() async {
    await syncAll(
      todayTasks: [
        {'id': '1', 'title': '完成项目汇报', 'isCompleted': false, 'priority': 'high', 'dueAt': DateTime.now().toIso8601String(), 'tags': []},
        {'id': '2', 'title': '回复客户邮件', 'isCompleted': false, 'priority': 'medium', 'dueAt': DateTime.now().toIso8601String(), 'tags': []},
        {'id': '3', 'title': '团队周会', 'isCompleted': true, 'priority': 'medium', 'dueAt': DateTime.now().toIso8601String(), 'tags': []},
        {'id': '4', 'title': '阅读技术文档', 'isCompleted': false, 'priority': 'low', 'dueAt': DateTime.now().toIso8601String(), 'tags': []},
      ],
      inboxTasks: [
        {'id': '5', 'title': '学习 Flutter 新特性', 'isCompleted': false, 'priority': 'none', 'dueAt': null, 'tags': []},
        {'id': '6', 'title': '购买办公用品', 'isCompleted': false, 'priority': 'none', 'dueAt': null, 'tags': []},
      ],
      quadrantCounts: {
        'importantUrgent': 2,
        'importantNotUrgent': 3,
        'urgentUnimportant': 1,
        'notUrgentUnimportant': 0,
      },
      themeId: 'blue',
      isDarkMode: false,
    );
  }
}
```

---

## 9. 测试指南

### 9.1 添加小组件到主屏幕

1. 构建运行 App 到 iPhone 模拟器
2. 回到主屏幕，长按空白处
3. 点击左上角的 **+** 按钮
4. 找到 "Planbook"，选择要添加的小组件：
   - 今天任务（Small/Medium/Large）
   - 四象限（Medium/Large）
   - 收集箱（Small/Medium）
   - 标签任务（Small/Medium）
   - 快速记录（Small/Medium）

### 9.2 测试数据推送

在 App 中添加调试按钮：

```dart
ElevatedButton(
  onPressed: () => IOSWidgetSyncService.sendTestData(),
  child: Text('推送测试数据到小组件'),
),
```

### 9.3 预期效果

| 小组件 | Small | Medium | Large |
|--------|-------|--------|-------|
| 今天任务 | 进度圆环 | 4个任务列表 | 8个任务列表 |
| 四象限 | - | 四个数字格 | 四个列表 |
| 收集箱 | 任务数量 | 3个任务列表 | - |
| 标签任务 | 标签名+数量 | 任务列表 | - |
| 快速记录 | +按钮 | 输入框+按钮 | - |
