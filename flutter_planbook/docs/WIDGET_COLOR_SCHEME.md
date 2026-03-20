# 小组件 ColorScheme 同步方案

## 概述

本文档描述如何将 Flutter App 的 ColorScheme 同步到 iOS/Android 小组件，确保小组件与 App 的视觉风格一致。

## 设计目标

1. **一致性**：小组件颜色与 App 完全一致
2. **动态性**：支持跟随系统深色/浅色模式自动切换
3. **实时性**：App 修改主题后，小组件立即更新
4. **可配置**：用户自定义的主题色也能同步

## 颜色配置模型

### Flutter 端定义

```dart
// packages/planbook_api/lib/src/widget/widget_color_scheme.dart

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'widget_color_scheme.g.dart';

/// 小组件颜色方案
/// 
/// 包含亮色和暗色两套主题，小组件根据系统模式自动切换
@JsonSerializable()
class WidgetColorScheme {
  /// 主色调（品牌色）
  final String primary;
  
  /// 次要色调
  final String secondary;
  
  /// 背景色
  final String background;
  
  /// 表面色（卡片、列表项背景）
  final String surface;
  
  /// 主要文本色
  final String onPrimary;
  
  /// 背景上的文本色
  final String onBackground;
  
  /// 表面上的文本色
  final String onSurface;
  
  /// 次要文本色（副标题、说明文字）
  final String onSurfaceVariant;
  
  /// 边框/分割线颜色
  final String outline;
  
  /// 错误色
  final String error;
  
  /// 成功/完成色
  final String success;
  
  /// 警告色
  final String warning;
  
  /// 四象限颜色（优先级）
  final PriorityColors priorityColors;
  
  const WidgetColorScheme({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.onPrimary,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.error,
    required this.success,
    required this.warning,
    required this.priorityColors,
  });
  
  /// 从 Flutter ColorScheme 创建
  factory WidgetColorScheme.fromColorScheme(
    ColorScheme light, 
    ColorScheme dark, {
    PriorityColors? customPriorityColors,
  }) {
    return WidgetColorScheme(
      primary: colorToHex(light.primary),
      secondary: colorToHex(light.secondary),
      background: colorToHex(light.background),
      surface: colorToHex(light.surface),
      onPrimary: colorToHex(light.onPrimary),
      onBackground: colorToHex(light.onBackground),
      onSurface: colorToHex(light.onSurface),
      onSurfaceVariant: colorToHex(light.onSurfaceVariant),
      outline: colorToHex(light.outline),
      error: colorToHex(light.error),
      success: colorToHex(const Color(0xFF4CAF50)),
      warning: colorToHex(const Color(0xFFFF9800)),
      priorityColors: customPriorityColors ?? PriorityColors.defaultColors(),
    );
  }
  
  /// 暗色主题版本
  WidgetColorScheme get dark => WidgetColorScheme(
    primary: primary,  // 可以根据需要调整
    secondary: secondary,
    background: _darken(background),
    surface: _darken(surface),
    onPrimary: onPrimary,
    onBackground: _lighten(onBackground),
    onSurface: _lighten(onSurface),
    onSurfaceVariant: _lighten(onSurfaceVariant),
    outline: _darken(outline),
    error: error,
    success: success,
    warning: warning,
    priorityColors: priorityColors,
  );
  
  factory WidgetColorScheme.fromJson(Map<String, dynamic> json) => 
      _$WidgetColorSchemeFromJson(json);
  
  Map<String, dynamic> toJson() => _$WidgetColorSchemeToJson(this);
  
  // Helper methods
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
  
  static Color hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
  
  String _darken(String color) {
    final c = hexToColor(color);
    final darkened = Color.fromRGBO(
      (c.red * 0.8).round(),
      (c.green * 0.8).round(),
      (c.blue * 0.8).round,
      1,
    );
    return colorToHex(darkened);
  }
  
  String _lighten(String color) {
    final c = hexToColor(color);
    final lightened = Color.fromRGBO(
      (c.red + (255 - c.red) * 0.2).round(),
      (c.green + (255 - c.green) * 0.2).round(),
      (c.blue + (255 - c.blue) * 0.2).round(),
      1,
    );
    return colorToHex(lightened);
  }
}

/// 四象限优先级颜色
@JsonSerializable()
class PriorityColors {
  /// 重要且紧急（高优先级）
  final String importantUrgent;
  
  /// 重要不紧急（中优先级）
  final String importantNotUrgent;
  
  /// 紧急不重要（低优先级）
  final String urgentUnimportant;
  
  /// 不紧急不重要（无优先级）
  final String notUrgentUnimportant;
  
  const PriorityColors({
    required this.importantUrgent,
    required this.importantNotUrgent,
    required this.urgentUnimportant,
    required this.notUrgentUnimportant,
  });
  
  factory PriorityColors.defaultColors() => const PriorityColors(
    importantUrgent: '#FF4444',      // 红色
    importantNotUrgent: '#FFBB33',   // 黄色
    urgentUnimportant: '#FF8800',    // 橙色
    notUrgentUnimportant: '#9E9E9E', // 灰色
  );
  
  /// 从主色调生成协调的优先级颜色
  factory PriorityColors.fromPrimary(String primaryHex) {
    final primary = WidgetColorScheme.hexToColor(primaryHex);
    final hsl = HSLColor.fromColor(primary);
    
    return PriorityColors(
      importantUrgent: WidgetColorScheme.colorToHex(
        hsl.withHue((hsl.hue + 0) % 360).toColor(),
      ),
      importantNotUrgent: WidgetColorScheme.colorToHex(
        hsl.withHue((hsl.hue + 30) % 360).toColor(),
      ),
      urgentUnimportant: WidgetColorScheme.colorToHex(
        hsl.withHue((hsl.hue + 60) % 360).toColor(),
      ),
      notUrgentUnimportant: WidgetColorScheme.colorToHex(
        hsl.withLightness(0.7).toColor(),
      ),
    );
  }
  
  factory PriorityColors.fromJson(Map<String, dynamic> json) => 
      _$PriorityColorsFromJson(json);
  
  Map<String, dynamic> toJson() => _$PriorityColorsToJson(this);
}

/// 主题模式
enum ThemeMode {
  light,
  dark,
  system,
}

/// 完整的主题配置（包含亮色和暗色）
@JsonSerializable()
class WidgetThemeConfig {
  final WidgetColorScheme light;
  final WidgetColorScheme dark;
  final ThemeMode mode;
  
  const WidgetThemeConfig({
    required this.light,
    required this.dark,
    this.mode = ThemeMode.system,
  });
  
  /// 获取当前应该使用的颜色方案
  WidgetColorScheme getColorScheme(Brightness brightness) {
    switch (mode) {
      case ThemeMode.light:
        return light;
      case ThemeMode.dark:
        return dark;
      case ThemeMode.system:
        return brightness == Brightness.dark ? dark : light;
    }
  }
  
  factory WidgetThemeConfig.fromJson(Map<String, dynamic> json) => 
      _$WidgetThemeConfigFromJson(json);
  
  Map<String, dynamic> toJson() => _$WidgetThemeConfigToJson(this);
}
```

### iOS 端定义 (Swift)

```swift
// ios/Widgets/WidgetColorScheme.swift

import SwiftUI

struct WidgetColorScheme: Codable {
    let primary: String
    let secondary: String
    let background: String
    let surface: String
    let onPrimary: String
    let onBackground: String
    let onSurface: String
    let onSurfaceVariant: String
    let outline: String
    let error: String
    let success: String
    let warning: String
    let priorityColors: PriorityColors
    
    struct PriorityColors: Codable {
        let importantUrgent: String
        let importantNotUrgent: String
        let urgentUnimportant: String
        let notUrgentUnimportant: String
    }
}

struct WidgetThemeConfig: Codable {
    let light: WidgetColorScheme
    let dark: WidgetColorScheme
    let mode: String  // "light", "dark", "system"
}

// 颜色扩展
extension WidgetColorScheme {
    var primaryColor: Color { Color(hex: primary) }
    var secondaryColor: Color { Color(hex: secondary) }
    var backgroundColor: Color { Color(hex: background) }
    var surfaceColor: Color { Color(hex: surface) }
    var onPrimaryColor: Color { Color(hex: onPrimary) }
    var onBackgroundColor: Color { Color(hex: onBackground) }
    var onSurfaceColor: Color { Color(hex: onSurface) }
    var onSurfaceVariantColor: Color { Color(hex: onSurfaceVariant) }
    var outlineColor: Color { Color(hex: outline) }
    var errorColor: Color { Color(hex: error) }
    var successColor: Color { Color(hex: success) }
    var warningColor: Color { Color(hex: warning) }
}

// Color 初始化扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// 环境值用于传递颜色方案
struct ColorSchemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: WidgetColorScheme = WidgetColorScheme(
        primary: "#2196F3",
        secondary: "#03DAC6",
        background: "#FFFFFF",
        surface: "#F5F5F5",
        onPrimary: "#FFFFFF",
        onBackground: "#000000",
        onSurface: "#000000",
        onSurfaceVariant: "#666666",
        outline: "#E0E0E0",
        error: "#B00020",
        success: "#4CAF50",
        warning: "#FF9800",
        priorityColors: .init(
            importantUrgent: "#FF4444",
            importantNotUrgent: "#FFBB33",
            urgentUnimportant: "#FF8800",
            notUrgentUnimportant: "#9E9E9E"
        )
    )
}

extension EnvironmentValues {
    var widgetColorScheme: WidgetColorScheme {
        get { self[ColorSchemeEnvironmentKey.self] }
        set { self[ColorSchemeEnvironmentKey.self] = newValue }
    }
}
```

### Android 端定义 (Kotlin)

```kotlin
// android/app/src/main/kotlin/com/bapaws/planbook/widget/WidgetColorScheme.kt

package com.bapaws.planbook.widget

import android.content.Context
import android.graphics.Color
import androidx.core.graphics.toColorInt

// 颜色方案数据类
data class WidgetColorScheme(
    val primary: String,
    val secondary: String,
    val background: String,
    val surface: String,
    val onPrimary: String,
    val onBackground: String,
    val onSurface: String,
    val onSurfaceVariant: String,
    val outline: String,
    val error: String,
    val success: String,
    val warning: String,
    val priorityColors: PriorityColors
) {
    data class PriorityColors(
        val importantUrgent: String,
        val importantNotUrgent: String,
        val urgentUnimportant: String,
        val notUrgentUnimportant: String
    )
    
    // 转换方法
    fun primaryInt(): Int = primary.toColorInt()
    fun secondaryInt(): Int = secondary.toColorInt()
    fun backgroundInt(): Int = background.toColorInt()
    fun surfaceInt(): Int = surface.toColorInt()
    fun onPrimaryInt(): Int = onPrimary.toColorInt()
    fun onBackgroundInt(): Int = onBackground.toColorInt()
    fun onSurfaceInt(): Int = onSurface.toColorInt()
    fun onSurfaceVariantInt(): Int = onSurfaceVariant.toColorInt()
    fun outlineInt(): Int = outline.toColorInt()
    fun errorInt(): Int = error.toColorInt()
    fun successInt(): Int = success.toColorInt()
    fun warningInt(): Int = warning.toColorInt()
}

// 主题配置
data class WidgetThemeConfig(
    val light: WidgetColorScheme,
    val dark: WidgetColorScheme,
    val mode: String  // "light", "dark", "system"
) {
    companion object {
        const val MODE_LIGHT = "light"
        const val MODE_DARK = "dark"
        const val MODE_SYSTEM = "system"
    }
    
    fun getColorScheme(isDark: Boolean): WidgetColorScheme {
        return when (mode) {
            MODE_LIGHT -> light
            MODE_DARK -> dark
            else -> if (isDark) dark else light
        }
    }
}

// 默认颜色方案
object DefaultColorScheme {
    val LIGHT = WidgetColorScheme(
        primary = "#2196F3",
        secondary = "#03DAC6",
        background = "#FFFFFF",
        surface = "#F5F5F5",
        onPrimary = "#FFFFFF",
        onBackground = "#000000",
        onSurface = "#000000",
        onSurfaceVariant = "#666666",
        outline = "#E0E0E0",
        error = "#B00020",
        success = "#4CAF50",
        warning = "#FF9800",
        priorityColors = WidgetColorScheme.PriorityColors(
            importantUrgent = "#FF4444",
            importantNotUrgent = "#FFBB33",
            urgentUnimportant = "#FF8800",
            notUrgentUnimportant = "#9E9E9E"
        )
    )
    
    val DARK = WidgetColorScheme(
        primary = "#90CAF9",
        secondary = "#80CBC4",
        background = "#121212",
        surface = "#1E1E1E",
        onPrimary = "#000000",
        onBackground = "#FFFFFF",
        onSurface = "#FFFFFF",
        onSurfaceVariant = "#B0B0B0",
        outline = "#424242",
        error = "#CF6679",
        success = "#81C784",
        warning = "#FFB74D",
        priorityColors = WidgetColorScheme.PriorityColors(
            importantUrgent = "#FF6B6B",
            importantNotUrgent = "#FFD93D",
            urgentUnimportant = "#FF9F43",
            notUrgentUnimportant = "#A0A0A0"
        )
    )
}

// 颜色解析扩展
fun String.toColorIntSafe(): Int {
    return try {
        this.toColorInt()
    } catch (e: Exception) {
        Color.GRAY
    }
}

// RemoteViews 颜色设置扩展
fun RemoteViews.setTextColorSafe(viewId: Int, color: String) {
    try {
        setTextColor(viewId, color.toColorInt())
    } catch (e: Exception) {
        // 使用默认颜色
    }
}

fun RemoteViews.setBackgroundColorSafe(viewId: Int, color: String) {
    try {
        setInt(viewId, "setBackgroundColor", color.toColorInt())
    } catch (e: Exception) {
        // 使用默认颜色
    }
}

fun RemoteViews.setImageViewColorFilter(viewId: Int, color: String) {
    try {
        setInt(viewId, "setColorFilter", color.toColorInt())
    } catch (e: Exception) {
        // 使用默认颜色
    }
}
```

---

## 颜色同步服务

### Flutter 端

```dart
// lib/services/widget_theme_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetThemeService {
  static const _colorSchemeKey = 'widget_color_scheme';
  static const _appGroupId = 'group.GM4766U38W.com.bapaws.habits';
  
  /// 同步当前主题到小组件
  static Future<void> syncThemeToWidget(BuildContext context) async {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final theme = Theme.of(context);
    
    // 创建颜色配置
    final config = WidgetThemeConfig(
      light: WidgetColorScheme.fromColorScheme(
        ThemeData.light().colorScheme,
        ThemeData.dark().colorScheme,
        customPriorityColors: _extractPriorityColors(theme),
      ),
      dark: WidgetColorScheme.fromColorScheme(
        ThemeData.dark().colorScheme,
        ThemeData.dark().colorScheme,
        customPriorityColors: _extractPriorityColors(theme, isDark: true),
      ),
      mode: _getThemeMode(),
    );
    
    // 保存到共享存储
    await _saveColorScheme(config);
    
    // 触发小组件刷新
    await _reloadWidgets();
  }
  
  /// 监听主题变化自动同步
  static void setupThemeListener(BuildContext context) {
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    
    // 使用 WidgetsBinding 监听系统主题变化
    WidgetsBinding.instance.addObserver(
      _ThemeChangeObserver(onChanged: () {
        syncThemeToWidget(context);
      }),
    );
  }
  
  /// 保存颜色方案到共享存储
  static Future<void> _saveColorScheme(WidgetThemeConfig config) async {
    final json = jsonEncode(config.toJson());
    
    if (Platform.isIOS) {
      await AppHomeWidget.setAppGroupId(_appGroupId);
      await AppHomeWidget.saveWidgetData(_colorSchemeKey, json);
    } else if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_colorSchemeKey, json);
    }
  }
  
  /// 提取四象限颜色
  static PriorityColors _extractPriorityColors(ThemeData theme, {bool isDark = false}) {
    // 可以从 AppStyles 或设置中读取用户自定义的优先级颜色
    final appStyles = AppStyles.instance;
    
    return PriorityColors(
      importantUrgent: _colorToHex(appStyles.priorityHighColor ?? Colors.red),
      importantNotUrgent: _colorToHex(appStyles.priorityMediumColor ?? Colors.orange),
      urgentUnimportant: _colorToHex(appStyles.priorityLowColor ?? Colors.yellow.shade700),
      notUrgentUnimportant: _colorToHex(appStyles.priorityNoneColor ?? Colors.grey),
    );
  }
  
  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
  
  static ThemeMode _getThemeMode() {
    // 从 SettingsBloc 或 SharedPreferences 读取用户设置
    final settings = AppSettings.instance;
    return settings.themeMode;
  }
  
  static Future<void> _reloadWidgets() async {
    // 刷新所有小组件
    await HomeWidget.updateWidget(
      name: 'TodayWidget',
      androidName: 'TodayWidgetProvider',
      iOSName: 'TodayWidget',
    );
    await HomeWidget.updateWidget(
      name: 'QuadrantWidget',
      androidName: 'QuadrantWidgetProvider',
      iOSName: 'QuadrantWidget',
    );
    // ... 其他小组件
  }
}

/// 主题变化观察者
class _ThemeChangeObserver extends WidgetsBindingObserver {
  final VoidCallback onChanged;
  Brightness? _lastBrightness;
  
  _ThemeChangeObserver({required this.onChanged});
  
  @override
  void didChangePlatformBrightness() {
    onChanged();
  }
}
```

### 在 App 启动时初始化

```dart
// lib/app/view/app.dart

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 初始化小组件主题同步
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetThemeService.syncThemeToWidget(context);
      WidgetThemeService.setupThemeListener(context);
    });
    
    return MaterialApp(
      // ...
    );
  }
}

// 或者在 ThemeBloc 中监听主题变化
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState()) {
    on<ThemeChanged>(_onThemeChanged);
  }
  
  Future<void> _onThemeChanged(ThemeChanged event, Emitter<ThemeState> emit) async {
    // ... 更新主题状态
    
    // 同步到小组件
    await WidgetThemeService.syncThemeToWidget(event.context);
  }
}
```

---

## iOS 小组件使用颜色方案

```swift
// ios/Widgets/TodayWidget.swift

import WidgetKit
import SwiftUI

struct TodayWidgetView: View {
    var entry: TodayWidgetEntry
    @Environment(\.widgetColorScheme) var colorScheme
    @Environment(\.colorScheme) var systemColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 头部 - 使用主色调背景
            HStack {
                Label("今天待办", systemImage: "calendar")
                    .font(.headline)
                    .foregroundColor(colorScheme.onSurfaceColor)
                Spacer()
                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.caption)
                    .foregroundColor(colorScheme.onSurfaceVariantColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(colorScheme.surfaceColor)
            
            Divider()
                .background(colorScheme.outlineColor)
            
            // 任务列表
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.tasks.prefix(4)) { task in
                    TaskRowView(task: task)
                }
            }
            .padding(.horizontal, 12)
            
            Spacer()
        }
        .background(colorScheme.backgroundColor)
    }
}

struct TaskRowView: View {
    let task: WidgetTask
    @Environment(\.widgetColorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            // 完成状态圆圈 - 使用优先级颜色
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? colorScheme.successColor : priorityColor)
                .font(.system(size: 18))
            
            // 任务标题
            Text(task.title)
                .font(.system(size: 14))
                .lineLimit(1)
                .strikethrough(task.isCompleted)
                .foregroundColor(task.isCompleted ? colorScheme.onSurfaceVariantColor : colorScheme.onSurfaceColor)
            
            Spacer()
        }
    }
    
    var priorityColor: Color {
        switch task.priority {
        case .high:
            return Color(hex: colorScheme.priorityColors.importantUrgent)
        case .medium:
            return Color(hex: colorScheme.priorityColors.importantNotUrgent)
        case .low:
            return Color(hex: colorScheme.priorityColors.urgentUnimportant)
        case .none:
            return Color(hex: colorScheme.priorityColors.notUrgentUnimportant)
        }
    }
}

// 在 Provider 中加载颜色方案
struct TodayWidgetProvider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (TodayWidgetEntry) -> Void) {
        let colorScheme = WidgetDataProvider.shared.loadColorScheme()
        
        var entry = TodayWidgetEntry(
            date: Date(),
            tasks: [],
            completedCount: 0,
            totalCount: 0
        )
        
        // 将颜色方案传递给 View
        // 使用 environment 传递
        completion(entry)
    }
}

// WidgetDataProvider 扩展
extension WidgetDataProvider {
    func loadColorScheme() -> WidgetColorScheme {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let jsonString = defaults.string(forKey: "widget_color_scheme"),
              let jsonData = jsonString.data(using: .utf8),
              let config = try? JSONDecoder().decode(WidgetThemeConfig.self, from: jsonData) else {
            return ColorSchemeEnvironmentKey.defaultValue
        }
        
        // 根据系统模式选择颜色方案
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        return config.getColorScheme(isDark: isDark)
    }
}

// WidgetThemeConfig 扩展
extension WidgetThemeConfig {
    func getColorScheme(isDark: Bool) -> WidgetColorScheme {
        switch mode {
        case "light":
            return light
        case "dark":
            return dark
        default:
            return isDark ? dark : light
        }
    }
}
```

---

## Android 小组件使用颜色方案

```kotlin
// android/app/src/main/kotlin/com/bapaws/planbook/widget/TodayWidgetProvider.kt

class TodayWidgetProvider : AppWidgetProvider() {
    
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val dataProvider = WidgetDataProvider(context)
        val tasks = dataProvider.getTodayTasks(5)
        val colorScheme = dataProvider.getColorScheme()
        
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, tasks, colorScheme)
        }
    }
    
    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        tasks: List<WidgetTask>,
        colorScheme: WidgetColorScheme
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_today_medium)
        
        // 设置背景色
        views.setInt(R.id.widget_container, "setBackgroundColor", colorScheme.backgroundInt())
        
        // 设置头部
        val completedCount = tasks.count { it.isCompleted }
        views.setTextViewText(R.id.tv_header, "今天待办 ${completedCount}/${tasks.size}")
        views.setTextColor(R.id.tv_header, colorScheme.onSurfaceInt())
        views.setInt(R.id.header_container, "setBackgroundColor", colorScheme.surfaceInt())
        
        // 设置分割线颜色
        views.setInt(R.id.divider, "setBackgroundColor", colorScheme.outlineInt())
        
        // 清空列表
        views.removeAllViews(R.id.task_list)
        
        // 添加任务项
        tasks.take(4).forEach { task ->
            val taskView = RemoteViews(context.packageName, R.layout.widget_task_item)
            
            // 设置完成图标颜色
            val completeIconRes = if (task.isCompleted) 
                R.drawable.ic_check_circle_filled 
            else 
                R.drawable.ic_circle_outline
            views.setImageViewResource(R.id.iv_complete, completeIconRes)
            
            val completeColor = if (task.isCompleted) 
                colorScheme.success 
            else 
                getPriorityColor(task.priority, colorScheme)
            views.setImageViewColorFilter(R.id.iv_complete, completeColor)
            
            // 设置标题
            views.setTextViewText(R.id.tv_title, task.title)
            views.setTextColor(R.id.tv_title, 
                if (task.isCompleted) colorScheme.onSurfaceVariant else colorScheme.onSurface
            )
            
            // 设置优先级指示点
            views.setImageViewColorFilter(
                R.id.iv_priority, 
                getPriorityColor(task.priority, colorScheme)
            )
            
            views.addView(R.id.task_list, taskView)
        }
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
    
    private fun getPriorityColor(priority: WidgetTask.TaskPriority, colorScheme: WidgetColorScheme): String {
        return when (priority) {
            WidgetTask.TaskPriority.HIGH -> colorScheme.priorityColors.importantUrgent
            WidgetTask.TaskPriority.MEDIUM -> colorScheme.priorityColors.importantNotUrgent
            WidgetTask.TaskPriority.LOW -> colorScheme.priorityColors.urgentUnimportant
            WidgetTask.TaskPriority.NONE -> colorScheme.priorityColors.notUrgentUnimportant
        }
    }
}

// WidgetDataProvider 扩展
class WidgetDataProvider(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("widget_data", Context.MODE_PRIVATE)
    private val gson = Gson()
    
    fun getColorScheme(): WidgetColorScheme {
        val json = prefs.getString("widget_color_scheme", null)
        return if (json != null) {
            try {
                val config = gson.fromJson(json, WidgetThemeConfig::class.java)
                val isDark = isDarkMode()
                config.getColorScheme(isDark)
            } catch (e: Exception) {
                DefaultColorScheme.LIGHT
            }
        } else {
            DefaultColorScheme.LIGHT
        }
    }
    
    private fun isDarkMode(): Boolean {
        val currentNightMode = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return currentNightMode == Configuration.UI_MODE_NIGHT_YES
    }
}
```

---

## 完整的推送数据结构

```dart
// 最终推送到小组件的 JSON 结构
{
  "timestamp": "2024-01-15T10:30:00Z",
  "tasks": {
    "today": [...],
    "inbox": [...],
    "quadrantCounts": {...}
  },
  "theme": {
    "light": {
      "primary": "#2196F3",
      "secondary": "#03DAC6",
      "background": "#FFFFFF",
      "surface": "#F5F5F5",
      "onPrimary": "#FFFFFF",
      "onBackground": "#000000",
      "onSurface": "#000000",
      "onSurfaceVariant": "#666666",
      "outline": "#E0E0E0",
      "error": "#B00020",
      "success": "#4CAF50",
      "warning": "#FF9800",
      "priorityColors": {
        "importantUrgent": "#FF4444",
        "importantNotUrgent": "#FFBB33",
        "urgentUnimportant": "#FF8800",
        "notUrgentUnimportant": "#9E9E9E"
      }
    },
    "dark": {
      // ... 暗色主题颜色
    },
    "mode": "system"  // light, dark, system
  }
}
```

---

## 更新触发时机

| 时机 | 操作 |
|------|------|
| App 启动 | 同步当前主题 |
| 系统深色模式切换 | 自动同步 |
| 用户在设置中修改主题色 | 立即同步 |
| 用户修改优先级颜色 | 立即同步 |
| 每天凌晨 | 定时刷新（可选）|

---

## 注意事项

1. **默认值**：小组件需要有合理的默认颜色，防止首次使用或数据丢失时显示异常
2. **容错处理**：颜色解析失败时使用默认颜色
3. **性能优化**：颜色同步可以和任务数据同步合并，减少 I/O 操作
4. **缓存策略**：可以在原生端缓存颜色方案，避免每次刷新都解析 JSON
