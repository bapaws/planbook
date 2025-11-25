import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository({required SharedPreferences sp}) : _sp = sp;

  final SharedPreferences _sp;

  @visibleForTesting
  static const kSettingsDarkModeKey = '__settings_dark_mode_key__';

  /// The key used for storing the settings app icon name locally.
  @visibleForTesting
  static const kSettingsAppIconNameKey = '__settings_app_icon_name_key__';

  /// The key used for storing the settings seed color locally.
  @visibleForTesting
  static const kSettingsSeedColorKey = '__settings_seed_color_key__';

  /// The key used for storing the settings cloud locally.
  @visibleForTesting
  static const kSettingsCloudSyncKey = '__settings_cloud_sync_key__';

  @visibleForTesting
  static const kSettingsAutoBackupCountKey =
      '__settings_auto_backup_count_key__';

  /// The key used for storing the settings seed color locally.
  @visibleForTesting
  static const kSettingsLightColorSchemeKey =
      '__settings_light_color_scheme_key__';

  /// The key used for storing the settings seed color locally.
  @visibleForTesting
  static const kSettingsDarkColorSchemeKey =
      '__settings_dark_color_scheme_key__';

  /// The key used for storing the settings start of week locally.
  @visibleForTesting
  static const kSettingsStartOfWeekKey = '__settings_start_of_week_key__';

  /// The key used for storing the settings onboarding completed locally.
  @visibleForTesting
  static const kSettingsOnboardingCompletedKey =
      '__settings_onboarding_completed_key__';

  /// The key used for storing the app launch count locally.
  @visibleForTesting
  static const kSettingsLaunchCountKey = '__settings_launch_count_key__';

  Future<bool> getCloudSynchronizable() async {
    final synchronizable = _sp.getBool(kSettingsCloudSyncKey);
    return synchronizable != null && synchronizable;
  }

  DarkMode? getDarkMode() {
    final index = _sp.getInt(kSettingsDarkModeKey);
    if (index == null) return null;
    return DarkMode.values[index];
  }

  Future<void> saveDarkMode(DarkMode? mode) async {
    if (mode == null) {
      await _sp.remove(kSettingsDarkModeKey);
    } else {
      await _sp.setInt(kSettingsDarkModeKey, mode.index);
    }
  }

  Future<void> toggleCloudSync() async {
    final synchronizable = await getCloudSynchronizable();
    if (synchronizable) {
      await _sp.remove(kSettingsCloudSyncKey);
    } else {
      await _sp.setBool(kSettingsCloudSyncKey, true);
    }
  }

  Future<int> getAutoBackupCount() async {
    final count = _sp.getInt(kSettingsAutoBackupCountKey);
    return count ?? 1;
  }

  Future<void> saveAutoBackupCount({required int count}) async {
    if (count <= 0) {
      await _sp.remove(kSettingsAutoBackupCountKey);
    } else {
      await _sp.setInt(kSettingsAutoBackupCountKey, count);
    }
  }

  String? getAppIconName() => _sp.getString(kSettingsAppIconNameKey);

  Future<void> saveAppIconName(String name) async {
    await _sp.setString(kSettingsAppIconNameKey, name);
  }

  Future<void> saveSeedColorHex(String hex) async {
    await _sp.setString(kSettingsSeedColorKey, hex);
  }

  String? getSeedColorHex() {
    return _sp.getString(kSettingsSeedColorKey);
  }

  Future<void> saveLightColorScheme(Map<String, int> colorScheme) async {
    if (!Platform.isIOS) return;
    await AppHomeWidget.saveWidgetData(
      kSettingsLightColorSchemeKey,
      jsonEncode(colorScheme),
    );
  }

  Future<void> saveDarkColorScheme(Map<String, int> colorScheme) async {
    if (!Platform.isIOS) return;
    await AppHomeWidget.saveWidgetData(
      kSettingsDarkColorSchemeKey,
      jsonEncode(colorScheme),
    );
  }

  Future<Map<String, int>?> getLightColorScheme() async {
    if (!Platform.isIOS) return null;
    final json = await AppHomeWidget.getWidgetData<String>(
      kSettingsLightColorSchemeKey,
    );
    if (json is! String) return null;
    final map = jsonDecode(json) as Map;
    return Map<String, int>.from(map);
  }

  Future<Map<String, int>?> getDarkColorScheme() async {
    if (!Platform.isIOS) return null;
    final json = await AppHomeWidget.getWidgetData<String>(
      kSettingsDarkColorSchemeKey,
    );
    if (json is! String) return null;
    final map = jsonDecode(json) as Map;
    return Map<String, int>.from(map);
  }

  Future<StartOfWeek?> getStartOfWeek() async {
    final name = await AppHomeWidget.getWidgetData<String>(
      kSettingsStartOfWeekKey,
    );
    if (name == null) return null;
    return StartOfWeek.values.byName(name);
  }

  Future<void> saveStartOfWeek(StartOfWeek startOfWeek) async {
    await AppHomeWidget.saveWidgetData(
      kSettingsStartOfWeekKey,
      startOfWeek.name,
    );
  }

  Future<bool> getOnboardingCompleted() async {
    return _sp.getBool(kSettingsOnboardingCompletedKey) ?? false;
  }

  Future<void> saveOnboarding({required bool completed}) async {
    await _sp.setBool(kSettingsOnboardingCompletedKey, completed);
  }

  Future<int> getLaunchCount() async {
    return _sp.getInt(kSettingsLaunchCountKey) ?? 0;
  }

  Future<int> incrementLaunchCount() async {
    final currentCount = await getLaunchCount();
    final newCount = currentCount + 1;
    await _sp.setInt(kSettingsLaunchCountKey, newCount);
    return newCount;
  }
}
