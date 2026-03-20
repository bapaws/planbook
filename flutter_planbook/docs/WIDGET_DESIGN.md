# Planbook 小组件设计文档

## 概述

本文档详细描述 Planbook 应用的桌面小组件设计方案，包括视觉样式、技术架构、数据查询与交互逻辑。

## 小组件类型

### 1. 四象限小组件 (Quadrant Widget)

#### 功能描述
以 Eisenhower Matrix（艾森豪威尔矩阵）形式展示今天的任务分布，帮助用户快速识别优先级。

#### 支持尺寸
- **Medium (中号)**: 2x2 网格展示四象限概览
- **Large (大号)**: 4x2 网格，每个象限显示具体任务列表

#### 视觉设计

**中号 (Medium) 样式:**
```
┌─────────────────────────────┐
│  📊 四象限                3 │
├─────────────┬───────────────┤
│ 🔴 重要且紧急 │ 🟡 重要不紧急  │
│     2       │       1       │
├─────────────┼───────────────┤
│ 🟠 紧急不重要 │ ⚪ 不紧急不重要 │
│     0       │       0       │
└─────────────┴───────────────┘
```

**大号 (Large) 样式:**
```
┌─────────────────────────────────────┐
│  📊 四象限                      3   │
├──────────────┬──────────────────────┤
│ 🔴 重要且紧急 2 │ 🟡 重要不紧急 1      │
│ ├ 完成项目汇报 │ ├ 阅读技术文档        │
│ ├ 修复线上bug │ └ 健身计划           │
│ └ 回复客户邮件 │                      │
├──────────────┼──────────────────────┤
│ 🟠 紧急不重要 0 │ ⚪ 不紧急不重要 0    │
│              │                      │
└──────────────┴──────────────────────┘
```

**颜色方案:**
| 象限 | 颜色 | Hex |
|------|------|-----|
| 重要且紧急 | 红色 | #FF4444 |
| 重要不紧急 | 黄色 | #FFBB33 |
| 紧急不重要 | 橙色 | #FF8800 |
| 不紧急不重要 | 灰色 | #9E9E9E |

---

### 2. 今天任务小组件 (Today Widget)

#### 功能描述
展示今天需要完成的任务列表，支持标记完成。

#### 支持尺寸
- **Small (小号)**: 显示今天待办数量 + 进度
- **Medium (中号)**: 显示 3-4 个任务的列表
- **Large (大号)**: 显示 6-8 个任务的完整列表

#### 视觉设计

**小号 (Small) 样式:**
```
┌─────────────┐
│   📅 今天   │
│             │
│   3/5      │
│  ━━━━━━    │
│  60%       │
└─────────────┘
```

**中号 (Medium) 样式:**
```
┌─────────────────────────────┐
│ 📅 今天待办              3  │
├─────────────────────────────┤
│ ☐ 完成项目汇报               │
│ ☐ 回复客户邮件               │
│ ☑ 团队周会 (已完成)          │
│ ☐ 阅读技术文档               │
└─────────────────────────────┘
```

**交互:**
- 点击任务左侧圆圈标记完成/未完成
- 点击任务标题打开 App 并跳转到对应任务
- 点击"+"按钮快速添加任务

---

### 3. 收集箱小组件 (Inbox Widget)

#### 功能描述
快速查看未分类任务（没有日期或标签的任务），提醒用户及时整理。

#### 支持尺寸
- **Small (小号)**: 显示收集箱任务数量
- **Medium (中号)**: 显示最近 3 个收集箱任务

#### 视觉设计

**小号 (Small) 样式:**
```
┌─────────────┐
│   📥 收集箱 │
│             │
│    12      │
│  待整理     │
└─────────────┘
```

**中号 (Medium) 样式:**
```
┌─────────────────────────────┐
│ 📥 收集箱               12  │
├─────────────────────────────┤
│ • 学习 Flutter 新特性        │
│ • 购买办公用品              │
│ • 预约牙医                 │
├─────────────────────────────┤
│ [    快速添加...    ] [+]  │
└─────────────────────────────┘
```

**交互:**
- 底部输入框支持快速添加任务到收集箱
- 点击任务打开 App 编辑

---

### 4. 标签过滤小组件 (Tag Filter Widget)

#### 功能描述
用户可配置显示特定标签的任务，支持工作、生活、学习等场景。

#### 支持尺寸
- **Small (小号)**: 显示指定标签的任务数量
- **Medium (中号)**: 显示指定标签的任务列表

#### 配置选项
- **标签选择**: 用户在添加小组件时选择要显示的标签
- **颜色主题**: 自动继承标签颜色

#### 视觉设计

**小号 (Small) 样式:**
```
┌─────────────┐
│   💼 工作   │
│   (蓝色)    │
│             │
│    5/8     │
│  待完成     │
└─────────────┘
```

**中号 (Medium) 样式:**
```
┌─────────────────────────────┐
│ 💼 工作                 5/8 │
├─────────────────────────────┤
│ ☐ 完成项目汇报               │
│ ☐ 回复客户邮件               │
│ ☐ 准备周会材料              │
│ ☐ 代码审查                 │
└─────────────────────────────┘
```

---

### 5. 快速记录小组件 (Quick Capture Widget)

#### 功能描述
提供最快的方式记录想法、任务或笔记，无需打开 App。

#### 支持尺寸
- **Small (小号)**: 一个快速记录按钮
- **Medium (中号)**: 快捷记录 + 最近记录列表

#### 视觉设计

**小号 (Small) 样式:**
```
┌─────────────┐
│             │
│     ➕     │
│             │
│  快速记录   │
│             │
└─────────────┘
```

**中号 (Medium) 样式:**
```
┌─────────────────────────────┐
│ ⚡ 快速记录                 │
├─────────────────────────────┤
│ [                        ] │
│ [任务/笔记/想法...        ] │
│ [                        ] │
├─────────────────────────────┤
│ [📋任务] [📝笔记] [💡想法] │
└─────────────────────────────┘
```

**交互:**
- 点击输入框展开键盘直接输入
- 底部按钮选择记录类型
- 支持 Siri/语音输入快捷方式

---

## 技术架构

### 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter App                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ TaskBloc    │  │ NoteBloc    │  │ WidgetDataService   │ │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘ │
│         └─────────────────┴────────────────────┘            │
│                          │                                  │
│  ┌───────────────────────┼──────────────────────────────┐  │
│  │                       ▼                              │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │           Repository Layer                    │   │  │
│  │  │  ┌──────────┐ ┌──────────┐ ┌──────────────┐  │   │  │
│  │  │  │ TasksRepo│ │ NotesRepo│ │ SettingsRepo │  │   │  │
│  │  │  └────┬─────┘ └────┬─────┘ └──────┬───────┘  │   │  │
│  │  └───────┼────────────┼──────────────┼──────────┘   │  │
│  │          │            │              │               │  │
│  │  ┌───────┴────────────┴──────────────┴──────────┐   │  │
│  │  │              Data Source Layer                │   │  │
│  │  │  ┌──────────────────┐  ┌──────────────────┐  │   │  │
│  │  │  │  Drift (SQLite)  │  │   Supabase       │  │   │  │
│  │  │  └────────┬─────────┘  └────────┬─────────┘  │   │  │
│  │  └───────────┼─────────────────────┼────────────┘   │  │
│  └──────────────┼─────────────────────┼────────────────┘  │
└─────────────────┼─────────────────────┼───────────────────┘
                  │                     │
                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    Shared Storage                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  iOS: App Group Container                              │  │
│  │  Android: SharedPreferences (MODE_WORLD_READABLE)      │  │
│  │  Data: widget_today_tasks.json                         │  │
│  │        widget_quadrant_counts.json                     │  │
│  │        widget_inbox_tasks.json                         │  │
│  └───────────────────────────────────────────────────────┘  │
└──────────────────────────────┬──────────────────────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  iOS WidgetKit  │  │ Android AppWidget│  │   App Intent    │
│  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │
│  │ SwiftUI   │  │  │  │  Kotlin   │  │  │  │  Quick    │  │
│  │  Views    │  │  │  │  Views    │  │  │  │ Actions   │  │
│  └───────────┘  │  │  └───────────┘  │  │  └───────────┘  │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

---

## 数据层设计

### 数据模型

#### WidgetTask (小组件任务模型)
```swift
// iOS (Swift)
struct WidgetTask: Codable {
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
    let color: String // Hex color
}
```

```kotlin
// Android (Kotlin)
data class WidgetTask(
    val id: String,
    val title: String,
    val isCompleted: Boolean,
    val priority: TaskPriority,
    val dueAt: Long?,
    val tags: List<WidgetTag>
) {
    enum class TaskPriority { HIGH, MEDIUM, LOW, NONE }
}

data class WidgetTag(
    val id: String,
    val name: String,
    val color: String
)
```

#### WidgetData (小组件数据容器)
```swift
// iOS
struct WidgetData: Codable {
    let timestamp: Date
    let todayTasks: [WidgetTask]
    let inboxTasks: [WidgetTask]
    let quadrantCounts: QuadrantCounts
    let tagTasks: [String: [WidgetTask]] // key: tagId
}

struct QuadrantCounts: Codable {
    let importantUrgent: Int      // 重要且紧急
    let importantNotUrgent: Int   // 重要不紧急
    let urgentUnimportant: Int    // 紧急不重要
    let notUrgentUnimportant: Int // 不紧急不重要
}
```

### 数据存储策略

#### iOS - App Group 共享
```swift
// App Group ID
let appGroupId = "group.GM4766U38W.com.bapaws.habits"

// 共享 UserDefaults
let sharedDefaults = UserDefaults(suiteName: appGroupId)

// 共享文件路径
let sharedContainer = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
let widgetDataURL = sharedContainer?.appendingPathComponent("widget_data.json")
```

#### Android - 共享存储
```kotlin
// 使用 SharedPreferences 跨进程共享
val prefs = context.getSharedPreferences(
    "widget_data", 
    Context.MODE_PRIVATE
)

// 或者使用 ContentProvider 更安全地共享
class WidgetDataProvider : ContentProvider() {
    // 实现查询方法供小组件调用
}
```

### 数据同步机制

#### 1. Flutter 端数据准备
```dart
// lib/services/widget_data_service.dart

class WidgetDataService {
  static const _appGroupId = 'group.GM4766U38W.com.bapaws.habits';
  
  final TasksRepository _tasksRepository;
  final TagsRepository _tagsRepository;
  
  WidgetDataService(this._tasksRepository, this._tagsRepository);
  
  /// 更新所有小组件数据
  Future<void> updateAllWidgetData() async {
    final now = DateTime.now();
    
    // 1. 获取今天任务
    final todayTasks = await _tasksRepository
        .getTaskEntities(date: Jiffy.now(), mode: TaskListMode.today)
        .first;
    
    // 2. 获取收集箱任务
    final inboxTasks = await _tasksRepository
        .getTaskEntities(date: Jiffy.now(), mode: TaskListMode.inbox)
        .first;
    
    // 3. 计算四象限统计
    final quadrantCounts = _calculateQuadrantCounts(todayTasks);
    
    // 4. 按标签分组任务
    final tagTasks = await _groupTasksByTag();
    
    // 5. 序列化为 JSON
    final widgetData = WidgetData(
      timestamp: now,
      todayTasks: todayTasks.map((e) => WidgetTask.fromEntity(e)).toList(),
      inboxTasks: inboxTasks.map((e) => WidgetTask.fromEntity(e)).toList(),
      quadrantCounts: quadrantCounts,
      tagTasks: tagTasks,
    );
    
    // 6. 保存到共享存储
    await _saveToSharedStorage(widgetData);
    
    // 7. 触发小组件刷新
    await _reloadWidgets();
  }
  
  Future<void> _saveToSharedStorage(WidgetData data) async {
    final json = jsonEncode(data.toJson());
    
    if (Platform.isIOS) {
      // iOS: 使用 AppHomeWidget 保存
      await AppHomeWidget.setAppGroupId(_appGroupId);
      await AppHomeWidget.saveWidgetData('widget_data', json);
    } else if (Platform.isAndroid) {
      // Android: 使用 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_data', json);
    }
  }
  
  Future<void> _reloadWidgets() async {
    // 使用 home_widget 包刷新小组件
    await HomeWidget.updateWidget(
      name: 'TodayWidget',
      androidName: 'TodayWidgetProvider',
      iOSName: 'TodayWidget',
    );
    // ... 刷新其他小组件
  }
}
```

#### 2. 触发更新时机
```dart
// 在 Bloc 中监听状态变化，自动更新小组件
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final WidgetDataService _widgetDataService;
  
  TaskBloc(this._widgetDataService) : super(TaskInitial()) {
    on<TaskCompleted>(_onTaskCompleted);
    on<TaskCreated>(_onTaskCreated);
    on<TaskUpdated>(_onTaskUpdated);
    on<TaskDeleted>(_onTaskDeleted);
  }
  
  Future<void> _onTaskCompleted(
    TaskCompleted event,
    Emitter<TaskState> emit,
  ) async {
    // ... 完成任务逻辑
    
    // 更新小组件数据
    await _widgetDataService.updateAllWidgetData();
  }
  
  // 其他 CRUD 操作类似...
}
```

---

## iOS 实现 (Swift + WidgetKit)

### 1. 项目结构
```
ios/
├── Runner/                    # 主 App
│   └── AppDelegate.swift
├── Widgets/                   # Widget Extension
│   ├── WidgetsBundle.swift    # Widget Bundle 入口
│   ├── TodayWidget.swift      # 今天任务小组件
│   ├── QuadrantWidget.swift   # 四象限小组件
│   ├── InboxWidget.swift      # 收集箱小组件
│   ├── TagFilterWidget.swift  # 标签过滤小组件
│   ├── QuickCaptureWidget.swift # 快速记录小组件
│   ├── WidgetModels.swift     # 数据模型
│   ├── WidgetDataProvider.swift # 数据提供器
│   └── WidgetViewComponents.swift # 共享视图组件
└── PlanbookIntents/           # App Intents Extension
    └── TaskIntents.swift
```

### 2. 数据提供器 (Data Provider)
```swift
// ios/Widgets/WidgetDataProvider.swift

import WidgetKit
import SwiftUI

class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    private let appGroupId = "group.GM4766U38W.com.bapaws.habits"
    
    func loadWidgetData() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let jsonString = defaults.string(forKey: "widget_data"),
              let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        
        return try? JSONDecoder().decode(WidgetData.self, from: jsonData)
    }
    
    func loadTodayTasks(limit: Int = 5) -> [WidgetTask] {
        let data = loadWidgetData()
        return Array(data?.todayTasks.prefix(limit) ?? [])
    }
    
    func loadQuadrantCounts() -> QuadrantCounts {
        return loadWidgetData()?.quadrantCounts ?? QuadrantCounts()
    }
}
```

### 3. 今天任务小组件
```swift
// ios/Widgets/TodayWidget.swift

import WidgetKit
import SwiftUI

struct TodayWidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let completedCount: Int
    let totalCount: Int
}

struct TodayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayWidgetEntry {
        TodayWidgetEntry(
            date: Date(),
            tasks: WidgetTask.sampleTasks,
            completedCount: 2,
            totalCount: 5
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TodayWidgetEntry) -> Void) {
        let data = WidgetDataProvider.shared.loadWidgetData()
        let tasks = data?.todayTasks ?? []
        let completed = tasks.filter { $0.isCompleted }.count
        
        let entry = TodayWidgetEntry(
            date: Date(),
            tasks: tasks,
            completedCount: completed,
            totalCount: tasks.count
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

struct TodayWidgetView: View {
    var entry: TodayWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            TodaySmallView(entry: entry)
        case .systemMedium:
            TodayMediumView(entry: entry)
        case .systemLarge:
            TodayLargeView(entry: entry)
        default:
            TodaySmallView(entry: entry)
        }
    }
}

struct TodayMediumView: View {
    let entry: TodayWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 头部
            HStack {
                Label("今天待办", systemImage: "calendar")
                    .font(.headline)
                Spacer()
                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 任务列表
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.tasks.prefix(4)) { task in
                    TaskRowView(task: task)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct TaskRowView: View {
    let task: WidgetTask
    
    var body: some View {
        HStack(spacing: 8) {
            // 完成状态圆圈
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : priorityColor)
                .font(.system(size: 18))
            
            // 任务标题
            Text(task.title)
                .font(.system(size: 14))
                .lineLimit(1)
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? .secondary : .primary)
            
            Spacer()
        }
        .contentShape(Rectangle())
        // 点击处理在 .widgetURL 或 App Intent 中实现
    }
    
    var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        case .none: return .gray
        }
    }
}

struct TodayWidget: Widget {
    let kind: String = "TodayWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayWidgetProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("今天任务")
        .description("查看今天需要完成的任务")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

### 4. 四象限小组件
```swift
// ios/Widgets/QuadrantWidget.swift

import WidgetKit
import SwiftUI

struct QuadrantWidgetView: View {
    let entry: QuadrantEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemMedium:
            QuadrantMediumView(counts: entry.counts)
        case .systemLarge:
            QuadrantLargeView(data: entry)
        default:
            QuadrantMediumView(counts: entry.counts)
        }
    }
}

struct QuadrantMediumView: View {
    let counts: QuadrantCounts
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("四象限", systemImage: "square.grid.2x2")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 8) {
                QuadrantCell(
                    title: "重要且紧急",
                    count: counts.importantUrgent,
                    color: .red,
                    icon: "exclamationmark.circle.fill"
                )
                QuadrantCell(
                    title: "重要不紧急",
                    count: counts.importantNotUrgent,
                    color: .orange,
                    icon: "star.fill"
                )
            }
            
            HStack(spacing: 8) {
                QuadrantCell(
                    title: "紧急不重要",
                    count: counts.urgentUnimportant,
                    color: .yellow,
                    icon: "bell.fill"
                )
                QuadrantCell(
                    title: "不紧急不重要",
                    count: counts.notUrgentUnimportant,
                    color: .gray,
                    icon: "arrow.down.circle.fill"
                )
            }
        }
        .padding()
    }
}

struct QuadrantCell: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Spacer()
            }
            
            Text("\(count)")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct QuadrantWidget: Widget {
    let kind: String = "QuadrantWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuadrantProvider()) { entry in
            QuadrantWidgetView(entry: entry)
        }
        .configurationDisplayName("四象限")
        .description("以四象限方式展示任务分布")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
```

### 5. App Intents (交互)
```swift
// ios/PlanbookIntents/TaskIntents.swift

import AppIntents
import WidgetKit

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "完成任务"
    static var description: IntentDescription = "标记任务为已完成"
    
    @Parameter(title: "任务ID")
    var taskId: String
    
    init() {}
    
    init(taskId: String) {
        self.taskId = taskId
    }
    
    func perform() async throws -> some IntentResult {
        // 1. 调用 Flutter Method Channel 或共享存储
        // 2. 更新任务状态
        // 3. 触发小组件刷新
        
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}

struct QuickAddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "快速添加任务"
    static var description: IntentDescription = "快速添加一个任务"
    
    @Parameter(title: "任务内容")
    var content: String
    
    @Parameter(title: "标签", default: nil)
    var tagId: String?
    
    func perform() async throws -> some IntentResult {
        // 1. 保存到共享存储
        // 2. 通过 Method Channel 通知 Flutter 处理
        // 3. 刷新小组件
        
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}
```

---

## Android 实现 (Kotlin + AppWidgetProvider)

### 1. 项目结构
```
android/app/src/main/
├── kotlin/com/bapaws/planbook/
│   ├── MainActivity.kt
│   └── widget/
│       ├── WidgetDataProvider.kt      # 数据提供
│       ├── TodayWidgetProvider.kt     # 今天任务
│       ├── QuadrantWidgetProvider.kt  # 四象限
│       ├── InboxWidgetProvider.kt     # 收集箱
│       ├── TagFilterWidgetProvider.kt # 标签过滤
│       ├── QuickCaptureWidgetProvider.kt # 快速记录
│       └── WidgetUpdateService.kt     # 更新服务
├── res/
│   ├── layout/
│   │   ├── widget_today_small.xml
│   │   ├── widget_today_medium.xml
│   │   ├── widget_quadrant_medium.xml
│   │   └── ...
│   ├── xml/
│   │   ├── today_widget_info.xml
│   │   ├── quadrant_widget_info.xml
│   │   └── ...
│   └── values/
│       └── widget_colors.xml
└── AndroidManifest.xml
```

### 2. 数据提供器
```kotlin
// android/app/src/main/kotlin/com/bapaws/planbook/widget/WidgetDataProvider.kt

package com.bapaws.planbook.widget

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

data class WidgetTask(
    val id: String,
    val title: String,
    val isCompleted: Boolean,
    val priority: TaskPriority,
    val dueAt: Long?,
    val tags: List<WidgetTag>
) {
    enum class TaskPriority { HIGH, MEDIUM, LOW, NONE }
}

data class WidgetTag(
    val id: String,
    val name: String,
    val color: String
)

data class QuadrantCounts(
    val importantUrgent: Int = 0,
    val importantNotUrgent: Int = 0,
    val urgentUnimportant: Int = 0,
    val notUrgentUnimportant: Int = 0
)

class WidgetDataProvider(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(
        "widget_data",
        Context.MODE_PRIVATE
    )
    private val gson = Gson()
    
    fun getTodayTasks(limit: Int = 10): List<WidgetTask> {
        val json = prefs.getString("today_tasks", "[]") ?: "[]"
        val type = object : TypeToken<List<WidgetTask>>() {}.type
        return gson.fromJson<List<WidgetTask>>(json, type).take(limit)
    }
    
    fun getQuadrantCounts(): QuadrantCounts {
        val json = prefs.getString("quadrant_counts", null)
        return if (json != null) {
            gson.fromJson(json, QuadrantCounts::class.java)
        } else {
            QuadrantCounts()
        }
    }
    
    fun getInboxTasks(limit: Int = 5): List<WidgetTask> {
        val json = prefs.getString("inbox_tasks", "[]") ?: "[]"
        val type = object : TypeToken<List<WidgetTask>>() {}.type
        return gson.fromJson<List<WidgetTask>>(json, type).take(limit)
    }
}
```

### 3. 今天任务小组件
```kotlin
// android/app/src/main/kotlin/com/bapaws/planbook/widget/TodayWidgetProvider.kt

package com.bapaws.planbook.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.bapaws.planbook.MainActivity
import com.bapaws.planbook.R

class TodayWidgetProvider : AppWidgetProvider() {
    
    companion object {
        const val ACTION_COMPLETE_TASK = "com.bapaws.planbook.COMPLETE_TASK"
        const val ACTION_REFRESH = "com.bapaws.planbook.REFRESH_WIDGET"
        const val EXTRA_TASK_ID = "task_id"
        
        fun updateWidget(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TodayWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val dataProvider = WidgetDataProvider(context)
        val tasks = dataProvider.getTodayTasks(5)
        
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, tasks)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            ACTION_COMPLETE_TASK -> {
                val taskId = intent.getStringExtra(EXTRA_TASK_ID)
                taskId?.let {
                    // 通知 Flutter 层完成任务
                    notifyFlutterTaskCompleted(context, it)
                    // 刷新小组件
                    updateWidget(context)
                }
            }
            ACTION_REFRESH -> {
                updateWidget(context)
            }
        }
    }
    
    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        tasks: List<WidgetTask>
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_today_medium)
        
        // 设置头部
        val completedCount = tasks.count { it.isCompleted }
        views.setTextViewText(R.id.tv_header, "今天待办 ${completedCount}/${tasks.size}")
        
        // 清空列表
        views.removeAllViews(R.id.task_list)
        
        // 添加任务项
        tasks.take(4).forEach { task ->
            val taskView = RemoteViews(context.packageName, R.layout.widget_task_item)
            
            // 设置完成图标
            val iconRes = if (task.isCompleted) 
                R.drawable.ic_check_circle_filled 
            else 
                R.drawable.ic_circle_outline
            views.setImageViewResource(R.id.iv_complete, iconRes)
            
            // 设置标题
            views.setTextViewText(R.id.tv_title, task.title)
            
            // 设置优先级颜色
            val priorityColor = when (task.priority) {
                WidgetTask.TaskPriority.HIGH -> R.color.priority_high
                WidgetTask.TaskPriority.MEDIUM -> R.color.priority_medium
                WidgetTask.TaskPriority.LOW -> R.color.priority_low
                WidgetTask.TaskPriority.NONE -> R.color.priority_none
            }
            views.setInt(R.id.iv_priority, "setColorFilter", 
                context.getColor(priorityColor))
            
            // 点击完成任务
            val completeIntent = Intent(context, TodayWidgetProvider::class.java).apply {
                action = ACTION_COMPLETE_TASK
                putExtra(EXTRA_TASK_ID, task.id)
            }
            val completePendingIntent = PendingIntent.getBroadcast(
                context,
                task.id.hashCode(),
                completeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.iv_complete, completePendingIntent)
            
            // 点击打开详情
            val openIntent = Intent(context, MainActivity::class.java).apply {
                putExtra("route", "/task/${task.id}")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPendingIntent = PendingIntent.getActivity(
                context,
                task.id.hashCode(),
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.tv_title, openPendingIntent)
            
            views.addView(R.id.task_list, taskView)
        }
        
        // 点击头部打开 App
        val mainIntent = Intent(context, MainActivity::class.java)
        val mainPendingIntent = PendingIntent.getActivity(
            context,
            0,
            mainIntent,
            PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.tv_header, mainPendingIntent)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
    
    private fun notifyFlutterTaskCompleted(context: Context, taskId: String) {
        // 通过 Method Channel 或广播通知 Flutter
        val intent = Intent("com.bapaws.planbook.TASK_COMPLETED").apply {
            putExtra(EXTRA_TASK_ID, taskId)
        }
        context.sendBroadcast(intent)
    }
}
```

### 4. 布局文件
```xml
<!-- android/app/src/main/res/layout/widget_today_medium.xml -->
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout 
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@drawable/widget_background"
    android:padding="12dp">

    <!-- Header -->
    <TextView
        android:id="@+id/tv_header"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="今天待办"
        android:textSize="16sp"
        android:textStyle="bold"
        android:textColor="@android:color/black"
        android:drawableStart="@drawable/ic_calendar"
        android:drawablePadding="8dp"
        android:gravity="center_vertical" />

    <View
        android:layout_width="match_parent"
        android:layout_height="1dp"
        android:layout_marginVertical="8dp"
        android:background="#E0E0E0" />

    <!-- Task List -->
    <LinearLayout
        android:id="@+id/task_list"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical" />

</LinearLayout>
```

```xml
<!-- android/app/src/main/res/layout/widget_task_item.xml -->
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout 
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="horizontal"
    android:gravity="center_vertical"
    android:paddingVertical="6dp">

    <ImageView
        android:id="@+id/iv_complete"
        android:layout_width="20dp"
        android:layout_height="20dp"
        android:src="@drawable/ic_circle_outline"
        android:contentDescription="Complete task" />

    <TextView
        android:id="@+id/tv_title"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:layout_marginStart="8dp"
        android:textSize="14sp"
        android:textColor="@android:color/black"
        android:maxLines="1"
        android:ellipsize="end" />

    <ImageView
        android:id="@+id/iv_priority"
        android:layout_width="8dp"
        android:layout_height="8dp"
        android:layout_marginStart="4dp"
        android:src="@drawable/ic_dot"
        android:contentDescription="Priority" />

</LinearLayout>
```

### 5. 小组件配置
```xml
<!-- android/app/src/main/res/xml/today_widget_info.xml -->
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider 
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:initialLayout="@layout/widget_today_medium"
    android:minWidth="250dp"
    android:minHeight="110dp"
    android:resizeMode="horizontal|vertical"
    android:updatePeriodMillis="1800000"
    android:widgetCategory="home_screen"
    android:previewImage="@drawable/widget_today_preview">
</appwidget-provider>
```

### 6. AndroidManifest 声明
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <application>
        <!-- Today Widget -->
        <receiver 
            android:name=".widget.TodayWidgetProvider"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/today_widget_info" />
        </receiver>
        
        <!-- Quadrant Widget -->
        <receiver 
            android:name=".widget.QuadrantWidgetProvider"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/quadrant_widget_info" />
        </receiver>
        
        <!-- Other widgets... -->
        
    </application>
</manifest>
```

---

## 数据查询与同步详细设计

### 1. 数据库查询策略

由于小组件无法直接使用 Drift 数据库，需要 Flutter App 主动推送数据。

#### 查询优化
```dart
// packages/database_planbook_api/lib/task/database_task_widget_api.dart

class DatabaseTaskWidgetApi {
  final AppDatabase _db;
  
  DatabaseTaskWidgetApi({required AppDatabase db}) : _db = db;
  
  /// 获取今天任务的精简数据（供小组件使用）
  Future<List<WidgetTaskData>> getTodayTasksForWidget({
    required String? userId,
    int limit = 10,
  }) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    // 联合查询任务和标签
    final query = _db.select(_db.tasks).join([
      leftOuterJoin(
        _db.taskTags,
        _db.taskTags.taskId.equalsExp(_db.tasks.id),
      ),
      leftOuterJoin(
        _db.tags,
        _db.tags.id.equalsExp(_db.taskTags.tagId),
      ),
    ])
      ..where(
        _db.tasks.userId.equals(userId) |
        _db.tasks.userId.isNull(),
      )
      ..where(_db.tasks.deletedAt.isNull())
      ..where(
        // 今天截止或开始的任务
        (_db.tasks.dueAt.isNotNull() & 
         _db.tasks.dueAt.isBetweenValues(startOfDay, endOfDay)) |
        (_db.tasks.startAt.isNotNull() & 
         _db.tasks.startAt.isBetweenValues(startOfDay, endOfDay))
      )
      ..orderBy([
        OrderingTerm(
          expression: _db.tasks.priority,
          mode: OrderingMode.asc,
        ),
        OrderingTerm(
          expression: _db.tasks.createdAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    
    final rows = await query.get();
    
    // 聚合任务和标签
    final taskMap = <String, WidgetTaskData>{};
    for (final row in rows) {
      final task = row.readTable(_db.tasks);
      final tag = row.readTableOrNull(_db.tags);
      
      taskMap.putIfAbsent(
        task.id,
        () => WidgetTaskData(
          id: task.id,
          title: task.title,
          priority: task.priority,
          isCompleted: false, // 需要通过 TaskActivity 查询
          dueAt: task.dueAt,
          tags: [],
        ),
      );
      
      if (tag != null) {
        taskMap[task.id]!.tags.add(
          WidgetTagData(
            id: tag.id,
            name: tag.name,
            color: tag.color,
          ),
        );
      }
    }
    
    // 查询完成状态
    for (final taskData in taskMap.values) {
      taskData.isCompleted = await _isTaskCompletedToday(
        taskId: taskData.id,
        date: now,
      );
    }
    
    return taskMap.values.toList();
  }
  
  Future<bool> _isTaskCompletedToday({
    required String taskId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final count = await (_db.select(_db.taskActivities)
          ..where((tbl) => 
            tbl.taskId.equals(taskId) &
            tbl.completedAt.isBetweenValues(startOfDay, endOfDay) &
            tbl.deletedAt.isNull()
          ))
        .get()
        .then((rows) => rows.length);
    
    return count > 0;
  }
}
```

### 2. 数据序列化
```dart
// packages/planbook_api/lib/src/widget/widget_models.dart

import 'package:json_annotation/json_annotation.dart';

part 'widget_models.g.dart';

@JsonSerializable()
class WidgetTaskData {
  final String id;
  final String title;
  final String priority; // high, medium, low, none
  bool isCompleted;
  final DateTime? dueAt;
  final List<WidgetTagData> tags;
  
  WidgetTaskData({
    required this.id,
    required this.title,
    required this.priority,
    required this.isCompleted,
    this.dueAt,
    required this.tags,
  });
  
  factory WidgetTaskData.fromJson(Map<String, dynamic> json) => 
      _$WidgetTaskDataFromJson(json);
  
  Map<String, dynamic> toJson() => _$WidgetTaskDataToJson(this);
}

@JsonSerializable()
class WidgetTagData {
  final String id;
  final String name;
  final String? color;
  
  WidgetTagData({
    required this.id,
    required this.name,
    this.color,
  });
  
  factory WidgetTagData.fromJson(Map<String, dynamic> json) => 
      _$WidgetTagDataFromJson(json);
  
  Map<String, dynamic> toJson() => _$WidgetTagDataToJson(this);
}

@JsonSerializable()
class WidgetDataContainer {
  final DateTime timestamp;
  final List<WidgetTaskData> todayTasks;
  final List<WidgetTaskData> inboxTasks;
  final QuadrantCounts quadrantCounts;
  final Map<String, List<WidgetTaskData>> tagTasks;
  
  WidgetDataContainer({
    required this.timestamp,
    required this.todayTasks,
    required this.inboxTasks,
    required this.quadrantCounts,
    required this.tagTasks,
  });
  
  factory WidgetDataContainer.fromJson(Map<String, dynamic> json) => 
      _$WidgetDataContainerFromJson(json);
  
  Map<String, dynamic> toJson() => _$WidgetDataContainerToJson(this);
}

@JsonSerializable()
class QuadrantCounts {
  final int importantUrgent;
  final int importantNotUrgent;
  final int urgentUnimportant;
  final int notUrgentUnimportant;
  
  QuadrantCounts({
    this.importantUrgent = 0,
    this.importantNotUrgent = 0,
    this.urgentUnimportant = 0,
    this.notUrgentUnimportant = 0,
  });
  
  int get total => importantUrgent + importantNotUrgent + 
                  urgentUnimportant + notUrgentUnimportant;
  
  factory QuadrantCounts.fromJson(Map<String, dynamic> json) => 
      _$QuadrantCountsFromJson(json);
  
  Map<String, dynamic> toJson() => _$QuadrantCountsToJson(this);
}
```

### 3. 自动更新机制
```dart
// lib/bloc/widget/widget_sync_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 小组件同步事件
abstract class WidgetSyncEvent {}

class WidgetDataChanged extends WidgetSyncEvent {}

class WidgetSyncTimerTick extends WidgetSyncEvent {}

/// 小组件同步状态
class WidgetSyncState {
  final DateTime? lastSyncTime;
  final bool isSyncing;
  
  WidgetSyncState({
    this.lastSyncTime,
    this.isSyncing = false,
  });
}

/// 小组件同步 BLoC
class WidgetSyncBloc extends Bloc<WidgetSyncEvent, WidgetSyncState> {
  final WidgetDataService _widgetDataService;
  Timer? _syncTimer;
  
  WidgetSyncBloc(this._widgetDataService) : super(WidgetSyncState()) {
    on<WidgetDataChanged>(_onDataChanged);
    on<WidgetSyncTimerTick>(_onTimerTick);
    
    // 每 15 分钟自动同步一次
    _syncTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => add(WidgetSyncTimerTick()),
    );
  }
  
  Future<void> _onDataChanged(
    WidgetDataChanged event,
    Emitter<WidgetSyncState> emit,
  ) async {
    emit(WidgetSyncState(isSyncing: true, lastSyncTime: state.lastSyncTime));
    await _widgetDataService.updateAllWidgetData();
    emit(WidgetSyncState(isSyncing: false, lastSyncTime: DateTime.now()));
  }
  
  Future<void> _onTimerTick(
    WidgetSyncTimerTick event,
    Emitter<WidgetSyncState> emit,
  ) async {
    await _widgetDataService.updateAllWidgetData();
    emit(WidgetSyncState(isSyncing: false, lastSyncTime: DateTime.now()));
  }
  
  @override
  Future<void> close() {
    _syncTimer?.cancel();
    return super.close();
  }
}
```

### 4. 任务完成交互流程
```
┌─────────────┐     ┌──────────────┐     ┌───────────────┐
│   Widget    │────▶│   App Intent │────▶│ Native Bridge │
│  (User Tap) │     │  / Broadcast │     │               │
└─────────────┘     └──────────────┘     └───────┬───────┘
                                                 │
                    ┌────────────────────────────┼───────┐
                    │                            ▼       │
                    │  ┌─────────────────────────────────┐│
                    │  │         Flutter App             ││
                    │  │  ┌─────────────────────────┐    ││
                    │  │  │    Method Channel       │◀───┼┘
                    │  │  │  - completeTask()       │    │
                    │  │  └───────────┬─────────────┘    │
                    │  │              │                  │
                    │  │  ┌───────────▼─────────────┐    │
                    │  │  │    TaskBloc/Repository  │    │
                    │  │  │  - update database      │    │
                    │  │  │  - sync to Supabase     │    │
                    │  │  │  - update widget data   │    │
                    │  │  └───────────┬─────────────┘    │
                    │  │              │                  │
                    │  │  ┌───────────▼─────────────┐    │
                    │  │  │   WidgetDataService     │    │
                    │  │  │  - save to shared store │────┼──┐
                    │  │  │  - notify widgets       │    │  │
                    │  │  └─────────────────────────┘    │  │
                    │  └─────────────────────────────────┘  │
                    │                                         │
                    │            ┌────────────┐              │
                    └───────────▶│  Widgets   │◀─────────────┘
                                 │  Refresh   │
                                 └────────────┘
```

---

## 开发路线图

### Phase 1: 基础框架 (1-2 周)
- [ ] 设置 iOS Widget Extension
- [ ] 设置 Android AppWidgetProvider 框架
- [ ] 实现 Flutter 到 Native 的数据传递
- [ ] 实现基础 Today Widget (只读)

### Phase 2: 核心小组件 (2-3 周)
- [ ] Today Widget 完整功能（支持标记完成）
- [ ] Quadrant Widget 实现
- [ ] Inbox Widget 实现
- [ ] 数据自动同步机制

### Phase 3: 高级功能 (2 周)
- [ ] Tag Filter Widget（支持配置）
- [ ] Quick Capture Widget
- [ ] App Intents / Shortcuts 集成
- [ ] 深色模式支持

### Phase 4: 优化与测试 (1-2 周)
- [ ] 性能优化
- [ ] 内存管理
- [ ] 单元测试
- [ ] UI 测试
- [ ] 用户反馈收集

---

## 注意事项

### iOS 限制
1. **内存限制**: Widget 内存有限，避免加载大量数据
2. **刷新限制**: 使用 Timeline 控制刷新，避免频繁更新
3. **交互限制**: iOS 17+ 支持 App Intents，旧版本使用 URL Scheme
4. **网络请求**: Widget 中避免直接网络请求，依赖 App 提供数据

### Android 限制
1. **RemoteViews 限制**: 只能使用有限的 View 类型
2. **点击处理**: 通过 PendingIntent 处理交互
3. **更新频率**: `updatePeriodMillis` 最小 30 分钟，频繁更新需用 AlarmManager
4. **后台限制**: Android 12+ 对后台服务有更严格限制

### 数据一致性
1. 始终使用 App Group (iOS) / SharedPreferences (Android) 共享数据
2. Flutter 负责数据更新，小组件只负责展示
3. 任务完成后通过 Method Channel 回传 Flutter 处理
4. 定期同步（每 15 分钟 + App 从后台恢复时）

---

## 参考资源

### 官方文档
- [Apple WidgetKit](https://developer.apple.com/documentation/widgetkit)
- [Android App Widgets](https://developer.android.com/guide/topics/appwidgets)
- [home_widget package](https://pub.dev/packages/home_widget)

### 示例项目
- [home_widget example](https://github.com/ABausG/home_widget/tree/main/example)

### 相关技术
- App Groups (iOS)
- UserDefaults / SharedPreferences
- Method Channel
- Drift Database
- WidgetKit (iOS 14+)
- Jetpack Glance (Android 12+)
