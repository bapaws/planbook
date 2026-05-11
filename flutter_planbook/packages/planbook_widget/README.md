# planbook_widget

Planbook 小组件（Android `AppWidgetProvider` / iOS WidgetKit `AppIntent`）
通过 MethodChannel 调用主 App Flutter 端业务逻辑的桥接插件。

## 设计目标

- 把"完成任务"等本来需要在 widget 内复刻的业务逻辑，统一委托给主 App
  的 Flutter 端 `TasksRepository`/`NotesRepository` 等，确保两端行为一致。
- 处理 widget 触发时 Flutter Engine 可能尚未启动的情况：内置 ready 握手
  机制（native 等待 Dart 端 `notifyReady` 后再发起 MethodChannel 调用）。
- 仅做事件桥接；KV 数据共享、widget 刷新继续使用上游 `home_widget`。

## 调用流程

```
Widget 点击 (Receiver / AppIntent)
        │
        ▼
WidgetActionDispatcher  ──── 等待 EngineReadyTracker ──── 调 MethodChannel
        │                                                       │
        │ 8s 超时无响应                                          ▼
        ▼                                              Flutter handler
   兜底：本地 DB 写入                                  TasksRepository.completeTask
```

## Dart API

```dart
// 注册回调，由 widget 触发时调用
PlanbookWidget.registerCompleteTaskHandler((taskId) async {
  // ...调 TasksRepository.completeTask 等
});

// Flutter 端就绪后通知 native（必须在 register 之后再调）
await PlanbookWidget.notifyReady();
```

## Native API

- Android: `WidgetActionDispatcher.completeTask(context, taskId)` (suspend)
- iOS: `WidgetActionDispatcher.completeTask(taskId:)` (async)

两端实现都会优先复用主 App 的 FlutterEngine（已缓存）；若 App 未启动，
Android 会拉起 headless FlutterEngine，iOS 由 AppIntent 自动后台拉起 App。
