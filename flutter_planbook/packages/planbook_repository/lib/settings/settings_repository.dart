import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository({required SharedPreferences sp}) : _sp = sp {
    _init();
  }

  final SharedPreferences _sp;

  List<TaskAutoNoteRule>? taskAutoNoteRules;

  late final _taskPriorityStyleController =
      BehaviorSubject<TaskPriorityStyle>();
  Stream<TaskPriorityStyle> get onTaskPriorityStyleChange =>
      _taskPriorityStyleController.stream;

  late final _onBackgroundAssetChangeController =
      BehaviorSubject<AppBackgroundEntity>();
  Stream<AppBackgroundEntity> get onBackgroundAssetChange =>
      _onBackgroundAssetChangeController.stream;
  AppBackgroundEntity? get backgroundAsset =>
      _onBackgroundAssetChangeController.value;

  @visibleForTesting
  static const kSettingsDarkModeKey = '__settings_dark_mode_key__';

  /// The key used for storing the settings app icon name locally.
  @visibleForTesting
  static const kSettingsAppIconNameKey = '__settings_app_icon_name_key__';

  /// The key used for storing the settings seed color locally.
  @visibleForTesting
  static const kSettingsSeedColorKey = '__settings_seed_color_key__';

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

  /// The key used for storing the settings task auto note rules locally.
  @visibleForTesting
  static const kSettingsTaskAutoNoteRulesKey =
      '__settings_task_auto_note_rules_key__';

  /// The key used for storing the settings task priority style locally.
  @visibleForTesting
  static const kSettingsTaskPriorityStyleKey =
      '__settings_task_priority_style_key__';

  static const kSettingsTaskCompletedSound =
      '__settings_task_completed_sound_key__';
  static const kSettingsBackgroundAsset = '__settings_background_asset_key__';

  Future<void> _init() async {
    final styleData = await AppHomeWidget.getWidgetData<String?>(
      kSettingsTaskPriorityStyleKey,
    );
    final style = styleData == null
        ? TaskPriorityStyle.solidColorBackground
        : TaskPriorityStyle.values.byName(styleData);
    _taskPriorityStyleController.add(style);

    final backgroundAssetData = await AppHomeWidget.getWidgetData<String?>(
      kSettingsBackgroundAsset,
    );
    final backgroundAsset = backgroundAssetData == null
        ? AppBackgroundEntity.all.first
        : AppBackgroundEntity.fromJson(
            jsonDecode(backgroundAssetData) as Map<String, dynamic>,
          );
    _onBackgroundAssetChangeController.add(backgroundAsset);
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

  Future<List<TaskAutoNoteRule>> getTaskAutoNoteRules() async {
    final json = await AppHomeWidget.getWidgetData<String>(
      kSettingsTaskAutoNoteRulesKey,
    );
    if (json == null) {
      return taskAutoNoteRules ??
          <TaskAutoNoteRule>[
            for (final priority in TaskPriority.values)
              TaskAutoNoteRule(
                priority: priority,
              ),
          ];
    }
    final list = jsonDecode(json) as List;
    return taskAutoNoteRules = list
        .map((e) => TaskAutoNoteRule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTaskAutoNoteRules(List<TaskAutoNoteRule> rules) async {
    await AppHomeWidget.saveWidgetData(
      kSettingsTaskAutoNoteRulesKey,
      jsonEncode(rules.map((e) => e.toJson()).toList()),
    );
    taskAutoNoteRules = rules;
  }

  Future<TaskPriorityStyle> getTaskPriorityStyle() async {
    final json = await AppHomeWidget.getWidgetData<String>(
      kSettingsTaskPriorityStyleKey,
    );
    final style = json == null
        ? TaskPriorityStyle.solidColorBackground
        : TaskPriorityStyle.values.byName(json);
    _taskPriorityStyleController.add(style);
    return style;
  }

  Future<void> saveTaskPriorityStyle(TaskPriorityStyle style) async {
    await AppHomeWidget.saveWidgetData(
      kSettingsTaskPriorityStyleKey,
      style.name,
    );
    _taskPriorityStyleController.add(style);
  }

  Future<String?> getTaskCompletedSound() async {
    final sound = await AppHomeWidget.getWidgetData<String>(
      kSettingsTaskCompletedSound,
    );
    return sound ?? 'audios/click2.m4a';
  }

  Future<void> saveTaskCompletedSound(String? sound) async {
    await AppHomeWidget.saveWidgetData(
      kSettingsTaskCompletedSound,
      sound,
    );
  }

  Future<void> saveBackgroundAsset(AppBackgroundEntity asset) async {
    await AppHomeWidget.saveWidgetData(
      kSettingsBackgroundAsset,
      jsonEncode(asset.toJson()),
    );
    _onBackgroundAssetChangeController.add(asset);
  }
}
