# iOS Today Widget 实现指南

## 第一步：Xcode 项目设置

### 1.1 添加 Widget Extension

在 Xcode 中：
1. 打开 `ios/Runner.xcworkspace`
2. File → New → Target
3. 选择 **Widget Extension**
4. 填写信息：
   - Product Name: `PlanbookWidgets`
   - Team: 选择你的开发团队
   - Include Configuration Intent: **取消勾选**（我们使用 Static Configuration）

### 1.2 启用 App Groups

```
1. 选择 Runner target → Signing & Capabilities
2. 点击 + Capability
3. 添加 App Groups
4. 点击 + 添加新的 group: group.GM4766U38W.com.bapaws.habits

5. 选择 PlanbookWidgets target
6. 同样添加 App Groups，选择相同的 group
```

### 1.3 项目结构

```
ios/
├── Runner/
│   └── ...
├── PlanbookWidgets/
│   ├── PlanbookWidgetsBundle.swift      # Widget Bundle 入口
│   ├── TodayWidget/
│   │   ├── TodayWidget.swift            # 今天任务小组件
│   │   ├── TodayWidgetView.swift        # 视图组件
│   │   └── TodayWidgetProvider.swift    # 数据提供器
│   ├── Models/
│   │   ├── WidgetModels.swift           # 数据模型
│   │   └── WidgetTheme.swift            # 主题配色方案
│   ├── Utils/
│   │   ├── WidgetDataProvider.swift     # 数据读取工具
│   │   └── ColorExtensions.swift        # 颜色扩展
│   └── Assets.xcassets/
└── ...
```

---

## 第二步：创建数据模型

### 2.1 WidgetModels.swift

```swift
// ios/PlanbookWidgets/Models/WidgetModels.swift

import Foundation

// MARK: - 任务模型

struct WidgetTask: Codable, Identifiable {
    let id: String
    let title: String
    let isCompleted: Bool
    let priority: TaskPriority
    let dueAt: Date?
    let tags: [WidgetTag]
    
    enum TaskPriority: String, Codable {
        case high = "high"       // 重要且紧急
        case medium = "medium"   // 重要不紧急
        case low = "low"         // 紧急不重要
        case none = "none"       // 不紧急不重要
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

// MARK: - 小组件数据容器

struct WidgetDataContainer: Codable {
    let timestamp: Date
    let todayTasks: [WidgetTask]
    let completedCount: Int
    let totalCount: Int
    let themeConfig: WidgetThemeConfig
}

// MARK: - 预览数据

extension WidgetTask {
    static let sampleTasks: [WidgetTask] = [
        WidgetTask(
            id: "1",
            title: "完成项目汇报",
            isCompleted: false,
            priority: .high,
            dueAt: Date(),
            tags: []
        ),
        WidgetTask(
            id: "2",
            title: "回复客户邮件",
            isCompleted: false,
            priority: .medium,
            dueAt: Date(),
            tags: []
        ),
        WidgetTask(
            id: "3",
            title: "团队周会",
            isCompleted: true,
            priority: .medium,
            dueAt: Date(),
            tags: []
        ),
        WidgetTask(
            id: "4",
            title: "阅读技术文档",
            isCompleted: false,
            priority: .low,
            dueAt: Date(),
            tags: []
        )
    ]
}
```

### 2.2 WidgetTheme.swift（内置配色方案）

```swift
// ios/PlanbookWidgets/Models/WidgetTheme.swift

import SwiftUI

// MARK: - 主题ID

enum ThemeId: String, CaseIterable {
    case red = "red"
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    case orange = "orange"
    case pink = "pink"
    case teal = "teal"
    case indigo = "indigo"
    case brown = "brown"
    case gray = "gray"
}

// MARK: - 颜色方案

struct AppColorScheme {
    let primary: String
    let label: String
    let secondaryLabel: String
    let tertiaryLabel: String
    let quaternaryLabel: String
    let background: String
    let secondaryBackground: String
    let tertiaryBackground: String
    let quaternaryBackground: String
    let shadow: String
    let outline: String
    
    // 便利属性
    var primaryColor: Color { Color(hex: primary) }
    var labelColor: Color { Color(hex: label) }
    var secondaryLabelColor: Color { Color(hex: secondaryLabel) }
    var tertiaryLabelColor: Color { Color(hex: tertiaryLabel) }
    var quaternaryLabelColor: Color { Color(hex: quaternaryLabel) }
    var backgroundColor: Color { Color(hex: background) }
    var secondaryBackgroundColor: Color { Color(hex: secondaryBackground) }
    var tertiaryBackgroundColor: Color { Color(hex: tertiaryBackground) }
    var quaternaryBackgroundColor: Color { Color(hex: quaternaryBackground) }
    var shadowColor: Color { Color(hex: shadow) }
    var outlineColor: Color { Color(hex: outline) }
}

// MARK: - 主题对（亮色/暗色）

struct ThemePair {
    let light: AppColorScheme
    let dark: AppColorScheme
}

// MARK: - 优先级颜色

struct PriorityColors {
    let importantUrgent: String
    let importantNotUrgent: String
    let urgentUnimportant: String
    let notUrgentUnimportant: String
    
    static let `default` = PriorityColors(
        importantUrgent: "#FF4444",
        importantNotUrgent: "#FFBB33",
        urgentUnimportant: "#FF8800",
        notUrgentUnimportant: "#9E9E9E"
    )
    
    var importantUrgentColor: Color { Color(hex: importantUrgent) }
    var importantNotUrgentColor: Color { Color(hex: importantNotUrgent) }
    var urgentUnimportantColor: Color { Color(hex: urgentUnimportant) }
    var notUrgentUnimportantColor: Color { Color(hex: notUrgentUnimportant) }
}

// MARK: - 主题管理器

struct WidgetThemeManager {
    
    // MARK: - 内置配色方案
    
    static let themes: [ThemeId: ThemePair] = [
        .red: ThemePair(
            light: AppColorScheme(
                primary: "#F44336",
                label: "#181818",
                secondaryLabel: "#414144",
                tertiaryLabel: "#71717A",
                quaternaryLabel: "#A1A1AA",
                background: "#FFFFFF",
                secondaryBackground: "#F4F4F5",
                tertiaryBackground: "#E4E4E7",
                quaternaryBackground: "#D4D4D8",
                shadow: "#000000",
                outline: "#E4E4E7"
            ),
            dark: AppColorScheme(
                primary: "#F44336",
                label: "#FFFFFF",
                secondaryLabel: "#E4E4E7",
                tertiaryLabel: "#D4D4D8",
                quaternaryLabel: "#C4C4C4",
                background: "#000000",
                secondaryBackground: "#181818",
                tertiaryBackground: "#282828",
                quaternaryBackground: "#383838",
                shadow: "#000000",
                outline: "#E4E4E7"
            )
        ),
        
        .blue: ThemePair(
            light: AppColorScheme(
                primary: "#2196F3",
                label: "#181818",
                secondaryLabel: "#414144",
                tertiaryLabel: "#71717A",
                quaternaryLabel: "#A1A1AA",
                background: "#FFFFFF",
                secondaryBackground: "#F4F4F5",
                tertiaryBackground: "#E4E4E7",
                quaternaryBackground: "#D4D4D8",
                shadow: "#000000",
                outline: "#E4E4E7"
            ),
            dark: AppColorScheme(
                primary: "#64B5F6",
                label: "#FFFFFF",
                secondaryLabel: "#E4E4E7",
                tertiaryLabel: "#D4D4D8",
                quaternaryLabel: "#C4C4C4",
                background: "#000000",
                secondaryBackground: "#181818",
                tertiaryBackground: "#282828",
                quaternaryBackground: "#383838",
                shadow: "#000000",
                outline: "#E4E4E7"
            )
        ),
        
        .green: ThemePair(
            light: AppColorScheme(
                primary: "#4CAF50",
                label: "#181818",
                secondaryLabel: "#414144",
                tertiaryLabel: "#71717A",
                quaternaryLabel: "#A1A1AA",
                background: "#FFFFFF",
                secondaryBackground: "#F4F4F5",
                tertiaryBackground: "#E4E4E7",
                quaternaryBackground: "#D4D4D8",
                shadow: "#000000",
                outline: "#E4E4E7"
            ),
            dark: AppColorScheme(
                primary: "#81C784",
                label: "#FFFFFF",
                secondaryLabel: "#E4E4E7",
                tertiaryLabel: "#D4D4D8",
                quaternaryLabel: "#C4C4C4",
                background: "#000000",
                secondaryBackground: "#181818",
                tertiaryBackground: "#282828",
                quaternaryBackground: "#383838",
                shadow: "#000000",
                outline: "#E4E4E7"
            )
        ),
        
        .purple: ThemePair(
            light: AppColorScheme(
                primary: "#9C27B0",
                label: "#181818",
                secondaryLabel: "#414144",
                tertiaryLabel: "#71717A",
                quaternaryLabel: "#A1A1AA",
                background: "#FFFFFF",
                secondaryBackground: "#F4F4F5",
                tertiaryBackground: "#E4E4E7",
                quaternaryBackground: "#D4D4D8",
                shadow: "#000000",
                outline: "#E4E4E7"
            ),
            dark: AppColorScheme(
                primary: "#BA68C8",
                label: "#FFFFFF",
                secondaryLabel: "#E4E4E7",
                tertiaryLabel: "#D4D4D8",
                quaternaryLabel: "#C4C4C4",
                background: "#000000",
                secondaryBackground: "#181818",
                tertiaryBackground: "#282828",
                quaternaryBackground: "#383838",
                shadow: "#000000",
                outline: "#E4E4E7"
            )
        ),
        
        .orange: ThemePair(
            light: AppColorScheme(
                primary: "#FF9800",
                label: "#181818",
                secondaryLabel: "#414144",
                tertiaryLabel: "#71717A",
                quaternaryLabel: "#A1A1AA",
                background: "#FFFFFF",
                secondaryBackground: "#F4F4F5",
                tertiaryBackground: "#E4E4E7",
                quaternaryBackground: "#D4D4D8",
                shadow: "#000000",
                outline: "#E4E4E7"
            ),
            dark: AppColorScheme(
                primary: "#FFB74D",
                label: "#FFFFFF",
                secondaryLabel: "#E4E4E7",
                tertiaryLabel: "#D4D4D8",
                quaternaryLabel: "#C4C4C4",
                background: "#000000",
                secondaryBackground: "#181818",
                tertiaryBackground: "#282828",
                quaternaryBackground: "#383838",
                shadow: "#000000",
                outline: "#E4E4E7"
            )
        ),
        
        .pink: ThemePair(
            light: AppColorScheme(
                primary: "#E91E63",
                label: "#181818",
                secondaryLabel: "#414144",
                tertiaryLabel: "#71717A",
                quaternaryLabel: "#A1A1AA",
                background: "#FFFFFF",
                secondaryBackground: "#F4F4F5",
                tertiaryBackground: "#E4E4E7",
                quaternaryBackground: "#D4D4D8",
                shadow: "#000000",
                outline: "#E4E4E7"
            ),
            dark: AppColorScheme(
                primary: "#F06292",
                label: "#FFFFFF",
                secondaryLabel: "#E4E4E7",
                tertiaryLabel: "#D4D4D8",
                quaternaryLabel: "#C4C4C4",
                background: "#000000",
                secondaryBackground: "#181818",
                tertiaryBackground: "#282828",
                quaternaryBackground: "#383838",
                shadow: "#000000",
                outline: "#E4E4E7"
            )
        )
    ]
    
    // MARK: - 获取颜色方案
    
    static func getColorScheme(themeId: String, isDarkMode: Bool) -> AppColorScheme {
        let id = ThemeId(rawValue: themeId) ?? .red
        let pair = themes[id] ?? themes[.red]!
        return isDarkMode ? pair.dark : pair.light
    }
    
    static func getColorScheme(from config: WidgetThemeConfig) -> AppColorScheme {
        return getColorScheme(themeId: config.themeId, isDarkMode: config.isDarkMode)
    }
    
    // MARK: - 获取优先级颜色
    
    static func getPriorityColors(from config: WidgetThemeConfig) -> PriorityColors {
        if let custom = config.priorityColors {
            return PriorityColors(
                importantUrgent: custom.importantUrgent,
                importantNotUrgent: custom.importantNotUrgent,
                urgentUnimportant: custom.urgentUnimportant,
                notUrgentUnimportant: custom.notUrgentUnimportant
            )
        }
        return .default
    }
}
```

---

## 第三步：工具类

### 3.1 ColorExtensions.swift

```swift
// ios/PlanbookWidgets/Utils/ColorExtensions.swift

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

### 3.2 WidgetDataProvider.swift

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
    
    // MARK: - 读取数据
    
    func loadWidgetData() -> WidgetDataContainer? {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return nil
        }
        
        // 读取主题配置
        let themeId = defaults.string(forKey: themeIdKey) ?? "red"
        let isDarkMode = defaults.bool(forKey: isDarkModeKey)
        
        let themeConfig = WidgetThemeConfig(
            themeId: themeId,
            isDarkMode: isDarkMode,
            priorityColors: nil
        )
        
        // 尝试读取完整数据
        if let jsonString = defaults.string(forKey: widgetDataKey),
           let jsonData = jsonString.data(using: .utf8),
           var container = try? JSONDecoder().decode(WidgetDataContainer.self, from: jsonData) {
            // 更新主题配置（因为可能单独更新了主题）
            let updatedContainer = WidgetDataContainer(
                timestamp: container.timestamp,
                todayTasks: container.todayTasks,
                completedCount: container.completedCount,
                totalCount: container.totalCount,
                themeConfig: themeConfig
            )
            return updatedContainer
        }
        
        // 返回默认数据
        return WidgetDataContainer(
            timestamp: Date(),
            todayTasks: WidgetTask.sampleTasks,
            completedCount: 1,
            totalCount: 4,
            themeConfig: themeConfig
        )
    }
    
    func loadThemeConfig() -> WidgetThemeConfig {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
        }
        
        let themeId = defaults.string(forKey: themeIdKey) ?? "red"
        let isDarkMode = defaults.bool(forKey: isDarkModeKey)
        
        return WidgetThemeConfig(
            themeId: themeId,
            isDarkMode: isDarkMode,
            priorityColors: nil
        )
    }
    
    // MARK: - 触发刷新
    
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

---

## 第四步：Today Widget 实现

### 4.1 TodayWidgetEntry.swift

```swift
// ios/PlanbookWidgets/TodayWidget/TodayWidgetEntry.swift

import WidgetKit

struct TodayWidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let completedCount: Int
    let totalCount: Int
    let themeConfig: WidgetThemeConfig
}
```

### 4.2 TodayWidgetProvider.swift

```swift
// ios/PlanbookWidgets/TodayWidget/TodayWidgetProvider.swift

import WidgetKit

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
            completedCount: data?.completedCount ?? 0,
            totalCount: data?.totalCount ?? 0,
            themeConfig: data?.themeConfig ?? WidgetThemeConfig(themeId: "red", isDarkMode: false, priorityColors: nil)
        )
        
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWidgetEntry>) -> Void) {
        getSnapshot(in: context) { entry in
            // 每 15 分钟刷新一次
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}
```

### 4.3 TodayWidgetView.swift

```swift
// ios/PlanbookWidgets/TodayWidget/TodayWidgetView.swift

import SwiftUI
import WidgetKit

struct TodayWidgetView: View {
    var entry: TodayWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        let colorScheme = WidgetThemeManager.getColorScheme(from: entry.themeConfig)
        let priorityColors = WidgetThemeManager.getPriorityColors(from: entry.themeConfig)
        
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

// MARK: - Small Size

struct TodaySmallView: View {
    let entry: TodayWidgetEntry
    let colorScheme: AppColorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // 图标和标题
            Image(systemName: "checklist")
                .font(.system(size: 32))
                .foregroundColor(colorScheme.primaryColor)
            
            // 完成进度
            Text("\(entry.completedCount)/\(entry.totalCount)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(colorScheme.labelColor)
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorScheme.tertiaryBackgroundColor)
                        .frame(height: 4)
                    
                    if entry.totalCount > 0 {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorScheme.primaryColor)
                            .frame(
                                width: geometry.size.width * CGFloat(entry.completedCount) / CGFloat(entry.totalCount),
                                height: 4
                            )
                    }
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 16)
            
            Text("今天待办")
                .font(.caption)
                .foregroundColor(colorScheme.secondaryLabelColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme.backgroundColor)
    }
}

// MARK: - Medium Size

struct TodayMediumView: View {
    let entry: TodayWidgetEntry
    let colorScheme: AppColorScheme
    let priorityColors: PriorityColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 头部
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
            
            // 分割线
            Divider()
                .background(colorScheme.outlineColor)
            
            // 任务列表
            if entry.tasks.isEmpty {
                EmptyTaskView(colorScheme: colorScheme)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entry.tasks.prefix(4).enumerated()), id: \.element.id) { index, task in
                        TaskRowView(
                            task: task,
                            colorScheme: colorScheme,
                            priorityColors: priorityColors
                        )
                        
                        if index < min(entry.tasks.count, 4) - 1 {
                            Divider()
                                .padding(.leading, 40)
                                .background(colorScheme.outlineColor.opacity(0.5))
                        }
                    }
                }
            }
            
            Spacer()
        }
        .background(colorScheme.backgroundColor)
    }
}

// MARK: - Large Size

struct TodayLargeView: View {
    let entry: TodayWidgetEntry
    let colorScheme: AppColorScheme
    let priorityColors: PriorityColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 头部（与 Medium 相同）
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
            
            // 更多任务的列表
            if entry.tasks.isEmpty {
                EmptyTaskView(colorScheme: colorScheme)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entry.tasks.prefix(8).enumerated()), id: \.element.id) { index, task in
                        TaskRowView(
                            task: task,
                            colorScheme: colorScheme,
                            priorityColors: priorityColors
                        )
                        
                        if index < min(entry.tasks.count, 8) - 1 {
                            Divider()
                                .padding(.leading, 40)
                                .background(colorScheme.outlineColor.opacity(0.5))
                        }
                    }
                }
            }
            
            Spacer()
        }
        .background(colorScheme.backgroundColor)
    }
}

// MARK: - 子视图

struct TaskRowView: View {
    let task: WidgetTask
    let colorScheme: AppColorScheme
    let priorityColors: PriorityColors
    
    var body: some View {
        HStack(spacing: 10) {
            // 完成状态圆圈
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(task.isCompleted ? Color.green : priorityColor)
                .frame(width: 24)
            
            // 任务标题
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
        case .high:
            return priorityColors.importantUrgentColor
        case .medium:
            return priorityColors.importantNotUrgentColor
        case .low:
            return priorityColors.urgentUnimportantColor
        case .none:
            return priorityColors.notUrgentUnimportantColor
        }
    }
}

struct EmptyTaskView: View {
    let colorScheme: AppColorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(colorScheme.tertiaryLabelColor)
            
            Text("今天没有任务")
                .font(.system(size: 14))
                .foregroundColor(colorScheme.secondaryLabelColor)
            
            Text("好好休息一下吧")
                .font(.system(size: 12))
                .foregroundColor(colorScheme.tertiaryLabelColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

### 4.4 TodayWidget.swift（Widget 配置）

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

// MARK: - 预览

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

#Preview(as: .systemLarge) {
    TodayWidget()
} timeline: {
    TodayWidgetEntry(
        date: .now,
        tasks: WidgetTask.sampleTasks,
        completedCount: 1,
        totalCount: 4,
        themeConfig: WidgetThemeConfig(themeId: "green", isDarkMode: false, priorityColors: nil)
    )
}
```

---

## 第五步：Widget Bundle

```swift
// ios/PlanbookWidgets/PlanbookWidgetsBundle.swift

import WidgetKit
import SwiftUI

@main
struct PlanbookWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        // 后续添加更多小组件：
        // QuadrantWidget()
        // InboxWidget()
        // ...
    }
}
```

---

## 第六步：Flutter 端数据推送

### 6.1 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  home_widget: ^0.9.0
```

### 6.2 初始化（main.dart）

```dart
import 'package:home_widget/home_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置 App Group ID（iOS 必需）
  if (Platform.isIOS) {
    await HomeWidget.setAppGroupId('group.GM4766U38W.com.bapaws.habits');
  }
  
  runApp(const App());
}
```

### 6.3 同步服务

```dart
// lib/services/ios_widget_sync_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:home_widget/home_widget.dart';

class IOSWidgetSyncService {
  static const _appGroupId = 'group.GM4766U38W.com.bapaws.habits';
  static const _widgetDataKey = 'widget_data';
  static const _themeIdKey = 'widget_theme_id';
  static const _isDarkModeKey = 'widget_is_dark_mode';
  
  /// 初始化
  static Future<void> initialize() async {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(_appGroupId);
    }
  }
  
  /// 同步任务数据到小组件
  static Future<void> syncTasks({
    required List<Map<String, dynamic>> tasks,
    required int completedCount,
    required int totalCount,
  }) async {
    if (!Platform.isIOS) return;
    
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'todayTasks': tasks,
      'completedCount': completedCount,
      'totalCount': totalCount,
    };
    
    await HomeWidget.saveWidgetData(_widgetDataKey, jsonEncode(data));
    await _reloadWidgets();
  }
  
  /// 同步主题配置
  static Future<void> syncTheme({
    required String themeId,
    required bool isDarkMode,
  }) async {
    if (!Platform.isIOS) return;
    
    await HomeWidget.saveWidgetData(_themeIdKey, themeId);
    await HomeWidget.saveWidgetData(_isDarkModeKey, isDarkMode);
    await _reloadWidgets();
  }
  
  /// 刷新小组件
  static Future<void> _reloadWidgets() async {
    await HomeWidget.updateWidget(
      iOSName: 'TodayWidget',
    );
  }
  
  /// 测试数据（开发时使用）
  static Future<void> sendTestData() async {
    final testTasks = [
      {
        'id': '1',
        'title': '完成项目汇报',
        'isCompleted': false,
        'priority': 'high',
        'dueAt': DateTime.now().toIso8601String(),
        'tags': [],
      },
      {
        'id': '2',
        'title': '回复客户邮件',
        'isCompleted': false,
        'priority': 'medium',
        'dueAt': DateTime.now().toIso8601String(),
        'tags': [],
      },
      {
        'id': '3',
        'title': '团队周会',
        'isCompleted': true,
        'priority': 'medium',
        'dueAt': DateTime.now().toIso8601String(),
        'tags': [],
      },
    ];
    
    await syncTasks(
      tasks: testTasks,
      completedCount: 1,
      totalCount: 3,
    );
    
    await syncTheme(themeId: 'blue', isDarkMode: false);
  }
}
```

### 6.4 在设置页面添加测试按钮

```dart
// lib/settings/view/settings_page.dart

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ... 其他设置项
          
          if (Platform.isIOS) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.widgets),
              title: const Text('刷新小组件'),
              subtitle: const Text('同步数据到 iOS 小组件'),
              onTap: () async {
                await IOSWidgetSyncService.sendTestData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('小组件数据已同步')),
                );
              },
            ),
            
            // 切换主题测试
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('切换小组件主题'),
              onTap: () async {
                final themes = ['red', 'blue', 'green', 'purple', 'orange'];
                final currentTheme = await HomeWidget.getWidgetData<String>('widget_theme_id');
                final currentIndex = themes.indexOf(currentTheme ?? 'red');
                final nextTheme = themes[(currentIndex + 1) % themes.length];
                
                await IOSWidgetSyncService.syncTheme(
                  themeId: nextTheme,
                  isDarkMode: false,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('主题已切换到: $nextTheme')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## 第七步：构建和测试

### 7.1 构建步骤

```bash
# 1. 获取依赖
flutter pub get

# 2. 构建 iOS
cd ios
pod install

# 3. 打开 Xcode
open Runner.xcworkspace
```

### 7.2 Xcode 配置检查清单

- [ ] App Groups 已启用（Runner 和 PlanbookWidgets）
- [ ] Group ID: `group.GM4766U38W.com.bapaws.habits`
- [ ] Signing & Capabilities 配置正确
- [ ] Deployment Target: iOS 17.0+

### 7.3 运行测试

1. 在 Xcode 中选择 **Runner** scheme，运行到 iPhone 模拟器
2. 回到主屏幕，长按空白处进入编辑模式
3. 点击左上角的 **+** 按钮
4. 找到 "Planbook"，选择 "今天任务" 小组件
5. 选择尺寸（Small/Medium/Large），点击添加

### 7.4 测试数据推送

1. 打开 App，进入设置页面
2. 点击 "刷新小组件"
3. 回到主屏幕查看小组件是否更新

---

## 效果预览

### Small Size
```
┌─────────────┐
│    📋      │
│   1/4      │
│  ━━━━      │
│ 今天待办    │
└─────────────┘
```

### Medium Size
```
┌─────────────────────────────┐
│ 📋 今天待办            1/4  │
├─────────────────────────────┤
│ ⭕ 完成项目汇报              │
│ ⭕ 回复客户邮件              │
│ ✅ 团队周会                  │
│ ⭕ 阅读技术文档              │
└─────────────────────────────┘
```

### Large Size
```
┌─────────────────────────────┐
│ 📋 今天待办            1/4  │
├─────────────────────────────┤
│ ⭕ 完成项目汇报              │
│ ⭕ 回复客户邮件              │
│ ✅ 团队周会                  │
│ ⭕ 阅读技术文档              │
│ ⭕ 代码审查                  │
│ ⭕ 准备周会材料              │
│ ...                         │
└─────────────────────────────┘
```

---

## 下一步

1. **添加交互**：点击任务标记完成
2. **添加更多小组件**：四象限、收集箱
3. **自动同步**：任务变更时自动刷新小组件
4. **深色模式优化**：完善暗色主题颜色
