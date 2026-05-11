import 'package:home_widget/home_widget.dart';

/// App group id for the app
const kAppGroupId = 'group.GM4766U38W.com.bapaws.planbook';

/// 四象限大号小组件标识
/// - iOS: `WidgetKit` 的 `kind`（见 `ios/Widgets/Quadrant/QuadrantWidget.swift`）
/// - Android: `AppWidgetProvider` 的完整类名
const _kQuadrantLargeIOSKind = 'QuadrantWidgetLarge';
const _kQuadrantLargeAndroidClass =
    'com.bapaws.planbook.widget.QuadrantWidgetLargeProvider';

/// 四象限中号小组件标识
const _kQuadrantSmallIOSKind = 'QuadrantWidgetSmall';
const _kQuadrantSmallAndroidClass =
    'com.bapaws.planbook.widget.QuadrantWidgetSmallProvider';

/// App home widget
class AppHomeWidget {
  /// Initializes the HomeWidget plugin with the given app group ID.
  /// This is required for iOS.
  static Future<bool?> setAppGroupId(String groupId) {
    return HomeWidget.setAppGroupId(groupId);
  }

  /// Saves data to be used by the widget.
  static Future<bool?> saveWidgetData<T>(String id, T? data) {
    return HomeWidget.saveWidgetData(id, data);
  }

  /// Removes data from the widget.
  static Future<void> removeWidgetData(String id) async {
    await HomeWidget.saveWidgetData(id, null);
  }

  /// Gets data saved for the widget.
  static Future<T?> getWidgetData<T>(String id, {T? defaultValue}) {
    return HomeWidget.getWidgetData(id, defaultValue: defaultValue);
  }

  /// 通用：刷新指定的小组件
  ///
  /// 见 [HomeWidget.updateWidget]。
  static Future<void> updateWidget({
    String? name,
    String? androidName,
    String? iOSName,
    String? qualifiedAndroidName,
  }) async {
    await HomeWidget.updateWidget(
      name: name,
      androidName: androidName,
      iOSName: iOSName,
      qualifiedAndroidName: qualifiedAndroidName,
    );
  }

  /// 一键刷新四象限相关的所有小组件（大号 + 中号）。
  ///
  /// 任务被创建/修改/完成/删除时调用。失败不抛异常，避免影响业务流程。
  static Future<void> refreshQuadrantWidgets() async {
    try {
      await Future.wait([
        HomeWidget.updateWidget(
          iOSName: _kQuadrantLargeIOSKind,
          qualifiedAndroidName: _kQuadrantLargeAndroidClass,
        ),
        HomeWidget.updateWidget(
          iOSName: _kQuadrantSmallIOSKind,
          qualifiedAndroidName: _kQuadrantSmallAndroidClass,
        ),
      ]);
    } on Object {
      // 容错：即使插件未注册或无对应平台实现也不影响主流程
    }
  }
}
