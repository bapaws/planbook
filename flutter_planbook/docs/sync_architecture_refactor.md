# Planbook 同步架构改造方案

> **版本**: v2.0 — DatabaseApi 自管理 Outbox  
> **状态**: 待评审  
> **作者**: Kimi Code  
> **日期**: 2026-05-11  
> **范围**: `packages/planbook_api`, `packages/database_planbook_api`, `packages/planbook_repository`, `packages/supabase_planbook_api`, `lib/bootstrap.dart`, `lib/app/bloc`

---

## 目录

1. [执行摘要](#1-执行摘要)
2. [现状诊断](#2-现状诊断)
3. [架构决策](#3-架构决策)
4. [核心设计](#4-核心设计)
5. [具体实施](#5-具体实施)
6. [数据库变更](#6-数据库变更)
7. [代码变更](#7-代码变更)
8. [测试方案](#8-测试方案)
9. [上线与迁移](#9-上线与迁移)
10. [风险与应对](#10-风险与应对)
11. [后续优化](#11-后续优化)
12. [附录](#12-附录)

---

## 1. 执行摘要

### 问题

当前写路径为"先 Supabase 后本地 Drift"，断网时 Supabase 抛异常 → 本地永远写不进去 → **数据直接丢失**。`SyncRepository.sync()` 是死代码（被注释掉），无 Outbox、无重试、无网络监听。

### 方案

1. **本地优先**：所有写操作先落盘本地，用户无感知。
2. **DatabaseApi 自管理 Outbox**：`DatabaseTaskApi`/`DatabaseNoteApi`/`DatabaseTagApi` 在事务中自动将变更写入 `sync_outbox` 表，Repository 层完全无感知。
3. **SyncEngine 后台排空**：监听网络变化 + 30 秒兜底，自动将 Outbox 推送到 Supabase。
4. **统一软删除**：Supabase 端不再物理删除，全部通过 `deleted_at` 标记。

### 预期效果

- 断网时创建 Task/Note/Tag → 本地成功，UI 正常展示。
- 恢复网络后 → 自动同步到 Supabase，无需用户操作。
- Repository 层代码量减少约 **60%**。
- **零遗漏**：新增 DatabaseApi 时编译器强制要求注入 `OutboxApi`。

---

## 2. 现状诊断

### 2.1 关键事实

| # | 事实 | 源码位置 | 影响 |
|---|------|----------|------|
| 1 | **写路径为先 Supabase 后本地** | `TasksRepository.create()` / `NotesRepository.create()` / `TasksRepository.completeTask()` / `delayTask()` / `updateWithEditMode()` | 断网时 Supabase 抛异常，本地**永远写不进去** |
| 2 | **`SyncRepository.sync()` 是死代码** | `AppBloc._onUserProfileRequested()` 整段被注释 | 换设备/重新登录后本地历史数据无法推送到云端 |
| 3 | **Notes 远端硬删除、Tasks 远端软删除** | `SupabaseNoteApi.deleteByNoteId()` 用 `.delete()`；`SupabaseTaskApi.deleteByTaskId()` update `deleted_at` | 同步语义不一致，跨设备无法同步删除状态 |
| 4 | **无 Outbox / 重试 / 网络监听** | 全局搜索 `outbox`、`retry`、`connectivity` 均无结果 | 写操作一旦失败即永久丢失 |
| 5 | **Schema 底子优秀** | 所有主表具备 `id`(UUID)、`createdAt`、`updatedAt`、`deletedAt` | 无需大规模改表，直接可用 |

### 2.2 当前写路径时序

```
用户点击保存
    │
    ▼
┌─────────────────┐
│ SupabaseTaskApi │  create() ──► 网络异常 ──► 抛出异常，本地未执行
└─────────────────┘
         │
         ▼ (仅在远端成功后)
┌─────────────────┐
│ DatabaseTaskApi │  create() ──► 本地写入
└─────────────────┘
```

### 2.3 删除语义不一致

```
┌──────────────┬──────────────────┬──────────────────┐
│   层级       │      Tasks       │      Notes       │
├──────────────┼──────────────────┼──────────────────┤
│ 本地 Drift   │ 软删除(deletedAt)│ 软删除(deletedAt)│
│ Supabase     │ 软删除(deletedAt)│ 硬删除(DELETE)   │  ◄── 不一致
└──────────────┴──────────────────┴──────────────────┘
```

---

## 3. 架构决策

### 3.1 决策 1：本地优先（Local-First）

所有写操作必须先写入本地 SQLite，再异步同步到 Supabase。这是离线可用的前提。

### 3.2 决策 2：Outbox 入队放在 DatabaseApi 层

| 方案 | 防遗漏能力 | Repository 侵入性 | 结论 |
|------|-----------|-------------------|------|
| A. Repository 手动 `enqueue` | ❌ 容易忘 | 高（每个方法塞 5-10 行） | 否决 |
| B. SyncCoordinator 中间层 | ⚠️ 可绕过 | 中 | 否决 |
| C. Drift `tableUpdates` 监听 | ❌ 无法得知记录级变更 | 无 | 否决 |
| D. SQLite 原生触发器 | ❌ 无法生成 JSON payload | 无 | 否决 |
| **E. DatabaseApi 自管理 Outbox** | ✅ 编译器强制注入 | **零侵入** | **采用** |

**理由**：
- `DatabaseTaskApi`/`DatabaseNoteApi`/`DatabaseTagApi` 的构造函数强制要求 `OutboxApi`。
- 所有 `create`/`update`/`delete` 方法内部自动完成 Outbox 入队。
- Repository 只调用 DatabaseApi，完全不感知 Outbox 的存在。
- 新增 DatabaseApi 时如果不注入 `OutboxApi`，编译直接报错。

### 3.3 决策 3：关联表采用 replace_associations 策略

`task_tags` / `note_tags` 在 update 时不逐条发 delete/insert，而是打包为一条 `replace_associations` Outbox 记录：`SyncEngine` 执行时先按 `task_id`/`note_id` 软删除旧关联，再批量插入新关联。

---

## 4. 核心设计

### 4.1 数据流

```
用户操作
    │
    ▼
┌─────────────────┐
│  Repository 层   │  纯业务逻辑，组装数据
│  （零 Outbox）   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  DatabaseApi 层  │  ① 写入本地业务表
│ （自管理 Outbox）│  ② 同一事务自动写入 sync_outbox
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   SyncEngine    │  监听网络变化 / 30s 兜底
│  （后台排空）    │  读取 Outbox → 推送 Supabase → 标记 synced
└─────────────────┘
         │
         ▼
┌─────────────────┐
│    Supabase     │
└─────────────────┘
```

### 4.2 核心组件

| 组件 | 职责 | 生命周期 |
|------|------|----------|
| `SyncOutbox` 表 | 记录待同步的变更（表名、记录ID、操作、payload、重试计数） | 持久化 |
| `OutboxApi` | Outbox 表的增删查改 | 与 `AppDatabase` 同生命周期 |
| `SyncEngine` | 监听网络、排空 Outbox、指数退避重试、死信处理 | `bootstrap()` 创建，`runApp` 前 `start()` |
| `DatabaseTaskApi` | Task 本地读写 + **自动 Outbox** | Repository 内创建 |
| `DatabaseNoteApi` | Note 本地读写 + **自动 Outbox** | Repository 内创建 |
| `DatabaseTagApi` | Tag 本地读写 + **自动 Outbox** | Repository 内创建 |

### 4.3 事务边界

```
┌─────────────────────────────────────────┐
│           db.transaction()              │
│  ┌─────────────────────────────────┐    │
│  │  doCreate() / doUpdate()        │    │
│  │  - insert into tasks            │    │
│  │  - insert into task_tags        │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │  doOutbox(txn)                  │    │
│  │  - insert into sync_outbox      │    │
│  │    (tasks insert)               │    │
│  │  - insert into sync_outbox      │    │
│  │    (task_tags replace_assoc)    │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
         ▲
         │ 失败时整体回滚：本地业务表和 Outbox 同时回滚
```

---

## 5. 具体实施

### 5.1 新增依赖

```yaml
# pubspec.yaml
dependencies:
  connectivity_plus: ^6.1.4          # 网络接口状态监听
  internet_connection_checker: ^3.0.1 # 真实互联网连通性探测
```

### 5.2 OutboxApi

```dart
// packages/database_planbook_api/lib/sync/outbox_api.dart

class OutboxApi {
  OutboxApi({required AppDatabase db}) : _db = db;
  final AppDatabase _db;

  Future<void> enqueue({
    required String tableName,
    required String recordId,
    required String operation,
    required String payload,
    required Transaction txn,
  }) async {
    await txn.into(_db.syncOutbox).insert(SyncOutboxCompanion(
      tableName: Value(tableName),
      recordId: Value(recordId),
      operation: Value(operation),
      payload: Value(payload),
      createdAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<List<SyncOutboxData>> getPending({int limit = 50}) async { ... }
  Future<void> markSynced(int outboxId) async { ... }
  Future<void> markFailed({required int outboxId, required String error, required int retryCount}) async { ... }
  Future<int> cleanup({int retainDays = 7}) async { ... }
}
```

### 5.3 SyncEngine

```dart
// packages/planbook_repository/lib/sync/sync_engine.dart

class SyncEngine {
  SyncEngine({required OutboxApi outboxApi, required SupabaseClient? supabase})
      : _outboxApi = outboxApi, _supabase = supabase;

  final OutboxApi _outboxApi;
  final SupabaseClient? _supabase;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;
  bool _isProcessing = false;

  String? get _userId => _supabase?.auth.currentUser?.id;

  void start() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile)) {
        _triggerSync();
      }
    });
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) => _triggerSync());
  }

  void triggerSync() => _triggerSync();

  void _triggerSync() {
    if (_isProcessing || _userId == null) return;
    unawaited(_processOutbox());
  }

  Future<void> _processOutbox() async {
    _isProcessing = true;
    try {
      if (!await InternetConnectionChecker().hasConnection) return;
      final pending = await _outboxApi.getPending(limit: 50);
      if (pending.isEmpty) return;

      for (final item in pending) {
        try {
          await _syncSingle(item);
          await _outboxApi.markSynced(item.id);
        } on PostgrestException catch (e) {
          final newRetry = item.retryCount + 1;
          await _outboxApi.markFailed(outboxId: item.id, error: e.message ?? '', retryCount: newRetry);
          if (e.code?.startsWith('4') ?? false) {
            await _outboxApi.markSynced(item.id); // 4xx 死信，不再重试
          }
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _syncSingle(SyncOutboxData item) async {
    if (_supabase == null) throw Exception('Supabase not initialized');
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    payload['user_id'] = _userId;

    final table = _supabase!.from(item.tableName);
    switch (item.operation) {
      case 'insert':
      case 'update':
        await table.upsert([payload], onConflict: 'id');
      case 'delete':
        await table.update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', item.recordId);
      case 'replace_associations':
        final parentId = payload['parent_id'] as String;
        final associations = payload['associations'] as List<dynamic>?;
        final parentColumn = '${item.tableName.split('_').first}_id';
        await table.update({'deleted_at': DateTime.now().toIso8601String()}).eq(parentColumn, parentId);
        if (associations != null && associations.isNotEmpty) {
          await table.insert(associations.cast<Map<String, dynamic>>());
        }
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
  }
}
```

### 5.4 bootstrap 与 AppBloc

```dart
// lib/bootstrap.dart

final outboxApi = OutboxApi(db: db);
final syncEngine = SyncEngine(outboxApi: outboxApi, supabase: AppSupabase.client);
syncEngine.start(); // 单例，runApp 前启动

final tasksRepository = TasksRepository(
  tagApi: tagApi,
  sp: sp,
  db: db,
  outboxApi: outboxApi, // 传入给 DatabaseApi 使用
);

// lib/app/bloc/app_bloc.dart

class AppBloc extends Bloc<AppEvent, AppState> with WidgetsBindingObserver {
  AppBloc({required SyncEngine syncEngine, ...}) : _syncEngine = syncEngine, ... {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncEngine.triggerSync();
  }

  Future<void> _onUserProfileRequested(...) async {
    await emit.forEach(_usersRepository.onUserEntityChange, onData: (user) {
      if (user != null && user.id != state.user?.id) {
        unawaited(_tasksRepository.syncTasks(force: true));
        unawaited(_notesRepository.syncNotes(force: true));
        _syncEngine.triggerSync();
      }
      return state.copyWith(user: user);
    });
  }

  @override
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    await super.close();
  }
}
```

---

## 6. 数据库变更

### 6.1 新增 SyncOutbox 表

```dart
// packages/planbook_api/lib/database/database.dart

class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // insert | update | delete | replace_associations
  TextColumn get payload => text()();
  IntColumn get createdAt => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get syncedAt => integer().nullable()();
  IntColumn get nextRetryAt => integer().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK (operation IN ("insert", "update", "delete", "replace_associations"))',
  ];
}
```

### 6.2 迁移策略

```dart
@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(notes, notes.type);
        await m.addColumn(notes, notes.focusAt);
      }
      if (from < 3) {
        await m.createTable(syncOutbox);
      }
    },
  );
}
```

---

## 7. 代码变更

### 7.1 DatabaseApi 层（核心）

**改造模式**：所有 DatabaseApi 的 `create`/`update`/`delete` 方法内部自动入 Outbox。

#### 7.1.1 DatabaseTaskApi

```dart
class DatabaseTaskApi {
  DatabaseTaskApi({
    required this.db,
    required this.tagApi,
    required OutboxApi outboxApi, // ◄── 强制注入
  }) : _outboxApi = outboxApi;

  final AppDatabase db;
  final DatabaseTagApi tagApi;
  final OutboxApi _outboxApi;

  // 辅助：camelCase → snake_case
  static Map<String, dynamic> _toSnakeCaseJson(Map<String, dynamic> json) { ... }

  Future<void> create({
    required Task task,
    List<TaskTag>? taskTags,
    List<Task>? children,
    Transaction? txn,
  }) async {
    final executor = txn ?? db;

    Future<void> doCreate() async {
      await executor.into(db.tasks).insert(task);
      for (final tt in taskTags ?? []) await executor.into(db.taskTags).insert(tt);
      for (final child in children ?? []) await executor.into(db.tasks).insert(child);
    }

    Future<void> doOutbox(Transaction t) async {
      await _outboxApi.enqueue(tableName: 'tasks', recordId: task.id, operation: 'insert', payload: jsonEncode(_toSnakeCaseJson(task.toJson())), txn: t);
      for (final child in children ?? []) {
        await _outboxApi.enqueue(tableName: 'tasks', recordId: child.id, operation: 'insert', payload: jsonEncode(_toSnakeCaseJson(child.toJson())), txn: t);
      }
      if (taskTags != null && taskTags.isNotEmpty) {
        await _outboxApi.enqueue(
          tableName: 'task_tags', recordId: task.id, operation: 'replace_associations',
          payload: jsonEncode({'parent_id': task.id, 'associations': taskTags.map((t) => _toSnakeCaseJson(t.toJson())).toList()}),
          txn: t,
        );
      }
    }

    if (txn == null) {
      await db.transaction((t) async { await doCreate(); await doOutbox(t); });
    } else {
      await doCreate();
      await doOutbox(txn);
    }
  }

  Future<Task?> deleteTaskById(String taskId, {Transaction? txn}) async {
    final executor = txn ?? db;

    Future<Task?> doDelete() async {
      if (kDebugMode) {
        return (executor.delete(db.tasks)..where((t) => t.id.equals(taskId))).goAndReturn().then((v) => v.firstOrNull);
      }
      return (executor.update(db.tasks)..where((t) => t.id.equals(taskId) & t.deletedAt.isNull()))
          .writeReturning(TasksCompanion(deletedAt: Value(Jiffy.now()))).then((v) => v.firstOrNull);
    }

    Future<void> doOutbox(Transaction t) async {
      await _outboxApi.enqueue(tableName: 'tasks', recordId: taskId, operation: 'delete', payload: jsonEncode({'id': taskId, 'deleted_at': Jiffy.now().toIso8601String()}), txn: t);
    }

    if (txn == null) {
      return db.transaction((t) async { final task = await doDelete(); if (task != null) await doOutbox(t); return task; });
    } else {
      final task = await doDelete();
      if (task != null) await doOutbox(txn);
      return task;
    }
  }

  // getTaskById, getTaskEntityById, buildTaskEntities 等读方法保持不变
}
```

#### 7.1.2 其他 DatabaseApi（同理）

| 文件 | 改造内容 |
|------|----------|
| `database_task_update_api.dart` | `update()` / `saveUpdateResult()` 内部自动入 Outbox |
| `database_task_completion_api.dart` | `completeTaskByActivities()` 内部自动入 Outbox（每条 activity 一条记录） |
| `database_task_delay_api.dart` | `softDeleteOccurrence()` 增加 `Transaction? txn` 参数 |
| `database_note_api.dart` | `create()` / `update()` / `deleteNoteById()` 内部自动入 Outbox |
| `database_tag_api.dart` | `create()` / `update()` / `deleteTagById()` 内部自动入 Outbox（含子标签级联） |

### 7.2 Repository 层（大幅简化）

#### 7.2.1 TasksRepository（前后对比）

**改造前**：
```dart
Future<void> create({required Task task, ...}) async {
  final newTask = ...;
  await _supabaseTaskApi.create(task: newTask, ...);   // ① 先远端（断网即丢）
  await _dbTaskApi.create(task: newTask, ...);          // ② 后本地
}
```

**改造后**：
```dart
Future<void> create({required Task task, List<TagEntity>? tags, List<TaskEntity>? children}) async {
  final newTask = task.copyWith(userId: Value(userId), childCount: children?.length ?? 0, updatedAt: Value(Jiffy.now()));
  final taskTags = _dbTaskApi.generateTaskTags(task: newTask, tags: tags, userId: userId);
  final newChildren = children?.map((e) => e.task.copyWith(...)).toList();

  // ◄── 只有一行。Outbox 由 DatabaseTaskApi.create 内部自动处理
  await _dbTaskApi.create(task: newTask, taskTags: taskTags, children: newChildren);

  unawaited(AppHomeWidget.refreshQuadrantWidgets());
}
```

**`completeTask` 改造后**：
```dart
Future<List<TaskActivity>> completeTask(TaskEntity entity, {Jiffy? completedAt, Jiffy? occurrenceAt}) async {
  final activities = await _dbTaskCompletionApi.completeTask(entity, completedAt: completedAt, occurrenceAt: occurrenceAt);
  if (userId != null) {
    for (var i = 0; i < activities.length; i++) {
      activities[i] = activities[i].copyWith(userId: Value(userId));
    }
  }
  await _dbTaskCompletionApi.completeTaskByActivities(activities); // 自动 Outbox
  unawaited(AppHomeWidget.refreshQuadrantWidgets());
  return activities;
}
```

#### 7.2.2 NotesRepository / TagsRepository

同理大幅简化。`create`/`update`/`delete` 均只有一行 DatabaseApi 调用。

### 7.3 SupabaseApi 层（删除语义统一）

```dart
// packages/supabase_planbook_api/lib/note/supabase_note_api.dart

Future<void> deleteByNoteId({required String noteId}) async {
  if (supabase == null) return;
  await supabase!.from('notes').update({
    'deleted_at': DateTime.now().toIso8601String(),
  }).eq('id', noteId);
  await supabase!.from('note_tags').update({
    'deleted_at': DateTime.now().toIso8601String(),
  }).eq('note_id', noteId);
}
```

`SupabaseTaskApi.deleteByTaskId` 同理，删除 debug 硬删除分支，统一为软删除。

### 7.4 读路径拉取（防覆盖）

```dart
Future<void> syncTasks({bool force = false}) async {
  final list = await _supabaseTaskApi.getLatestTasks(force: force);
  await _db.transaction(() async {
    for (final item in list) {
      final task = Task.fromJson(item);

      // ◄── 防覆盖：本地有 pending Outbox 时不覆盖
      final hasPending = await _db.selectOnly(_db.syncOutbox)
        ..addColumns([_db.syncOutbox.id.count()])
        ..where(_db.syncOutbox.recordId.equals(task.id) & _db.syncOutbox.syncedAt.isNull());
      final pendingCount = (await hasPending.getSingleOrNull())?.read(_db.syncOutbox.id.count()) ?? 0;
      if (pendingCount > 0) continue;

      await _db.into(_db.tasks).insertOnConflictUpdate(task);
      // ... task_tags、task_activities 处理
    }
  });
}
```

---

## 8. 测试方案

### 8.1 OutboxApi 测试

```dart
void main() {
  late AppDatabase db;
  late OutboxApi api;

  setUp(() { db = AppDatabase(NativeDatabase.memory()); api = OutboxApi(db: db); });
  tearDown(() => db.close());

  test('enqueue 应在事务中插入记录', () async {
    await db.transaction((txn) async {
      await api.enqueue(tableName: 'tasks', recordId: 't1', operation: 'insert', payload: '{}', txn: txn);
    });
    final pending = await api.getPending();
    expect(pending.length, 1);
    expect(pending.first.syncedAt, isNull);
  });

  test('事务回滚时 Outbox 不应残留', () async {
    try {
      await db.transaction((txn) async {
        await api.enqueue(tableName: 'tasks', recordId: 't2', operation: 'insert', payload: '{}', txn: txn);
        throw Exception('rollback');
      });
    } catch (_) {}
    expect(await api.getPending(), isEmpty);
  });
}
```

### 8.2 SyncEngine 测试

```dart
void main() {
  late MockOutboxApi outboxApi;
  late MockSupabaseClient supabase;
  late SyncEngine engine;

  setUp(() {
    outboxApi = MockOutboxApi();
    supabase = MockSupabaseClient();
    engine = SyncEngine(outboxApi: outboxApi, supabase: supabase);
  });

  test('空 Outbox 不调用 Supabase', () async {
    when(() => outboxApi.getPending(limit: any(named: 'limit'))).thenAnswer((_) async => []);
    engine.triggerSync();
    await Future.delayed(Duration(milliseconds: 100));
    verifyNever(() => outboxApi.markSynced(any()));
  });

  test('并发触发只执行一次', () async {
    when(() => outboxApi.getPending(limit: any(named: 'limit')))
        .thenAnswer((_) async { await Future.delayed(Duration(seconds: 1)); return []; });
    engine.triggerSync();
    engine.triggerSync();
    await Future.delayed(Duration(milliseconds: 100));
    verify(() => outboxApi.getPending(limit: any(named: 'limit'))).called(1);
  });
}
```

### 8.3 DatabaseTaskApi 集成测试（验证自动 Outbox）

```dart
void main() {
  late AppDatabase db;
  late DatabaseTaskApi taskApi;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final outboxApi = OutboxApi(db: db);
    final tagApi = DatabaseTagApi(db: db, outboxApi: outboxApi);
    taskApi = DatabaseTaskApi(db: db, tagApi: tagApi, outboxApi: outboxApi);
  });
  tearDown(() => db.close());

  test('create 自动产生 Outbox', () async {
    final task = Task(id: 't1', title: 'test', createdAt: Jiffy.now());
    await taskApi.create(task: task);

    expect(await db.select(db.tasks).get(), hasLength(1));

    final outbox = await db.select(db.syncOutbox).get();
    expect(outbox, hasLength(1));
    expect(outbox.first.operation, 'insert');
    expect(outbox.first.tableName, 'tasks');
  });

  test('deleteTaskById 自动产生 delete Outbox', () async {
    final task = Task(id: 't2', title: 'del', createdAt: Jiffy.now());
    await taskApi.create(task: task);
    await taskApi.deleteTaskById('t2');

    final local = await (db.select(db.tasks)..where((t) => t.id.equals('t2'))).getSingle();
    expect(local.deletedAt, isNotNull);

    final outbox = await (db.select(db.syncOutbox)
          ..where((o) => o.recordId.equals('t2') & o.operation.equals('delete')))
        .get();
    expect(outbox, hasLength(1));
  });
}
```

---

## 9. 上线与迁移

### 9.1 数据库迁移

- `schemaVersion` 2 → 3，`onUpgrade` 中 `await m.createTable(syncOutbox)`。
- iOS App Group 容器中的 WAL 文件（`-wal` / `-shm`）权限需正常。
- **建议**：升级前备份数据库到 `Documents/Backups/planbook_v2_backup.sqlite`。

### 9.2 存量数据

- **第一期不处理历史存量**（从未上云的数据）。仅在用户再次编辑时通过正常 `update` 流程自动入 Outbox。
- 若需一次性全量补传，单独写离线脚本，不保留死代码 `SyncRepository`。

### 9.3 Supabase 端 DDL（上线前必须执行）

#### 索引

```sql
CREATE INDEX idx_tasks_deleted_at ON tasks(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_notes_deleted_at ON notes(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_task_tags_deleted_at ON task_tags(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_note_tags_deleted_at ON note_tags(deleted_at) WHERE deleted_at IS NULL;
```

#### 级联软删除触发器

```sql
-- tasks → task_tags
CREATE OR REPLACE FUNCTION cascade_soft_delete_task_tags()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE task_tags SET deleted_at = NOW()
  WHERE task_id = OLD.id AND deleted_at IS NULL;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cascade_soft_delete_task_tags
  BEFORE UPDATE OF deleted_at ON tasks
  FOR EACH ROW
  WHEN (NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL)
  EXECUTE FUNCTION cascade_soft_delete_task_tags();

-- notes → note_tags
CREATE OR REPLACE FUNCTION cascade_soft_delete_note_tags()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE note_tags SET deleted_at = NOW()
  WHERE note_id = OLD.id AND deleted_at IS NULL;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cascade_soft_delete_note_tags
  BEFORE UPDATE OF deleted_at ON notes
  FOR EACH ROW
  WHEN (NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL)
  EXECUTE FUNCTION cascade_soft_delete_note_tags();

-- tags → child tags（可选）
CREATE OR REPLACE FUNCTION cascade_soft_delete_child_tags()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE tags SET deleted_at = NOW()
  WHERE parent_id = OLD.id AND deleted_at IS NULL;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cascade_soft_delete_child_tags
  BEFORE UPDATE OF deleted_at ON tags
  FOR EACH ROW
  WHEN (NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL)
  EXECUTE FUNCTION cascade_soft_delete_child_tags();
```

---

## 10. 风险与应对

| 风险 | 可能性 | 影响 | 应对措施 |
|------|--------|------|----------|
| DatabaseApi 内部事务过长 | 低 | 阻塞 Drift isolate | 单次事务只包含一条业务记录 + 关联 Tags（通常 ≤ 10 条 SQL） |
| Outbox 无限膨胀 | 低 | 存储增长 | `SyncEngine` 定期 `cleanup()` 删除已同步 7 天以上的记录 |
| 同一记录高频编辑导致堆积 | 中 | 冗余同步 | 允许多条 pending；`SyncEngine` 顺序执行，最终一致。二期合并去重 |
| 网络抖动导致频繁重试 | 高 | 电量消耗 | 指数退避 1s→2s→4s→...→60s；4xx 直接标记死信 |
| 多设备同时编辑 | 低 | LWW 冲突 | 接受 LWW；`syncTasks()` 本地有 pending 时不覆盖 |
| 离线 Note 图片 URL 无效 | 中 | 其他设备看不到图 | 一期已知限制；二期实现图片离线缓存 + Storage 上传 |
| 新 DatabaseApi 忘记注入 OutboxApi | 低 | 数据未同步 | **编译器兜底**：构造函数强制要求 `OutboxApi`，不写就编译报错 |
| schemaVersion 升级失败 | 低 | 崩溃/丢数据 | `onUpgrade` 加 `try/catch`，失败回退并上报 |

---

## 11. 后续优化

| 优化项 | 说明 |
|--------|------|
| Outbox 合并去重 | 同一 `recordId` 的多次 `update` 合并为最后一条 |
| 同步进度 UI | 设置页显示"正在同步 / 已同步" |
| 冲突解决策略 | 引入 `version` 或 vector clock，替代 LWW |
| 图片离线同步 | 离线创建带图片 Note 时，图片先入本地缓存，联网后上传 Supabase Storage 再同步 |
| 端到端加密 | payload 入 Outbox 前加密 |
| 后台同步 | `workmanager` 应用后台时定期排空 Outbox |
| 批量同步 | 按表批量 upsert（如一次 upsert 50 条 tasks） |

---

## 12. 附录

### A. 关键术语

| 术语 | 说明 |
|------|------|
| Outbox | 待同步变更队列，本地优先架构的核心组件 |
| LWW | Last-Write-Wins，最后写入者获胜 |
| RLS | Row Level Security，PostgreSQL 行级安全策略 |
| 软删除 | 更新 `deleted_at` 字段，不物理删除 |
| 指数退避 | 重试间隔按指数增长（1s, 2s, 4s...） |

### B. 字段名映射速查表

| Dart (camelCase) | Supabase (snake_case) |
|------------------|----------------------|
| `userId` | `user_id` |
| `createdAt` | `created_at` |
| `updatedAt` | `updated_at` |
| `deletedAt` | `deleted_at` |
| `parentId` | `parent_id` |
| `taskId` | `task_id` |
| `noteId` | `note_id` |
| `tagId` | `tag_id` |
| `linkedTagId` | `linked_tag_id` |
| `childCount` | `child_count` |
| `detachedFromTaskId` | `detached_from_task_id` |
| `detachedRecurrenceAt` | `detached_recurrence_at` |
| `detachedReason` | `detached_reason` |
| `recurrenceRule` | `recurrence_rule` |
| `isAllDay` | `is_all_day` |
| `dueAt` | `due_at` |
| `startAt` | `start_at` |
| `endAt` | `end_at` |
| `focusAt` | `focus_at` |
| `occurrenceAt` | `occurrence_at` |
| `activityType` | `activity_type` |
| `completedAt` | `completed_at` |
| `coverImage` | `cover_image` |

### C. 改造文件清单

| # | 文件路径 | 动作 |
|---|----------|------|
| 1 | `pubspec.yaml` | 新增 `connectivity_plus`, `internet_connection_checker` |
| 2 | `packages/planbook_api/lib/database/database.dart` | 新增 `SyncOutbox` 表，schemaVersion 3 |
| 3 | `packages/planbook_api/lib/planbook_api.dart` | 导出 `SyncOutbox` |
| 4 | `packages/database_planbook_api/lib/sync/outbox_api.dart` | **新增** |
| 5 | `packages/database_planbook_api/lib/database_planbook_api.dart` | 导出 `OutboxApi` |
| 6 | `packages/database_planbook_api/lib/task/database_task_api.dart` | **自管理 Outbox** |
| 7 | `packages/database_planbook_api/lib/task/database_task_update_api.dart` | **自管理 Outbox** |
| 8 | `packages/database_planbook_api/lib/task/database_task_completion_api.dart` | **自管理 Outbox** |
| 9 | `packages/database_planbook_api/lib/task/database_task_delay_api.dart` | 增加 `Transaction? txn` |
| 10 | `packages/database_planbook_api/lib/note/database_note_api.dart` | **自管理 Outbox** |
| 11 | `packages/database_planbook_api/lib/tag/database_tag_api.dart` | **自管理 Outbox** |
| 12 | `packages/planbook_repository/lib/sync/sync_engine.dart` | **新增** |
| 13 | `packages/planbook_repository/lib/task/tasks_repository.dart` | **大幅简化**，删除手动 Outbox |
| 14 | `packages/planbook_repository/lib/note/notes_repository.dart` | **大幅简化** |
| 15 | `packages/planbook_repository/lib/tag/tags_repository.dart` | **大幅简化** |
| 16 | `packages/supabase_planbook_api/lib/note/supabase_note_api.dart` | 统一软删除 |
| 17 | `packages/supabase_planbook_api/lib/task/supabase_task_api.dart` | 统一软删除 |
| 18 | `lib/bootstrap.dart` | 构造并启动 `SyncEngine` |
| 19 | `lib/app/bloc/app_bloc.dart` | 前后台监听，登录切换触发同步 |
| 20 | `packages/planbook_repository/lib/users/sync_repository.dart` | **删除** |

### D. 验收标准

- [ ] 新增依赖，`flutter pub get` 无报错。
- [ ] `SyncOutbox` 表创建成功，schemaVersion = 3，平滑升级。
- [ ] 断网：创建 Task/Note/Tag → 本地成功 → Outbox pending → UI 正常展示。
- [ ] 恢复网络：Outbox 自动同步到 Supabase → 标记 synced。
- [ ] `deleteByNoteId` / `deleteByTaskId` 均执行软删除。
- [ ] Supabase 触发器已部署（tasks→task_tags、notes→note_tags）。
- [ ] 多设备：设备 A 软删除 → 设备 B 拉取时本地也软删除，且不覆盖本地 pending。
- [ ] `completeTask` / `delayTask` / `updateWithEditMode` 断网可用，联网后同步。
- [ ] 单元测试全部通过，覆盖率 ≥ 60%。
- [ ] `SyncRepository` 已删除，无引用。
- [ ] iOS/Android 真机测试通过，无 ANR。
