import 'dart:convert';

import 'package:collection/collection.dart';
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

  late final _quadrantConfigsController =
      BehaviorSubject<List<QuadrantConfigEntity>>();
  Stream<List<QuadrantConfigEntity>> get onQuadrantConfigsChange =>
      _quadrantConfigsController.stream;
  List<QuadrantConfigEntity>? get quadrantConfigs =>
      _quadrantConfigsController.valueOrNull;

  @visibleForTesting
  static const kSettingsDarkModeKey = '__settings_dark_mode_key__';

  /// The key used for storing the app locale locally.
  @visibleForTesting
  static const kSettingsLocaleKey = '__settings_locale_key__';

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

  /// 四象限自定义配置（裸 key，便于原生 widget 直接读取）
  static const kSettingsQuadrantConfigs = 'widget_quadrant_configs';

  /// 发现页日志「翻页手势」首次提示是否已展示
  @visibleForTesting
  static const kDiscoverJournalFlipGestureHintShownKey =
      '__discover_journal_flip_gesture_hint_shown__';

  /// 国内渠道首启隐私政策是否已同意
  static const kSettingsPrivacyConsentAcceptedKey =
      '__settings_privacy_consent_accepted_key__';

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

    final quadrantConfigsData = await AppHomeWidget.getWidgetData<String?>(
      kSettingsQuadrantConfigs,
    );
    final quadrantConfigs = quadrantConfigsData == null
        ? QuadrantConfigEntity.defaults
        : QuadrantConfigEntity.listFromJson(
            jsonDecode(quadrantConfigsData) as List<dynamic>,
          );
    _quadrantConfigsController.add(quadrantConfigs);
  }

  Locale? getLocale() {
    final key = _sp.getString(kSettingsLocaleKey);
    if (key == null || key.isEmpty) return null;
    final parts = key.split('_');
    if (parts.length >= 2 && parts[0] == 'zh') {
      return Locale.fromSubtags(languageCode: 'zh', scriptCode: parts[1]);
    }
    return Locale(parts[0]);
  }

  Future<void> saveLocale(Locale? locale) async {
    if (locale == null) {
      await _sp.remove(kSettingsLocaleKey);
      return;
    }
    final key = locale.languageCode == 'zh' && locale.scriptCode != null
        ? '${locale.languageCode}_${locale.scriptCode}'
        : locale.languageCode;
    await _sp.setString(kSettingsLocaleKey, key);
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
    // 同步深色模式到 Widget（iOS + Android）
    final isDarkMode = mode == DarkMode.dark;
    await AppHomeWidget.saveWidgetData(
      'widget_theme',
      jsonEncode({'isDarkMode': isDarkMode}),
    );
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
    await AppHomeWidget.saveWidgetData(
      kSettingsLightColorSchemeKey,
      jsonEncode(colorScheme),
    );
  }

  Future<void> saveDarkColorScheme(Map<String, int> colorScheme) async {
    await AppHomeWidget.saveWidgetData(
      kSettingsDarkColorSchemeKey,
      jsonEncode(colorScheme),
    );
  }

  Future<Map<String, int>?> getLightColorScheme() async {
    final json = await AppHomeWidget.getWidgetData<String>(
      kSettingsLightColorSchemeKey,
    );
    if (json is! String) return null;
    final map = jsonDecode(json) as Map;
    return Map<String, int>.from(map);
  }

  Future<Map<String, int>?> getDarkColorScheme() async {
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

  Future<bool> getPrivacyConsentAccepted() async {
    return getPrivacyConsentAcceptedFrom(_sp);
  }

  Future<void> savePrivacyConsentAccepted({required bool accepted}) async {
    await savePrivacyConsentAcceptedTo(_sp, accepted: accepted);
  }

  static bool getPrivacyConsentAcceptedFrom(SharedPreferences sp) {
    return sp.getBool(kSettingsPrivacyConsentAcceptedKey) ?? false;
  }

  static Future<void> savePrivacyConsentAcceptedTo(
    SharedPreferences sp, {
    required bool accepted,
  }) async {
    await sp.setBool(kSettingsPrivacyConsentAcceptedKey, accepted);
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

  Future<TaskAutoNoteType> getTaskAutoNoteTypeByTask(TaskEntity task) async {
    final rules = await getTaskAutoNoteRules();
    if (task.parentId != null) {
      final subtaskRule = rules.firstWhereOrNull((rule) => rule.isSubtask);
      if (subtaskRule == null || subtaskRule.type == TaskAutoNoteType.none) {
        return TaskAutoNoteType.none;
      }
      return subtaskRule.type;
    } else {
      final rule = rules.firstWhereOrNull(
        (rule) => rule.priority == task.priority,
      );
      return (rule == null || rule.type == TaskAutoNoteType.none)
          ? TaskAutoNoteType.none
          : rule.type;
    }
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
    // 同步背景资源名称到 Widget（提取 bg_dot / bg_grid）
    final assetBaseName = asset.darkAsset
        .replaceAll('assets/images/', '')
        .replaceAll('_tile_dark.png', '');
    await AppHomeWidget.saveWidgetData(
      'widget_background_asset',
      assetBaseName,
    );
    _onBackgroundAssetChangeController.add(asset);
  }

  Future<List<QuadrantConfigEntity>> getQuadrantConfigs() async {
    final json = await AppHomeWidget.getWidgetData<String>(
      kSettingsQuadrantConfigs,
    );
    final configs = json == null
        ? QuadrantConfigEntity.defaults
        : QuadrantConfigEntity.listFromJson(jsonDecode(json) as List<dynamic>);
    _quadrantConfigsController.add(configs);
    return configs;
  }

  Future<void> saveQuadrantConfigs(List<QuadrantConfigEntity> configs) async {
    await AppHomeWidget.saveWidgetData(
      kSettingsQuadrantConfigs,
      jsonEncode(configs.map((e) => e.toJson()).toList()),
    );
    _quadrantConfigsController.add(configs);
  }

  bool getDiscoverJournalFlipGestureHintShown() {
    return _sp.getBool(kDiscoverJournalFlipGestureHintShownKey) ?? false;
  }

  Future<void> setDiscoverJournalFlipGestureHintShown({
    required bool shown,
  }) async {
    await _sp.setBool(kDiscoverJournalFlipGestureHintShownKey, shown);
  }
}
