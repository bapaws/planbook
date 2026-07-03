# home_widget (Planbook fork)

基于 [home_widget 0.9.1](https://github.com/ABausG/home_widget) 的本地 fork，在 Planbook 仓库内维护。

## 与上游的差异

**Android**

- 移除 `androidx.glance:glance-appwidget` 依赖及相关 Kotlin 源文件
- 移除 `HomeWidgetBackgroundReceiver` / `Worker` / `Service`（未使用 `registerInteractivityCallback`，且会触发应用自启动）
- 精简 `HomeWidgetIntent.kt`，仅保留 `HomeWidgetLaunchIntent.getActivity()`

**iOS / Dart API**

- 与上游 0.9.1 保持一致，Planbook 使用的 `saveWidgetData`、`getWidgetData`、`updateWidget`、`setAppGroupId` 行为不变。

## 维护原因

国内应用商店检测在「应用退出」阶段发现 `androidx.glance.appwidget` 触发自启动。Planbook Android 小组件使用 RemoteViews 实现，不需要 Glance。

## 许可

沿用上游 MIT License，见 [LICENSE](LICENSE)。
