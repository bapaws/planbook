import '../app_settings_ohos.dart';
import '../app_settings_platform_interface_ohos.dart';

class AppSettings {
  /// Open the app settings.
  static Future<void> openAppSettings({
    AppSettingsType type = AppSettingsType.settings,
    bool asAnotherTask = false,
  }) {
    return AppSettingsPlatform.instance.openAppSettings(type: type, asAnotherTask: asAnotherTask);
  }

  /// Open an application settings panel.
  static Future<void> openAppSettingsPanel(AppSettingsPanelType type) {
    return AppSettingsPlatform.instance.openAppSettingsPanel(type);
  }
}
