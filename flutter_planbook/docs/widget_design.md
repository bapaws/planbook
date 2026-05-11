# Planbook 小组件设计文档

> **版本**: v2.0  
> **日期**: 2026-04-22  
> **目标平台**: iOS (WidgetKit + GRDB.swift) / Android (App Widget + SQLite)  
> **核心变更**: 小组件直接读取 SQLite 数据库，不通过 JSON 传输数据，仅 SELECT 必要列

---

## 1. 概述

本文档定义 Planbook App 的桌面小组件设计方案。与常规方案不同，**小组件直接通过 SQLite 查询 App Group 共享的数据库**，Flutter 层仅负责写入主题/语言等配置，不传输任务数据。

| 组件 | 功能描述 | 支持尺寸 |
|------|---------|---------|
| **四象限组件** | 展示 Eisenhower Matrix 任务分布 | 大号（4×4）、中号（3×2） |
| **收集箱组件** | 按 Tag 分组展示无日期任务 | 大号（4×4）、中号（3×2） |
| **快速笔记组件** | 一键跳转创建笔记 | 小号（1×1） |

---

## 2. 现有基础设施

### 2.1 数据库

- **ORM**: Drift (Flutter 侧)
- **底层**: sqlite3
- **模式**: WAL（`PRAGMA journal_mode=WAL`），支持并发读写
- **iOS 路径**: App Group Container `group.GM4766U38W.com.bapaws.habits` / `habits.sqlite`
- **Android 路径**: `getApplicationDocumentsDirectory()` / `habits.sqlite`

### 2.2 表结构（Widget 相关）

```sql
-- 任务表（Tasks）
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  title TEXT NOT NULL,
  parent_id TEXT,
  layer INTEGER DEFAULT 0,
  child_count INTEGER DEFAULT 0,
  "order" INTEGER DEFAULT 0,
  start_at INTEGER,
  end_at INTEGER,
  is_all_day INTEGER DEFAULT 0,
  due_at INTEGER,
  recurrence_rule TEXT,
  detached_from_task_id TEXT,
  detached_recurrence_at INTEGER,
  detached_reason TEXT,
  alarms TEXT,
  priority TEXT,
  location TEXT,
  notes TEXT,
  time_zone TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  deleted_at INTEGER
);

-- 任务活动表（TaskActivities）—— 判断完成状态
CREATE TABLE task_activities (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  task_id TEXT,
  completed_at INTEGER,
  activity_type TEXT,
  occurrence_at INTEGER,
  start_at INTEGER,
  end_at INTEGER,
  duration INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  deleted_at INTEGER
);

-- 标签表（Tags）
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  name TEXT NOT NULL,
  color TEXT,
  "order" INTEGER DEFAULT 0,
  parent_id TEXT,
  level INTEGER DEFAULT 0,
  dark_color_scheme TEXT,
  light_color_scheme TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  deleted_at INTEGER
);

-- 任务标签关联表（TaskTags）
CREATE TABLE task_tags (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  task_id TEXT NOT NULL,
  tag_id TEXT NOT NULL,
  linked_tag_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  deleted_at INTEGER
);

-- 任务实例表（TaskOccurrences）—— 重复任务
CREATE TABLE task_occurrences (
  id TEXT PRIMARY KEY,
  task_id TEXT,
  occurrence_at INTEGER NOT NULL,
  start_at INTEGER,
  end_at INTEGER,
  due_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  deleted_at INTEGER,
  UNIQUE(task_id, occurrence_at)
);
```

### 2.3 iOS Widget Extension

已存在 `ios/Widgets/` Target，使用 SwiftUI + WidgetKit 构建，需引入 **GRDB.swift** 直接查询 SQLite。

### 2.4 Deeplink（仅用于必须启动 App 的场景）

App 已注册 URL Scheme：`planbook.bapaws`。仅「快速笔记」等必须打开 App 的操作使用 Deeplink，其余操作通过后台 Intent / Broadcast 处理。

---

## 3. Flutter 侧配置同步

由于小组件直接读数据库，Flutter **不再传输任务 JSON**，仅需同步以下配置：

| Key | 类型 | 说明 |
|-----|------|------|
| `widget_locale` | String | 语言标识，如 `zh`, `en` |
| `widget_theme` | String (JSON) | 颜色主题配置（见第 8 章） |

---

## 4. 交互方案：AppIntent（iOS）/ Background Action（Android）

> 核心原则：任务完成、象限切换等操作**不直接启动 App**，通过后台机制处理。

### 4.1 iOS AppIntent 设计

```swift
// 标记任务完成/撤销完成
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "完成任务"
    @Parameter(title: "任务ID") var taskId: String
    
    func perform() async throws -> some IntentResult {
        // 1. 直接操作 SQLite（GRDB）
        // 2. 插入或软删除 task_activities 记录
        // 3. 刷新 Widget Timeline
        return .result()
    }
}

// 中号四象限切换象限
struct SwitchQuadrantIntent: AppIntent {
    static var title: LocalizedStringResource = "切换象限"
    @Parameter(title: "优先级") var priority: String
    func perform() async throws -> some IntentResult
}

// 打开 App 创建笔记（唯一启动 App 的操作）
struct CreateNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "新建笔记"
    func perform() async throws -> some IntentResult {
        return .result(opensIntent: OpenURLIntent(
            URL(string: "planbook.bapaws://note/new")!
        ))
    }
}
```

### 4.2 Android Broadcast Action 设计

```kotlin
object WidgetActions {
    const val ACTION_COMPLETE_TASK = "com.bapaws.planbook.widget.COMPLETE_TASK"
    const val ACTION_SWITCH_QUADRANT = "com.bapaws.planbook.widget.SWITCH_QUADRANT"
    const val ACTION_CREATE_NOTE = "com.bapaws.planbook.widget.CREATE_NOTE"
    
    const val EXTRA_TASK_ID = "task_id"
    const val EXTRA_PRIORITY = "priority"
}
```

`WidgetActionReceiver` 直接在 `onReceive` 中操作 SQLite，不启动 Activity。

---

## 5. 组件详细设计

### 5.1 四象限组件（Quadrant Widget）

#### 5.1.1 大号组件（systemLarge / 4×4）

**布局**：2×2 网格完整展示四象限。

```
┌─────────────────────────────────┐
│  🔴 重要且紧急        🔵 重要不紧急  │
│  ├ 完成设计文档   ○    ├ 健身计划  ○ │
│  ├ 回复客户邮件   ○    ├ 阅读书籍  ○ │
│  └ +2 更多...         └ +1 更多... │
├─────────────────────────────────┤
│  🟡 紧急不重要        🟢 不紧急不重要 │
│  ├ 取快递         ○    ├ 整理桌面  ○ │
│  └ 已清空             └ +5 更多... │
└─────────────────────────────────┘
```

**显示规则**：
- 每个象限最多展示 3 条任务，超出显示 `+N 更多...`
- 已完成的任务灰色 + 删除线
- 有提醒的任务显示小闹钟图标
- 任务左侧/右侧显示 ○ 点击区域，用于完成

**交互**：
- 点击 ○：`CompleteTaskIntent` 直接操作 SQLite 标记完成（不启动 App）
- 点击任务文字：无操作
- 点击空白区域：无操作

#### 5.1.2 中号组件（systemMedium / 3×2）

**布局**：左侧象限切换栏 + 右侧任务列表。

```
┌────────────────────────────┐
│ █ │ 重要且紧急            │
│───┼───────────────────────│
│ ░ │ ○ 完成设计文档        │
│───┤ ○ 回复客户邮件        │
│ ░ │ ○ 准备会议资料        │
│───┤                       │
│ ░ │                       │
└────────────────────────────┘
```

- 左侧 `█` 当前选中，`░` 其他象限
- 默认选中 `high`

**交互**：
- 点击左侧色块：`SwitchQuadrantIntent` 切换象限
- 点击右侧 ○：`CompleteTaskIntent` 标记完成

---

### 5.2 收集箱组件（Inbox Widget）

#### 5.2.1 大号组件（systemLarge / 4×4）

```
┌─────────────────────────────┐
│ 📥 收集箱 (6)                │
├─────────────────────────────┤
│ ● 工作 (2)                  │
│   ○ 整理季度报表             │
│   ○ 更新项目文档             │
│ ● 学习 (1)                  │
│   ○ 背单词 50 个             │
│ ● 无标签 (3)                │
│   ○ 买牛奶                   │
│   ○ +2 更多...              │
└─────────────────────────────┘
```

- 按 Tag 分组，每组最多 2 条任务
- 无标签任务归入 "无标签" 组

#### 5.2.2 中号组件（systemMedium / 3×2）

展示前两个分组（按任务数优先）。交互同大号。

---

### 5.3 快速笔记组件（Quick Note Widget）

小号单一按钮，点击启动 App 到新建笔记页。

---

## 6. 刷新策略

| 组件 | 刷新频率 | 说明 |
|------|---------|------|
| 四象限 | 15 分钟 | 基于日期变化 |
| 收集箱 | 30 分钟 | 任务变更频率较低 |
| 快速笔记 | `.never` | 静态组件 |

**主动刷新触发**：Flutter 侧在任务/标签变更后，调用原生方法通知 widget 刷新 Timeline（仅通知，不传输数据）。

---

## 7. SQL 查询规范（仅 SELECT 必要列）

> 所有查询仅选取 widget 渲染所需的最小列集，减少内存占用。

### 7.1 四象限任务查询

```sql
-- 今日四象限任务（按优先级分组）
-- 适用于大号和中号组件
SELECT
  t.id,
  t.title,
  t.priority,
  t.parent_id,
  t.layer,
  t.alarms,
  ta.completed_at,
  ta.deleted_at AS activity_deleted_at
FROM tasks t
LEFT JOIN task_activities ta
  ON ta.task_id = t.id
  AND ta.deleted_at IS NULL
LEFT JOIN task_occurrences toc
  ON toc.task_id = t.id
  AND date(toc.occurrence_at / 1000000, 'unixepoch') = date('now')
  AND toc.deleted_at IS NULL
WHERE t.deleted_at IS NULL
  AND t.parent_id IS NULL
  AND (
    -- 今日任务条件（简化版，实际需根据业务精确匹配）
    date(t.start_at / 1000000, 'unixepoch') = date('now')
    OR date(t.due_at / 1000000, 'unixepoch') = date('now')
    OR date(toc.occurrence_at / 1000000, 'unixepoch') = date('now')
    -- 无日期但设置了优先级的任务也显示
    OR (t.start_at IS NULL AND t.due_at IS NULL AND t.priority IS NOT NULL)
  )
ORDER BY t."order" ASC, t.created_at ASC;
```

**必要列说明**：
| 列 | 用途 |
|----|------|
| `t.id` | 任务标识 / CompleteTaskIntent 参数 |
| `t.title` | 展示标题 |
| `t.priority` | 四象限分组（high/medium/low/none） |
| `t.parent_id` | 过滤子任务（仅展示顶层） |
| `t.layer` | 辅助层级判断 |
| `t.alarms` | 是否显示闹钟图标 |
| `ta.completed_at` | 判断是否已完成 |
| `ta.deleted_at` | 确认完成记录有效 |

> **注意**：时间戳存储为 microsecondsSinceEpoch（Drift 默认），除以 1000000 转为秒级 unixepoch。

### 7.2 收集箱任务查询

```sql
-- Inbox 任务（无日期任务）
SELECT
  t.id,
  t.title,
  t.alarms,
  ta.completed_at,
  ta.deleted_at AS activity_deleted_at,
  tg.id AS tag_id,
  tg.name AS tag_name,
  tg.color AS tag_color
FROM tasks t
LEFT JOIN task_activities ta
  ON ta.task_id = t.id
  AND ta.deleted_at IS NULL
LEFT JOIN task_tags tt
  ON tt.task_id = t.id
  AND tt.deleted_at IS NULL
LEFT JOIN tags tg
  ON tg.id = tt.tag_id
  AND tg.deleted_at IS NULL
WHERE t.deleted_at IS NULL
  AND t.parent_id IS NULL
  AND t.start_at IS NULL
  AND t.due_at IS NULL
  AND t.end_at IS NULL
ORDER BY tg."order" ASC, tg.name ASC, t."order" ASC;
```

**必要列说明**：
| 列 | 用途 |
|----|------|
| `t.id` / `t.title` | 任务展示 |
| `t.alarms` | 提醒图标 |
| `ta.completed_at` / `ta.deleted_at` | 完成状态 |
| `tg.id` / `tg.name` / `tg.color` | Tag 分组与颜色 |

### 7.3 标签查询（用于收集箱分组）

```sql
-- 获取所有有效标签（用于无任务时的空状态或分组标题）
SELECT id, name, color, "order"
FROM tags
WHERE deleted_at IS NULL
  AND parent_id IS NULL
ORDER BY "order" ASC, name ASC;
```

### 7.4 完成状态判断逻辑

```swift
// Swift (GRDB)
let isCompleted = row["completed_at"] != nil && row["activity_deleted_at"] == nil

// Kotlin (Android)
val isCompleted = cursor.getLong(cursor.getColumnIndexOrThrow("completed_at")) != 0L
    && cursor.isNull(cursor.getColumnIndexOrThrow("activity_deleted_at"))
```

---

## 8. AppColorSchemes 跨平台封装

> 通过 JSON 初始化，用户后续提供 dark/light 完整颜色数据。

### 8.1 JSON 数据结构（widget_theme）

```json
{
  "isDarkMode": false,
  "seedColorName": "blue",
  "colorScheme": {
    "primary": "#4DABF7",
    "onPrimary": "#FFFFFF",
    "primaryContainer": "#D0EBFF",
    "onPrimaryContainer": "#1864AB",
    "secondary": "#5C7CFA",
    "onSecondary": "#FFFFFF",
    "secondaryContainer": "#DBE4FF",
    "onSecondaryContainer": "#364FC7",
    "tertiary": "#9775FA",
    "onTertiary": "#FFFFFF",
    "tertiaryContainer": "#E5DBFF",
    "onTertiaryContainer": "#5F3DC4",
    "error": "#FF6B6B",
    "onError": "#FFFFFF",
    "errorContainer": "#FFE3E3",
    "onErrorContainer": "#C92A2A",
    "surface": "#F8F9FA",
    "onSurface": "#212529",
    "surfaceContainerHighest": "#E9ECEF",
    "onSurfaceVariant": "#495057",
    "outline": "#ADB5BD",
    "shadow": "#000000",
    "inverseSurface": "#343A40",
    "onInverseSurface": "#F8F9FA"
  }
}
```

### 8.2 Swift 封装

**文件**：`ios/Widgets/Theme/AppWidgetColorScheme.swift`

```swift
import SwiftUI
import GRDB

struct AppWidgetColorScheme: Codable {
    let primary, onPrimary: String
    let primaryContainer, onPrimaryContainer: String
    let secondary, onSecondary: String
    let secondaryContainer, onSecondaryContainer: String
    let tertiary, onTertiary: String
    let tertiaryContainer, onTertiaryContainer: String
    let error, onError: String
    let errorContainer, onErrorContainer: String
    let surface, onSurface: String
    let surfaceContainerHighest, onSurfaceVariant: String
    let outline, shadow: String
    let inverseSurface, onInverseSurface: String
    
    var colorPrimary: Color { Color(hex: primary) }
    // ... 其他计算属性
    
    static func from(prefsKey: String, groupId: String) -> AppWidgetColorScheme? {
        let prefs = UserDefaults(suiteName: groupId)
        guard let json = prefs?.string(forKey: prefsKey),
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AppWidgetColorScheme.self, from: data)
    }
}

extension Color {
    init(hex: String) { /* hex -> SwiftUI Color */ }
}
```

### 8.3 Kotlin 封装

**文件**：`android/app/src/main/kotlin/com/bapaws/planbook/widget/theme/AppWidgetColorScheme.kt`

```kotlin
data class AppWidgetColorScheme(
    val primary: String, val onPrimary: String,
    val primaryContainer: String, val onPrimaryContainer: String,
    // ... 其他字段
) {
    @ColorInt fun primaryColor(): Int = Color.parseColor(primary)
    // ... 其他解析方法
    
    companion object {
        fun fromPrefs(context: Context, key: String): AppWidgetColorScheme? {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val json = prefs.getString(key, null) ?: return null
            return try { Gson().fromJson(json, AppWidgetColorScheme::class.java) } catch (_: Exception) { null }
        }
    }
}
```

### 8.4 优先级固定颜色

四象限使用固定颜色（非主题色），但支持通过 `widget_theme` 中的 `priorityColors` 覆盖：

```json
{
  "priorityColors": {
    "high": "#FF6B6B",
    "medium": "#4DABF7",
    "low": "#FCC419",
    "none": "#69DB7C"
  }
}
```

---

## 9. 技术实现分工

### 9.1 Flutter 侧

**职责**：仅同步主题和语言配置，通知 widget 刷新。

**新增文件**：`lib/app/widget/app_widget_config.dart`

```dart
class AppWidgetConfig {
  static Future<void> syncTheme(AppTheme theme) async {
    final json = jsonEncode(theme.toWidgetJson());
    await AppHomeWidget.saveWidgetData('widget_theme', json);
  }
  
  static Future<void> syncLocale(String locale) async {
    await AppHomeWidget.saveWidgetData('widget_locale', locale);
  }
  
  static Future<void> reloadWidgets() async {
    // 调用原生方法通知 iOS/Android 刷新 Timeline
    await HomeWidgetChannel.reloadWidgets();
  }
}
```

### 9.2 iOS 侧（SwiftUI + GRDB.swift）

**依赖**：在 `ios/Widgets/Package.swift` 中添加 GRDB.swift 依赖。

**文件清单**：

| 文件 | 说明 |
|------|------|
| `ios/Widgets/WidgetsBundle.swift` | 注册 QuadrantWidget, InboxWidget, QuickNoteWidget |
| `ios/Widgets/QuadrantWidget.swift` | 大号/中号四象限组件 |
| `ios/Widgets/InboxWidget.swift` | 大号/中号收集箱组件 |
| `ios/Widgets/QuickNoteWidget.swift` | 小号快速笔记组件 |
| `ios/Widgets/Database/WidgetDatabase.swift` | GRDB 数据库连接 + SQL 查询封装 |
| `ios/Widgets/Database/TaskRecord.swift` | 仅含必要列的 Task 结构体 |
| `ios/Widgets/Database/TagRecord.swift` | 仅含必要列的 Tag 结构体 |
| `ios/Widgets/Theme/AppWidgetColorScheme.swift` | 颜色主题 JSON 解析 |
| `ios/Widgets/AppIntent.swift` | CompleteTaskIntent, SwitchQuadrantIntent, CreateNoteIntent |

**GRDB 查询示例**：

```swift
import GRDB

struct WidgetDatabase {
    static let appGroupId = "group.GM4766U38W.com.bapaws.habits"
    
    static var dbQueue: DatabaseQueue? {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent("habits.sqlite") else { return nil }
        return try? DatabaseQueue(path: containerURL.path)
    }
    
    static func fetchQuadrantTasks() -> [TaskRecord] {
        guard let dbQueue = dbQueue else { return [] }
        return (try? dbQueue.read { db in
            try TaskRecord.fetchAll(db, sql: """
                SELECT t.id, t.title, t.priority, t.parent_id, t.layer, t.alarms,
                       ta.completed_at, ta.deleted_at AS activity_deleted_at
                FROM tasks t
                LEFT JOIN task_activities ta ON ta.task_id = t.id AND ta.deleted_at IS NULL
                LEFT JOIN task_occurrences toc ON toc.task_id = t.id
                    AND date(toc.occurrence_at / 1000000, 'unixepoch') = date('now')
                    AND toc.deleted_at IS NULL
                WHERE t.deleted_at IS NULL
                  AND t.parent_id IS NULL
                  AND (
                      date(t.start_at / 1000000, 'unixepoch') = date('now')
                      OR date(t.due_at / 1000000, 'unixepoch') = date('now')
                      OR date(toc.occurrence_at / 1000000, 'unixepoch') = date('now')
                      OR (t.start_at IS NULL AND t.due_at IS NULL AND t.priority IS NOT NULL)
                  )
                ORDER BY t."order" ASC, t.created_at ASC
                LIMIT 50
            """)
        }) ?? []
    }
}

struct TaskRecord: FetchableRecord {
    let id: String
    let title: String
    let priority: String?
    let parentId: String?
    let layer: Int
    let alarms: String?
    let completedAt: Date?
    let activityDeletedAt: Date?
    
    var isCompleted: Bool { completedAt != nil && activityDeletedAt == nil }
    var hasAlarm: Bool { alarms != nil && !(alarms?.isEmpty ?? true) }
    
    init(row: Row) {
        id = row["id"]
        title = row["title"]
        priority = row["priority"]
        parentId = row["parent_id"]
        layer = row["layer"]
        alarms = row["alarms"]
        completedAt = row["completed_at"]
        activityDeletedAt = row["activity_deleted_at"]
    }
}
```

### 9.3 Android 侧（Kotlin + android.database.sqlite）

**新增文件**：

```
android/app/src/main/kotlin/com/bapaws/planbook/widget/
├── QuadrantWidgetProvider.kt
├── InboxWidgetProvider.kt
├── QuickNoteWidgetProvider.kt
├── WidgetActionReceiver.kt
├── database/
│   ├── WidgetDatabaseHelper.kt      // SQLiteOpenHelper / 直接打开数据库
│   ├── TaskRecord.kt                // 仅必要列的数据类
│   └── TagRecord.kt
└── theme/
    └── AppWidgetColorScheme.kt
```

**Android 数据库查询示例**：

```kotlin
class WidgetDatabaseHelper(context: Context) {
    private val dbPath = context.getDatabasePath("habits.sqlite").absolutePath
    
    fun readableDb(): SQLiteDatabase = SQLiteDatabase.openDatabase(
        dbPath, null, SQLiteDatabase.OPEN_READONLY
    )
    
    fun fetchQuadrantTasks(): List<TaskRecord> {
        val db = readableDb()
        val tasks = mutableListOf<TaskRecord>()
        val cursor = db.rawQuery("""
            SELECT t.id, t.title, t.priority, t.parent_id, t.layer, t.alarms,
                   ta.completed_at, ta.deleted_at AS activity_deleted_at
            FROM tasks t
            LEFT JOIN task_activities ta ON ta.task_id = t.id AND ta.deleted_at IS NULL
            LEFT JOIN task_occurrences toc ON toc.task_id = t.id
                AND date(toc.occurrence_at / 1000000, 'unixepoch') = date('now')
                AND toc.deleted_at IS NULL
            WHERE t.deleted_at IS NULL
              AND t.parent_id IS NULL
              AND (
                  date(t.start_at / 1000000, 'unixepoch') = date('now')
                  OR date(t.due_at / 1000000, 'unixepoch') = date('now')
                  OR date(toc.occurrence_at / 1000000, 'unixepoch') = date('now')
                  OR (t.start_at IS NULL AND t.due_at IS NULL AND t.priority IS NOT NULL)
              )
            ORDER BY t."order" ASC, t.created_at ASC
            LIMIT 50
        """, null)
        
        while (cursor.moveToNext()) {
            tasks.add(TaskRecord.fromCursor(cursor))
        }
        cursor.close()
        db.close()
        return tasks
    }
}

data class TaskRecord(
    val id: String,
    val title: String,
    val priority: String?,
    val parentId: String?,
    val layer: Int,
    val alarms: String?,
    val completedAt: Long?,
    val activityDeletedAt: Long?
) {
    val isCompleted: Boolean
        get() = completedAt != null && completedAt > 0 && activityDeletedAt == null
    
    val hasAlarm: Boolean
        get() = !alarms.isNullOrBlank()
    
    companion object {
        fun fromCursor(cursor: Cursor): TaskRecord = TaskRecord(
            id = cursor.getString(cursor.getColumnIndexOrThrow("id")),
            title = cursor.getString(cursor.getColumnIndexOrThrow("title")),
            priority = cursor.getString(cursor.getColumnIndexOrThrow("priority")),
            parentId = cursor.getString(cursor.getColumnIndexOrThrow("parent_id")),
            layer = cursor.getInt(cursor.getColumnIndexOrThrow("layer")),
            alarms = cursor.getString(cursor.getColumnIndexOrThrow("alarms")),
            completedAt = cursor.getLongOrNull(cursor.getColumnIndexOrThrow("completed_at")),
            activityDeletedAt = cursor.getLongOrNull(cursor.getColumnIndexOrThrow("activity_deleted_at"))
        )
    }
}
```

---

## 10. 空状态与异常处理

| 场景 | 展示方式 |
|------|---------|
| 象限无任务 | "✅ 已清空" |
| 收集箱为空 | "🎉 收集箱已清空" |
| 数据库读取失败 | 展示缓存数据或空状态占位 |
| WAL 文件缺失 | 降级为只读模式，跳过 WAL |
| App 未安装 | 无操作 |
| 用户未登录 | 正常显示（本地数据已存在） |

---

## 11. 开发排期建议

| 阶段 | 内容 | 预估工时 |
|------|------|---------|
| Phase 1 | Flutter 配置层（theme/locale 同步）+ 刷新通知通道 | 0.5d |
| Phase 2 | iOS GRDB 集成 + TaskRecord/TagRecord 定义 + 基础查询 | 1d |
| Phase 3 | iOS 四象限大号/中号组件（含 AppIntent） | 1.5d |
| Phase 4 | iOS 收集箱大号/中号组件 | 1d |
| Phase 5 | iOS 快速笔记 + WidgetBundle 整合 | 0.5d |
| Phase 6 | Android SQLite 查询层 + 全部组件 | 2d |
| Phase 7 | 多语言 + 主题适配联调 | 0.5d |
| **总计** | | **~7d** |

---

## 12. 附录：象限颜色对照表

| 象限 | Priority | 中文标题 | Hex (浅色) | Hex (深色) |
|------|----------|---------|-----------|-----------|
| 一 | `high` | 重要且紧急 | `#FF6B6B` | `#FF8787` |
| 二 | `medium` | 重要不紧急 | `#4DABF7` | `#74C0FC` |
| 三 | `low` | 紧急不重要 | `#FCC419` | `#FFD43B` |
| 四 | `none` | 不紧急不重要 | `#69DB7C` | `#8CE99A` |

> 实际颜色以 `widget_theme` 中 `priorityColors` 的值为准，上表为默认主题参考值。
