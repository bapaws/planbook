import 'package:flutter/services.dart';

/// 仅提供 Widget 数据存储的 Flutter 插件（saveWidgetData / getWidgetData）
class HomeWidget {
  static const MethodChannel _channel = MethodChannel('home_widget');

  /// The AppGroupId used for iOS Widgets (required on iOS for getWidgetData/saveWidgetData)
  static String? groupId;

  /// Save [data] to the Widget Storage
  ///
  /// Returns whether the data was saved or not
  static Future<bool?> saveWidgetData<T>(String id, T? data) {
    return _channel.invokeMethod<bool>('saveWidgetData', {
      'id': id,
      'data': data,
    });
  }

  /// Returns Data saved with [saveWidgetData]
  /// [id] of Data Saved
  /// [defaultValue] value to use if no data was found
  static Future<T?> getWidgetData<T>(String id, {T? defaultValue}) {
    return _channel.invokeMethod<T>('getWidgetData', {
      'id': id,
      'defaultValue': defaultValue,
    });
  }

  /// Required on iOS to set the AppGroupId [groupId] in order to ensure
  /// communication between the App and the Widget Extension
  static Future<bool?> setAppGroupId(String groupId) {
    HomeWidget.groupId = groupId;
    return _channel.invokeMethod('setAppGroupId', {'groupId': groupId});
  }
}
