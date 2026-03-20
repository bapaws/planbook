# 小组件直接访问数据库方案分析

## 概述

本文档分析让小组件直接访问 SQLite 数据库的方案，对比现有的 JSON 推送方案。

## 现状

目前数据库文件**已经**存放在 App Group 中：

```dart
// packages/planbook_api/lib/database/database.dart

static Future<File> getDatabaseFile() async {
  String? path;
  if (Platform.isIOS) {
    final providerFoundation = PathProviderFoundation();
    path = await providerFoundation.getContainerPath(
      appGroupIdentifier: kAppGroupId,  // "group.GM4766U38W.com.bapaws.habits"
    );
  }
  path ??= (await getApplicationDocumentsDirectory()).path;
  final file = File(p.join(path, 'habits.sqlite'));
  return file;
}
```

这意味着**技术上完全可行**，iOS 小组件和 Android 小组件都可以直接访问这个数据库文件。

---

## 方案对比

### 方案 A: JSON 推送方案 (当前推荐)

```
Flutter App → 查询 Drift → 序列化为 JSON → 保存到 Shared Storage → 小组件读取 JSON
```

**优点:**
1. ✅ 实现简单，小组件只需要解析 JSON
2. ✅ 查询逻辑集中在 Flutter 端，易于维护
3. ✅ 数据格式针对小组件优化，读取速度快
4. ✅ 不受小组件内存/时间限制影响
5. ✅ 数据库 schema 变更不影响小组件
6. ✅ 没有并发访问冲突问题

**缺点:**
1. ❌ 数据有延迟（虽然很短，约毫秒级）
2. ❌ 需要维护同步逻辑
3. ❌ 数据冗余（JSON 是数据库的副本）

---

### 方案 B: 小组件直接查询数据库

```
小组件 → 打开 SQLite → 执行 SQL 查询 → 渲染视图
                          ↑
Flutter App → 同时也在使用数据库
```

**优点:**
1. ✅ 数据实时性最好
2. ✅ 没有数据冗余
3. ✅ 小组件可以灵活查询（不需要提前定义 JSON 结构）

**缺点:**
1. ❌ **iOS 内存限制**：Widget 内存限制约 16-24MB，复杂查询可能导致内存警告
2. ❌ **iOS 时间限制**：Widget 刷新有时间限制（约 10-30 秒），复杂查询可能超时
3. ❌ **并发访问问题**：Flutter 和小组件同时访问可能导致数据库锁定
4. ❌ **实现复杂度高**：需要在原生端维护 SQL 查询逻辑
5. ❌ **维护成本高**：数据库 schema 变更需要同步更新原生代码
6. ❌ **测试困难**：需要同时测试 Flutter 和原生代码的兼容性

---

## 技术细节分析

### 1. iOS Widget 的限制

```swift
// iOS Widget 刷新机制
struct Provider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // ⚠️ 这里有时间限制！如果超过时间，Widget 会被系统终止
        
        // 复杂的数据库查询可能导致超时
        let tasks = DatabaseHelper.queryTodayTasks() // 如果查询慢，可能超时
        
        let entry = SimpleEntry(date: Date(), tasks: tasks)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}
```

**iOS Widget 限制：**
- 内存限制：约 16-24 MB
- 刷新时间：约 10-30 秒（复杂操作可能超时）
- 网络请求：不建议在 Widget 中直接发起

### 2. Android Widget 的限制

```kotlin
class TodayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        // ⚠️ onUpdate 在主线程执行，长时间操作会导致 ANR
        
        // 数据库查询必须在后台线程
        CoroutineScope(Dispatchers.IO).launch {
            val db = SQLiteDatabase.openDatabase(dbPath, ...)
            val tasks = db.query(...) // 复杂查询可能影响性能
            
            // 更新 UI 需要切回主线程
            withContext(Dispatchers.Main) {
                updateWidget(context, appWidgetManager, tasks)
            }
        }
    }
}
```

**Android Widget 限制：**
- `onUpdate` 在主线程执行
- 需要使用 RemoteViews，更新方式受限
- 后台服务限制（Android 12+）

### 3. 数据库并发访问问题

```
场景：Flutter 正在写入，小组件同时读取

Timeline:
┌─────────────┐              ┌─────────────┐
│  Flutter    │              │   Widget    │
│  App        │              │             │
├─────────────┤              ├─────────────┤
│ BEGIN       │              │             │
│ TRANSACTION │              │             │
│   INSERT    │              │  SELECT *   │
│   UPDATE    │              │  FROM tasks │
│   DELETE    │              │             │
│ COMMIT      │              │             │
└─────────────┘              └─────────────┘
         │                           │
         └───────────┬───────────────┘
                     ▼
            可能的并发冲突！
```

虽然 SQLite 支持 WAL 模式（项目中已启用）：
```dart
return NativeDatabase.createInBackground(
  file,
  setup: (database) {
    database
      // 启用 WAL 模式，允许并发读写
      ..execute('PRAGMA journal_mode=WAL;')
      ..execute('PRAGMA busy_timeout=10000;');
  },
);
```

但**原生端的小组件也需要正确配置**，否则可能出现：
- `database is locked` 错误
- 读到不完整的事务数据
- 性能下降

### 4. 实现复杂度对比

| 方面 | JSON 推送 | 直接访问数据库 |
|------|-----------|----------------|
| iOS 代码量 | ~200 行 | ~500+ 行 |
| Android 代码量 | ~300 行 | ~600+ 行 |
| 需要维护的 SQL 查询 | 0 个 | 5-10 个 |
| Schema 变更影响 | 无 | 需要同步更新原生代码 |
| 测试复杂度 | 低 | 高（需要测试并发） |

---

## 混合方案推荐

如果确实需要更好的实时性，可以考虑**混合方案**：

### 核心思路
1. **主要数据**：仍然使用 JSON 推送（保证性能）
2. **关键数据**：小组件直接查询数据库（保证实时性）

### 具体实现

```swift
// iOS: 只查询关键数据（如任务数量）
struct TodayWidgetProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // 1. 从 JSON 读取主要数据（任务列表）
        let widgetData = WidgetDataProvider.shared.loadWidgetData()
        var tasks = widgetData?.todayTasks ?? []
        
        // 2. 从数据库查询实时完成状态（只查询关键字段）
        let completedCount = DatabaseHelper.queryTodayCompletedCount()
        
        // 3. 更新完成状态
        tasks = tasks.map { task in
            var mutableTask = task
            mutableTask.isCompleted = DatabaseHelper.isTaskCompleted(task.id)
            return mutableTask
        }
        
        let entry = TodayWidgetEntry(
            date: Date(),
            tasks: tasks,
            completedCount: completedCount
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}
```

```kotlin
// Android: 轻量级数据库查询
class TodayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        // 1. 从 SharedPreferences 读取主要数据
        val dataProvider = WidgetDataProvider(context)
        val tasks = dataProvider.getTodayTasks(5)
        
        // 2. 只查询完成状态（轻量级查询）
        val db = SQLiteDatabase.openDatabase(dbPath, null, SQLiteDatabase.OPEN_READONLY)
        tasks.forEach { task ->
            task.isCompleted = queryCompletedStatus(db, task.id)
        }
        db.close()
        
        // 更新小组件...
    }
    
    private fun queryCompletedStatus(db: SQLiteDatabase, taskId: String): Boolean {
        // 只查询单个字段，避免复杂查询
        val cursor = db.rawQuery(
            "SELECT 1 FROM task_activities WHERE task_id = ? AND completed_at >= ? LIMIT 1",
            arrayOf(taskId, startOfDay)
        )
        val isCompleted = cursor.moveToFirst()
        cursor.close()
        return isCompleted
    }
}
```

### 混合方案优势
1. ✅ 主要数据从 JSON 读取，性能不受影响
2. ✅ 关键状态（如完成状态）实时从数据库查询
3. ✅ 查询简单，不会触发内存/时间限制
4. ✅ 即使数据库查询失败，也能显示缓存数据

---

## 推荐的实现策略

### Phase 1: JSON 推送方案（必须）
先实现基础的 JSON 推送方案，这是最稳妥的选择。

### Phase 2: 优化同步频率
```dart
class WidgetDataService {
  // 1. 任务变更时立即同步
  Future<void> onTaskChanged() async {
    await updateAllWidgetData();
    await _reloadWidgets();
  }
  
  // 2. App 从后台恢复时同步
  Future<void> onAppResumed() async {
    await updateAllWidgetData();
    await _reloadWidgets();
  }
  
  // 3. 定时同步（每 15 分钟）
  void startPeriodicSync() {
    Timer.periodic(Duration(minutes: 15), (_) async {
      await updateAllWidgetData();
    });
  }
}
```

### Phase 3: 关键数据实时查询（可选）
如果发现完成状态有延迟感，可以只针对完成状态做实时查询。

---

## 代码示例：原生端数据库查询

如果决定使用数据库查询方案，这里是基础实现：

### iOS (Swift)

```swift
import SQLite3

class WidgetDatabaseHelper {
    static let shared = WidgetDatabaseHelper()
    
    private let dbPath: String
    
    private init() {
        let groupId = "group.GM4766U38W.com.bapaws.habits"
        let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupId)
        dbPath = container?.appendingPathComponent("habits.sqlite").path ?? ""
    }
    
    func queryTodayTasks() -> [WidgetTask] {
        var tasks: [WidgetTask] = []
        var db: OpaquePointer?
        
        // 只读模式打开
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return tasks
        }
        defer { sqlite3_close(db) }
        
        let query = """
            SELECT t.id, t.title, t.priority, t.due_at,
                   EXISTS(SELECT 1 FROM task_activities a 
                          WHERE a.task_id = t.id 
                          AND a.completed_at >= ?) as is_completed
            FROM tasks t
            WHERE t.deleted_at IS NULL
            AND (DATE(t.due_at) = DATE('now') OR DATE(t.start_at) = DATE('now'))
            ORDER BY t.priority ASC, t.created_at DESC
            LIMIT 10
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return tasks
        }
        defer { sqlite3_finalize(statement) }
        
        // 绑定今天开始时间参数
        let startOfDay = Calendar.current.startOfDay(for: Date())
        sqlite3_bind_int64(statement, 1, Int64(startOfDay.timeIntervalSince1970))
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let task = WidgetTask(
                id: String(cString: sqlite3_column_text(statement, 0)),
                title: String(cString: sqlite3_column_text(statement, 1)),
                priority: String(cString: sqlite3_column_text(statement, 2)),
                isCompleted: sqlite3_column_int(statement, 4) == 1
            )
            tasks.append(task)
        }
        
        return tasks
    }
}
```

### Android (Kotlin)

```kotlin
class WidgetDatabaseHelper(context: Context) {
    private val dbPath: String
    
    init {
        val prefs = context.getSharedPreferences("widget_data", Context.MODE_PRIVATE)
        dbPath = prefs.getString("db_path", null) 
            ?: "/data/data/com.bapaws.planbook/databases/habits.sqlite"
    }
    
    fun queryTodayTasks(): List<WidgetTask> {
        val tasks = mutableListOf<WidgetTask>()
        
        // 只读模式打开
        val db = SQLiteDatabase.openDatabase(
            dbPath, 
            null, 
            SQLiteDatabase.OPEN_READONLY or SQLiteDatabase.NO_LOCALIZED_COLLATORS
        )
        
        db.use { database ->
            val cursor = database.rawQuery(
                """
                SELECT t.id, t.title, t.priority, t.due_at,
                       EXISTS(SELECT 1 FROM task_activities a 
                              WHERE a.task_id = t.id 
                              AND a.completed_at >= ?) as is_completed
                FROM tasks t
                WHERE t.deleted_at IS NULL
                AND (DATE(t.due_at / 1000, 'unixepoch') = DATE('now') 
                     OR DATE(t.start_at / 1000, 'unixepoch') = DATE('now'))
                ORDER BY t.priority ASC, t.created_at DESC
                LIMIT 10
                """,
                arrayOf(getStartOfDay().toString())
            )
            
            cursor.use {
                while (it.moveToNext()) {
                    tasks.add(WidgetTask(
                        id = it.getString(0),
                        title = it.getString(1),
                        priority = it.getString(2),
                        isCompleted = it.getInt(4) == 1
                    ))
                }
            }
        }
        
        return tasks
    }
    
    private fun getStartOfDay(): Long {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }
}
```

---

## 总结建议

| 场景 | 推荐方案 | 理由 |
|------|----------|------|
| **默认情况** | JSON 推送 | 简单、稳定、易于维护 |
| **实时性要求高** | 混合方案 | 兼顾性能和实时性 |
| **大量数据** | JSON 推送 | 避免 Widget 内存问题 |
| **简单计数** | 直接查询 | 查询简单，不会超时 |

### 最终建议

**使用 JSON 推送方案作为主要方案**，原因：

1. **项目现状**：Drift 已经在使用，schema 可能会变更
2. **团队效率**：不需要维护两套 SQL 查询逻辑
3. **稳定性**：避免 Widget 的内存/时间限制问题
4. **测试成本**：减少并发访问的测试复杂度

**如果实时性不够，优化策略**：
1. 增加同步频率（任务变更时立即同步）
2. 使用 `WidgetCenter.shared.reloadAllTimelines()` 强制刷新
3. 必要时使用混合方案，只针对关键数据做实时查询

直接访问数据库的方案**技术上可行**，但会增加开发和维护成本，建议只在 JSON 方案不能满足需求时再考虑。
