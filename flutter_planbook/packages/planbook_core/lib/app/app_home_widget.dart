import 'package:home_widget/home_widget.dart';

/// App group id for the app
const kAppGroupId = 'group.GM4766U38W.com.bapaws.habits';

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

  /// Returns a list of widgets currently installed on the home screen.
  // static Future<List<HomeWidgetInfo>> getInstalledWidgets() {
  //   return HomeWidget.getInstalledWidgets();
  // }

  // /// Updates the widget with the given name.
  // static Future<void> updateWidget({
  //   String? name,
  //   String? androidName,
  //   String? iOSName,
  //   String? qualifiedAndroidName,
  // }) async {
  //   await HomeWidget.updateWidget(
  //     name: name,
  //     androidName: androidName,
  //     iOSName: iOSName,
  //     qualifiedAndroidName: qualifiedAndroidName,
  //   );
  // }

  // /// Updates all widgets.
  // static Future<void> updateAllWidget() async {
  //   final widgets = await getInstalledWidgets();
  //   for (final widget in widgets) {
  //     await updateWidget(
  //       name: widget.iOSKind,
  //       androidName: widget.androidClassName,
  //       iOSName: widget.iOSKind,
  //       qualifiedAndroidName: widget.androidClassName,
  //     );
  //   }
  // }
}
