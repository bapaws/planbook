# 小组件主题ID同步方案

## 概述

基于项目现有的 `AppStyles` 和 `ColorScheme` 结构，设计一套轻量级的主题同步方案：
- **小组件内置**所有配色方案
- **只同步主题ID**（如 "red", "blue"）和深色模式状态
- **减少90%数据传输量**，同时保持完美一致性

## 现有颜色结构分析

### AppStyles (planbook_core)
```dart
class AppColors {
  final Color primary;
  final Color label;  // onBackground 主文本
  final Color secondaryLabel;  // onSurface 次要文本
  final Color tertiaryLabel;
  final Color quaternaryLabel;
  final Color background;
  final Color secondaryBackground;  // surface
  final Color tertiaryBackground;
  final Color quaternaryBackground;
  final Color shadow;
  final Color outline;
}
```

### ColorScheme (Material 3)
```dart
class ColorScheme {
  final int primaryArgb;
  final int onPrimaryArgb;
  final int surfaceArgb;
  final int onSurfaceArgb;
  // ... 完整的 Material 3 颜色系统
}
```

---

## 方案设计

### 核心思路

```
┌─────────────────────────────────────────────────────────┐
│  Flutter App                                            │
│  ┌─────────────┐   ┌──────────────────────────────┐    │
│  │ AppStyles   │──▶│ 只同步: {                     │    │
│  │ (主色调)    │   │   "themeId": "red",          │    │
│  │             │   │   "darkMode": false,         │    │
│  │             │   │   "priorityColors": {...}    │    │
│  └─────────────┘   │ }                            │    │
│                    └──────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│  小组件 (iOS/Android)                                    │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 内置配色方案:                                     │   │
│  │ {                                               │   │
│  │   "red": { light: {...}, dark: {...} },        │   │
│  │   "blue": { light: {...}, dark: {...} },       │   │
│  │   "green": { light: {...}, dark: {...} },      │   │
│  │   ...                                           │   │
│  │ }                                               │   │
│  └─────────────────────────────────────────────────┘   │
│                           │                             │
│                           ▼                             │
│  根据 themeId + darkMode 选择对应的颜色方案                │
└─────────────────────────────────────────────────────────┘
```

### 数据模型

#### Flutter 端 - 主题配置

```dart
// packages/planbook_api/lib/src/widget/widget_theme_config.dart

import 'package:json_annotation/json_annotation.dart';

part 'widget_theme_config.g.dart';

/// 小组件主题配置（轻量级）
/// 
/// 只包含主题ID和优先级颜色，小组件内置完整配色方案
@JsonSerializable()
class WidgetThemeConfig {
  /// 主题ID (如: "red", "blue", "green", "purple", "orange")
  final String themeId;
  
  /// 深色模式状态
  final bool isDarkMode;
  
  /// 四象限优先级颜色（用户可能自定义）
  final WidgetPriorityColors? priorityColors;
  
  const WidgetThemeConfig({
    required this.themeId,
    required this.isDarkMode,
    this.priorityColors,
  });
  
  factory WidgetThemeConfig.fromJson(Map<String, dynamic> json) => 
      _$WidgetThemeConfigFromJson(json);
  
  Map<String, dynamic> toJson() => _$WidgetThemeConfigToJson(this);
  
  /// 默认配置
  static const WidgetThemeConfig defaults = WidgetThemeConfig(
    themeId: 'red',
    isDarkMode: false,
    priorityColors: null,
  );
}

/// 优先级颜色（可选，用于用户自定义）
@JsonSerializable()
class WidgetPriorityColors {
  final String importantUrgent;      // 重要且紧急
  final String importantNotUrgent;   // 重要不紧急
  final String urgentUnimportant;    // 紧急不重要
  final String notUrgentUnimportant; // 不紧急不重要
  
  const WidgetPriorityColors({
    required this.importantUrgent,
    required this.importantNotUrgent,
    required this.urgentUnimportant,
    required this.notUrgentUnimportant,
  });
  
  factory WidgetPriorityColors.fromJson(Map<String, dynamic> json) => 
      _$WidgetPriorityColorsFromJson(json);
  
  Map<String, dynamic> toJson() => _$WidgetPriorityColorsToJson(this);
  
  /// 默认优先级颜色
  static const WidgetPriorityColors defaults = WidgetPriorityColors(
    importantUrgent: '#FF4444',
    importantNotUrgent: '#FFBB33',
    urgentUnimportant: '#FF8800',
    notUrgentUnimportant: '#9E9E9E',
  );
}
```

#### iOS 端 - 内置配色方案

```swift
// ios/Widgets/WidgetTheme.swift

import SwiftUI

/// 主题ID枚举
enum ThemeId: String, CaseIterable {
    case red    = "red"
    case blue   = "blue"
    case green  = "green"
    case purple = "purple"
    case orange = "orange"
    case pink   = "pink"
    case teal   = "teal"
    case indigo = "indigo"
    case brown  = "brown"
    case gray   = "gray"
}

/// 颜色方案结构（对应 AppColors）
struct AppColorScheme {
    let primary: String
    let label: String
    let secondaryLabel: String
    let tertiaryLabel: String
    let quaternaryLabel: String
    let background: String
    let secondaryBackground: String
    let tertiaryBackground: String
    let quaternaryBackground: String
    let shadow: String
    let outline: String
    
    // 扩展属性
    var primaryColor: Color { Color(hex: primary) }
    var backgroundColor: Color { Color(hex: background) }
    var surfaceColor: Color { Color(hex: secondaryBackground) }
    var onSurfaceColor: Color { Color(hex: label) }
    var onSurfaceVariantColor: Color { Color(hex: secondaryLabel) }
}

/// 主题管理器（内置所有配色方案）
struct WidgetThemeManager {
    
    // MARK: - 内置配色方案
    
    static let themes: [ThemeId: ThemePair] = [
        .red: ThemePair(
            light: AppColorScheme(
                primary: "#F44336",
                label: "#181818",
                secondaryLabel: "#414144",
                tertiaryLabel: "#71717A",
                quaternaryLabel: "#A1A1AA",
                background: "#FFFFFF",
                secondaryBackground: "#F4F4F5",
                tertiaryBackground: "#E4E4E7",
                quaternaryBackground: "#D4D4D8",
                shadow: "#000000",
                outline: "#E4E4E7"
            ),
            dark: AppColorScheme(
                primary: "#F44336",
                label: "#FFFFFF",
                secondaryLabel: "#E4E4E7",
                tertiaryLabel: "#D4D4D8",
                quaternaryLabel: "#C4C4C4",
                background: "#000000",
                secondaryBackground: "#181818",
                tertiaryBackground: "#282828",
                quaternaryBackground: "#383838",
                shadow: "#000000",
                outline: "#E4E4E7"
            )
        ),
        
        .blue: ThemePair(
            light: AppColorScheme(
                primary: "#2196F3",
                label: "#181818",
                secondaryLabel: "#414144",
                tertiaryLabel: "#71717A",
                quaternaryLabel: "#A1A1AA",
                background: "#FFFFFF",
                secondaryBackground: "#F4F4F5",
                tertiaryBackground: "#E4E4E7",
                quaternaryBackground: "#D4D4D8",
                shadow: "#000000",
                outline: "#E4E4E7"
            ),
            dark: AppColorScheme(
                primary: "#64B5F6",
                label: "#FFFFFF",
                secondaryLabel: "#E4E4E7",
                tertiaryLabel: "#D4D4D8",
                quaternaryLabel: "#C4C4C4",
                background: "#000000",
                secondaryBackground: "#181818",
                tertiaryBackground: "#282828",
                quaternaryBackground: "#383838",
                shadow: "#000000",
                outline: "#E4E4E7"
            )
        ),
        
        .green: ThemePair(
            light: AppColorScheme(
                primary: "#4CAF50",
                label: "#181818",
                secondaryLabel: "#414144",
                tertiaryLabel: "#71717A",
                quaternaryLabel: "#A1A1AA",
                background: "#FFFFFF",
                secondaryBackground: "#F4F4F5",
                tertiaryBackground: "#E4E4E7",
                quaternaryBackground: "#D4D4D8",
                shadow: "#000000",
                outline: "#E4E4E7"
            ),
            dark: AppColorScheme(
                primary: "#81C784",
                label: "#FFFFFF",
                secondaryLabel: "#E4E4E7",
                tertiaryLabel: "#D4D4D8",
                quaternaryLabel: "#C4C4C4",
                background: "#000000",
                secondaryBackground: "#181818",
                tertiaryBackground: "#282828",
                quaternaryBackground: "#383838",
                shadow: "#000000",
                outline: "#E4E4E7"
            )
        ),
        
        // ... 更多配色方案
        .purple: ThemePair(
            light: AppColorScheme(
                primary: "#9C27B0",
                label: "#181818",
                secondaryLabel: "#414144",
                tertiaryLabel: "#71717A",
                quaternaryLabel: "#A1A1AA",
                background: "#FFFFFF",
                secondaryBackground: "#F4F4F5",
                tertiaryBackground: "#E4E4E7",
                quaternaryBackground: "#D4D4D8",
                shadow: "#000000",
                outline: "#E4E4E7"
            ),
            dark: AppColorScheme(
                primary: "#BA68C8",
                label: "#FFFFFF",
                secondaryLabel: "#E4E4E7",
                tertiaryLabel: "#D4D4D8",
                quaternaryLabel: "#C4C4C4",
                background: "#000000",
                secondaryBackground: "#181818",
                tertiaryBackground: "#282828",
                quaternaryBackground: "#383838",
                shadow: "#000000",
                outline: "#E4E4E7"
            )
        ),
        
        .orange: ThemePair(
            light: AppColorScheme(
                primary: "#FF9800",
                label: "#181818",
                secondaryLabel: "#414144",
                tertiaryLabel: "#71717A",
                quaternaryLabel: "#A1A1AA",
                background: "#FFFFFF",
                secondaryBackground: "#F4F4F5",
                tertiaryBackground: "#E4E4E7",
                quaternaryBackground: "#D4D4D8",
                shadow: "#000000",
                outline: "#E4E4E7"
            ),
            dark: AppColorScheme(
                primary: "#FFB74D",
                label: "#FFFFFF",
                secondaryLabel: "#E4E4E7",
                tertiaryLabel: "#D4D4D8",
                quaternaryLabel: "#C4C4C4",
                background: "#000000",
                secondaryBackground: "#181818",
                tertiaryBackground: "#282828",
                quaternaryBackground: "#383838",
                shadow: "#000000",
                outline: "#E4E4E7"
            )
        )
    ]
    
    // MARK: - 获取颜色方案
    
    static func getColorScheme(themeId: String, isDarkMode: Bool) -> AppColorScheme {
        let id = ThemeId(rawValue: themeId) ?? .red
        let pair = themes[id] ?? themes[.red]!
        return isDarkMode ? pair.dark : pair.light
    }
    
    // MARK: - 从配置获取
    
    static func getColorScheme(from config: WidgetThemeConfig) -> AppColorScheme {
        return getColorScheme(themeId: config.themeId, isDarkMode: config.isDarkMode)
    }
}

struct ThemePair {
    let light: AppColorScheme
    let dark: AppColorScheme
}

/// 小组件主题配置（从 JSON 解析）
struct WidgetThemeConfig: Codable {
    let themeId: String
    let isDarkMode: Bool
    let priorityColors: WidgetPriorityColors?
    
    struct WidgetPriorityColors: Codable {
        let importantUrgent: String
        let importantNotUrgent: String
        let urgentUnimportant: String
        let notUrgentUnimportant: String
    }
}

/// 优先级颜色扩展（支持用户自定义）
extension WidgetThemeManager {
    static func getPriorityColors(config: WidgetThemeConfig) -> WidgetPriorityColors {
        // 如果用户自定义了优先级颜色，使用自定义的
        if let custom = config.priorityColors {
            return custom
        }
        
        // 否则使用默认的
        return WidgetPriorityColors(
            importantUrgent: "#FF4444",
            importantNotUrgent: "#FFBB33",
            urgentUnimportant: "#FF8800",
            notUrgentUnimportant: "#9E9E9E"
        )
    }
}

struct WidgetPriorityColors {
    let importantUrgent: String
    let importantNotUrgent: String
    let urgentUnimportant: String
    let notUrgentUnimportant: String
    
    var importantUrgentColor: Color { Color(hex: importantUrgent) }
    var importantNotUrgentColor: Color { Color(hex: importantNotUrgent) }
    var urgentUnimportantColor: Color { Color(hex: urgentUnimportant) }
    var notUrgentUnimportantColor: Color { Color(hex: notUrgentUnimportant) }
}
```

#### Android 端 - 内置配色方案

```kotlin
// android/app/src/main/kotlin/com/bapaws/planbook/widget/WidgetTheme.kt

package com.bapaws.planbook.widget

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import androidx.core.graphics.toColorInt

/// 主题ID枚举
enum class ThemeId(val value: String) {
    RED("red"),
    BLUE("blue"),
    GREEN("green"),
    PURPLE("purple"),
    ORANGE("orange"),
    PINK("pink"),
    TEAL("teal"),
    INDIGO("indigo"),
    BROWN("brown"),
    GRAY("gray");
    
    companion object {
        fun fromString(value: String): ThemeId {
            return values().find { it.value == value } ?: RED
        }
    }
}

/// 颜色方案数据类（对应 AppColors）
data class AppColorScheme(
    val primary: String,
    val label: String,
    val secondaryLabel: String,
    val tertiaryLabel: String,
    val quaternaryLabel: String,
    val background: String,
    val secondaryBackground: String,
    val tertiaryBackground: String,
    val quaternaryBackground: String,
    val shadow: String,
    val outline: String
) {
    // 转换方法
    fun primaryInt(): Int = primary.toColorInt()
    fun labelInt(): Int = label.toColorInt()
    fun secondaryLabelInt(): Int = secondaryLabel.toColorInt()
    fun tertiaryLabelInt(): Int = tertiaryLabel.toColorInt()
    fun quaternaryLabelInt(): Int = quaternaryLabel.toColorInt()
    fun backgroundInt(): Int = background.toColorInt()
    fun secondaryBackgroundInt(): Int = secondaryBackground.toColorInt()
    fun tertiaryBackgroundInt(): Int = tertiaryBackground.toColorInt()
    fun quaternaryBackgroundInt(): Int = quaternaryBackground.toColorInt()
    fun shadowInt(): Int = shadow.toColorInt()
    fun outlineInt(): Int = outline.toColorInt()
}

/// 主题对（亮色/暗色）
data class ThemePair(
    val light: AppColorScheme,
    val dark: AppColorScheme
)

/// 优先级颜色
data class PriorityColors(
    val importantUrgent: String,
    val importantNotUrgent: String,
    val urgentUnimportant: String,
    val notUrgentUnimportant: String
) {
    companion object {
        val DEFAULT = PriorityColors(
            importantUrgent = "#FF4444",
            importantNotUrgent = "#FFBB33",
            urgentUnimportant = "#FF8800",
            notUrgentUnimportant = "#9E9E9E"
        )
    }
    
    fun importantUrgentInt(): Int = importantUrgent.toColorInt()
    fun importantNotUrgentInt(): Int = importantNotUrgent.toColorInt()
    fun urgentUnimportantInt(): Int = urgentUnimportant.toColorInt()
    fun notUrgentUnimportantInt(): Int = notUrgentUnimportant.toColorInt()
}

/// 小组件主题管理器（内置所有配色方案）
object WidgetThemeManager {
    
    /// 内置配色方案
    private val THEMES: Map<ThemeId, ThemePair> = mapOf(
        ThemeId.RED to ThemePair(
            light = AppColorScheme(
                primary = "#F44336",
                label = "#181818",
                secondaryLabel = "#414144",
                tertiaryLabel = "#71717A",
                quaternaryLabel = "#A1A1AA",
                background = "#FFFFFF",
                secondaryBackground = "#F4F4F5",
                tertiaryBackground = "#E4E4E7",
                quaternaryBackground = "#D4D4D8",
                shadow = "#000000",
                outline = "#E4E4E7"
            ),
            dark = AppColorScheme(
                primary = "#F44336",
                label = "#FFFFFF",
                secondaryLabel = "#E4E4E7",
                tertiaryLabel = "#D4D4D8",
                quaternaryLabel = "#C4C4C4",
                background = "#000000",
                secondaryBackground = "#181818",
                tertiaryBackground = "#282828",
                quaternaryBackground = "#383838",
                shadow = "#000000",
                outline = "#E4E4E7"
            )
        ),
        
        ThemeId.BLUE to ThemePair(
            light = AppColorScheme(
                primary = "#2196F3",
                label = "#181818",
                secondaryLabel = "#414144",
                tertiaryLabel = "#71717A",
                quaternaryLabel = "#A1A1AA",
                background = "#FFFFFF",
                secondaryBackground = "#F4F4F5",
                tertiaryBackground = "#E4E4E7",
                quaternaryBackground = "#D4D4D8",
                shadow = "#000000",
                outline = "#E4E4E7"
            ),
            dark = AppColorScheme(
                primary = "#64B5F6",
                label = "#FFFFFF",
                secondaryLabel = "#E4E4E7",
                tertiaryLabel = "#D4D4D8",
                quaternaryLabel = "#C4C4C4",
                background = "#000000",
                secondaryBackground = "#181818",
                tertiaryBackground = "#282828",
                quaternaryBackground = "#383838",
                shadow = "#000000",
                outline = "#E4E4E7"
            )
        ),
        
        ThemeId.GREEN to ThemePair(
            light = AppColorScheme(
                primary = "#4CAF50",
                label = "#181818",
                secondaryLabel = "#414144",
                tertiaryLabel = "#71717A",
                quaternaryLabel = "#A1A1AA",
                background = "#FFFFFF",
                secondaryBackground = "#F4F4F5",
                tertiaryBackground = "#E4E4E7",
                quaternaryBackground = "#D4D4D8",
                shadow = "#000000",
                outline = "#E4E4E7"
            ),
            dark = AppColorScheme(
                primary = "#81C784",
                label = "#FFFFFF",
                secondaryLabel = "#E4E4E7",
                tertiaryLabel = "#D4D4D8",
                quaternaryLabel = "#C4C4C4",
                background = "#000000",
                secondaryBackground = "#181818",
                tertiaryBackground = "#282828",
                quaternaryBackground = "#383838",
                shadow = "#000000",
                outline = "#E4E4E7"
            )
        ),
        
        // ... 更多配色方案
        ThemeId.PURPLE to ThemePair(
            light = AppColorScheme(
                primary = "#9C27B0",
                label = "#181818",
                secondaryLabel = "#414144",
                tertiaryLabel = "#71717A",
                quaternaryLabel = "#A1A1AA",
                background = "#FFFFFF",
                secondaryBackground = "#F4F4F5",
                tertiaryBackground = "#E4E4E7",
                quaternaryBackground = "#D4D4D8",
                shadow = "#000000",
                outline = "#E4E4E7"
            ),
            dark = AppColorScheme(
                primary = "#BA68C8",
                label = "#FFFFFF",
                secondaryLabel = "#E4E4E7",
                tertiaryLabel = "#D4D4D8",
                quaternaryLabel = "#C4C4C4",
                background = "#000000",
                secondaryBackground = "#181818",
                tertiaryBackground = "#282828",
                quaternaryBackground = "#383838",
                shadow = "#000000",
                outline = "#E4E4E7"
            )
        ),
        
        ThemeId.ORANGE to ThemePair(
            light = AppColorScheme(
                primary = "#FF9800",
                label = "#181818",
                secondaryLabel = "#414144",
                tertiaryLabel = "#71717A",
                quaternaryLabel = "#A1A1AA",
                background = "#FFFFFF",
                secondaryBackground = "#F4F4F5",
                tertiaryBackground = "#E4E4E7",
                quaternaryBackground = "#D4D4D8",
                shadow = "#000000",
                outline = "#E4E4E7"
            ),
            dark = AppColorScheme(
                primary = "#FFB74D",
                label = "#FFFFFF",
                secondaryLabel = "#E4E4E7",
                tertiaryLabel = "#D4D4D8",
                quaternaryLabel = "#C4C4C4",
                background = "#000000",
                secondaryBackground = "#181818",
                tertiaryBackground = "#282828",
                quaternaryBackground = "#383838",
                shadow = "#000000",
                outline = "#E4E4E7"
            )
        )
    )
    
    /// 获取颜色方案
    @JvmStatic
    fun getColorScheme(themeId: String, isDarkMode: Boolean): AppColorScheme {
        val id = ThemeId.fromString(themeId)
        val pair = THEMES[id] ?: THEMES[ThemeId.RED]!!
        return if (isDarkMode) pair.dark else pair.light
    }
    
    /// 从配置获取
    @JvmStatic
    fun getColorScheme(config: WidgetThemeConfig): AppColorScheme {
        return getColorScheme(config.themeId, config.isDarkMode)
    }
    
    /// 获取优先级颜色
    @JvmStatic
    fun getPriorityColors(config: WidgetThemeConfig): PriorityColors {
        // 如果用户自定义了优先级颜色，使用自定义的
        return config.priorityColors ?: PriorityColors.DEFAULT
    }
}

/// 小组件主题配置（从 SharedPreferences 读取）
data class WidgetThemeConfig(
    val themeId: String,
    val isDarkMode: Boolean,
    val priorityColors: PriorityColors? = null
) {
    companion object {
        const val DEFAULT_THEME_ID = "red"
        
        fun fromSharedPreferences(context: Context): WidgetThemeConfig {
            val prefs = context.getSharedPreferences("widget_data", Context.MODE_PRIVATE)
            val themeId = prefs.getString("theme_id", DEFAULT_THEME_ID) ?: DEFAULT_THEME_ID
            val isDarkMode = prefs.getBoolean("is_dark_mode", false)
            
            // 读取自定义优先级颜色（可选）
            val priorityColors = if (prefs.contains("priority_important_urgent")) {
                PriorityColors(
                    importantUrgent = prefs.getString("priority_important_urgent", "#FF4444")!!,
                    importantNotUrgent = prefs.getString("priority_important_not_urgent", "#FFBB33")!!,
                    urgentUnimportant = prefs.getString("priority_urgent_unimportant", "#FF8800")!!,
                    notUrgentUnimportant = prefs.getString("priority_not_urgent_unimportant", "#9E9E9E")!!
                )
            } else null
            
            return WidgetThemeConfig(themeId, isDarkMode, priorityColors)
        }
    }
}

/// RemoteViews 扩展方法
fun RemoteViews.setBackgroundColorRes(viewId: Int, colorScheme: AppColorScheme, isDark: Boolean) {
    setInt(viewId, "setBackgroundColor", colorScheme.backgroundInt())
}

fun RemoteViews.setTextColorRes(viewId: Int, colorScheme: AppColorScheme, colorType: TextColorType) {
    val color = when (colorType) {
        TextColorType.LABEL -> colorScheme.labelInt()
        TextColorType.SECONDARY_LABEL -> colorScheme.secondaryLabelInt()
        TextColorType.TERTIARY_LABEL -> colorScheme.tertiaryLabelInt()
        TextColorType.PRIMARY -> colorScheme.primaryInt()
    }
    setTextColor(viewId, color)
}

enum class TextColorType {
    LABEL,
    SECONDARY_LABEL,
    TERTIARY_LABEL,
    PRIMARY
}
```

---

## Flutter 端同步服务

```dart
// lib/services/widget_theme_sync_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题同步服务
/// 
/// 只同步主题ID和深色模式状态，小组件内置完整配色方案
class WidgetThemeSyncService {
  static const _appGroupId = 'group.GM4766U38W.com.bapaws.habits';
  static const _themeIdKey = 'widget_theme_id';
  static const _isDarkModeKey = 'widget_is_dark_mode';
  static const _priorityColorsKey = 'widget_priority_colors';
  
  /// 可用的主题ID列表
  static const List<String> availableThemeIds = [
    'red',
    'blue', 
    'green',
    'purple',
    'orange',
    'pink',
    'teal',
    'indigo',
    'brown',
    'gray',
  ];
  
  /// 同步当前主题到小组件
  /// 
  /// 从 AppStyles 获取当前主题配置，提取 themeId 和 darkMode
  static Future<void> syncThemeToWidget() async {
    // 获取当前主题ID（从 AppStyles 或设置中）
    final themeId = _getCurrentThemeId();
    
    // 获取深色模式状态
    final isDarkMode = _getCurrentDarkMode();
    
    // 获取自定义优先级颜色（如果用户有设置）
    final priorityColors = _getCustomPriorityColors();
    
    // 保存到共享存储
    await _saveThemeConfig(
      themeId: themeId,
      isDarkMode: isDarkMode,
      priorityColors: priorityColors,
    );
    
    // 触发小组件刷新
    await _reloadWidgets();
  }
  
  /// 获取当前主题ID
  static String _getCurrentThemeId() {
    // 从 AppStyles 获取主色调，映射到 themeId
    final primaryColor = AppStyles.primary;
    return _colorToThemeId(primaryColor);
  }
  
  /// 将颜色映射到主题ID
  static String _colorToThemeId(Color color) {
    // 根据主色调值映射到最接近的 themeId
    final hue = HSLColor.fromColor(color).hue;
    
    if (hue >= 330 || hue < 15) return 'red';
    if (hue >= 15 && hue < 45) return 'orange';
    if (hue >= 45 && hue < 75) return 'yellow';
    if (hue >= 75 && hue < 150) return 'green';
    if (hue >= 150 && hue < 190) return 'teal';
    if (hue >= 190 && hue < 260) return 'blue';
    if (hue >= 260 && hue < 290) return 'indigo';
    if (hue >= 290 && hue < 330) return 'purple';
    
    return 'red'; // 默认
  }
  
  /// 获取当前深色模式状态
  static bool _getCurrentDarkMode() {
    // 从 AppStyles 或设置中获取
    final brightness = AppStyles.brightness; // 假设有这个属性
    return brightness == Brightness.dark;
  }
  
  /// 获取自定义优先级颜色
  static WidgetPriorityColors? _getCustomPriorityColors() {
    // 从设置中读取用户自定义的优先级颜色
    // 如果用户没有自定义，返回 null，小组件使用默认颜色
    final prefs = SharedPreferences.getInstance() as SharedPreferences;
    
    final importantUrgent = prefs.getString('priority_important_urgent');
    if (importantUrgent == null) return null;
    
    return WidgetPriorityColors(
      importantUrgent: importantUrgent,
      importantNotUrgent: prefs.getString('priority_important_not_urgent') ?? '#FFBB33',
      urgentUnimportant: prefs.getString('priority_urgent_unimportant') ?? '#FF8800',
      notUrgentUnimportant: prefs.getString('priority_not_urgent_unimportant') ?? '#9E9E9E',
    );
  }
  
  /// 保存主题配置到共享存储
  static Future<void> _saveThemeConfig({
    required String themeId,
    required bool isDarkMode,
    WidgetPriorityColors? priorityColors,
  }) async {
    final config = WidgetThemeConfig(
      themeId: themeId,
      isDarkMode: isDarkMode,
      priorityColors: priorityColors,
    );
    
    if (Platform.isIOS) {
      await AppHomeWidget.setAppGroupId(_appGroupId);
      await AppHomeWidget.saveWidgetData(_themeIdKey, themeId);
      await AppHomeWidget.saveWidgetData(_isDarkModeKey, isDarkMode);
      if (priorityColors != null) {
        await AppHomeWidget.saveWidgetData(_priorityColorsKey, jsonEncode(priorityColors.toJson()));
      }
    } else if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeIdKey, themeId);
      await prefs.setBool(_isDarkModeKey, isDarkMode);
      if (priorityColors != null) {
        await prefs.setString(_priorityColorsKey, jsonEncode(priorityColors.toJson()));
      }
    }
  }
  
  /// 刷新所有小组件
  static Future<void> _reloadWidgets() async {
    // 刷新 Today Widget
    await HomeWidget.updateWidget(
      name: 'TodayWidget',
      androidName: 'TodayWidgetProvider',
      iOSName: 'TodayWidget',
    );
    
    // 刷新 Quadrant Widget
    await HomeWidget.updateWidget(
      name: 'QuadrantWidget',
      androidName: 'QuadrantWidgetProvider',
      iOSName: 'QuadrantWidget',
    );
    
    // ... 其他小组件
  }
  
  /// 监听主题变化
  static void setupThemeListener() {
    // 使用 AppStyles 的通知监听主题变化
    AppStyles.instance.addListener(() {
      syncThemeToWidget();
    });
  }
}
```

---

## 小组件使用示例

### iOS Today Widget

```swift
// ios/Widgets/TodayWidget.swift

import WidgetKit
import SwiftUI

struct TodayWidgetView: View {
    var entry: TodayWidgetEntry
    @Environment(\.colorScheme) var systemColorScheme
    
    var body: some View {
        // 获取主题配置
        let config = entry.themeConfig
        let colorScheme = WidgetThemeManager.getColorScheme(from: config)
        let priorityColors = WidgetThemeManager.getPriorityColors(config: config)
        
        VStack(alignment: .leading, spacing: 8) {
            // 头部
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
                    TaskRowView(
                        task: task,
                        colorScheme: colorScheme,
                        priorityColors: priorityColors
                    )
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
    let colorScheme: AppColorScheme
    let priorityColors: WidgetPriorityColors
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : priorityColor)
                .font(.system(size: 18))
            
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
            return priorityColors.importantUrgentColor
        case .medium:
            return priorityColors.importantNotUrgentColor
        case .low:
            return priorityColors.urgentUnimportantColor
        case .none:
            return priorityColors.notUrgentUnimportantColor
        }
    }
}
```

### Android Today Widget

```kotlin
// android/app/src/main/kotlin/com/bapaws/planbook/widget/TodayWidgetProvider.kt

class TodayWidgetProvider : AppWidgetProvider() {
    
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val dataProvider = WidgetDataProvider(context)
        val tasks = dataProvider.getTodayTasks(5)
        
        // 读取主题配置
        val themeConfig = WidgetThemeConfig.fromSharedPreferences(context)
        val colorScheme = WidgetThemeManager.getColorScheme(themeConfig)
        val priorityColors = WidgetThemeManager.getPriorityColors(themeConfig)
        
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, tasks, colorScheme, priorityColors)
        }
    }
    
    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        tasks: List<WidgetTask>,
        colorScheme: AppColorScheme,
        priorityColors: PriorityColors
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_today_medium)
        
        // 设置背景色
        views.setInt(R.id.widget_container, "setBackgroundColor", colorScheme.backgroundInt())
        
        // 设置头部
        val completedCount = tasks.count { it.isCompleted }
        views.setTextViewText(R.id.tv_header, "今天待办 ${completedCount}/${tasks.size}")
        views.setTextColor(R.id.tv_header, colorScheme.labelInt())
        views.setInt(R.id.header_container, "setBackgroundColor", colorScheme.secondaryBackgroundInt())
        
        // 设置分割线
        views.setInt(R.id.divider, "setBackgroundColor", colorScheme.outlineInt())
        
        // 清空并重新添加任务
        views.removeAllViews(R.id.task_list)
        
        tasks.take(4).forEach { task ->
            val taskView = RemoteViews(context.packageName, R.layout.widget_task_item)
            
            // 完成图标
            val completeIcon = if (task.isCompleted) 
                R.drawable.ic_check_circle_filled 
            else 
                R.drawable.ic_circle_outline
            views.setImageViewResource(R.id.iv_complete, completeIcon)
            
            // 根据优先级设置图标颜色
            val priorityColor = when (task.priority) {
                WidgetTask.TaskPriority.HIGH -> priorityColors.importantUrgentInt()
                WidgetTask.TaskPriority.MEDIUM -> priorityColors.importantNotUrgentInt()
                WidgetTask.TaskPriority.LOW -> priorityColors.urgentUnimportantInt()
                WidgetTask.TaskPriority.NONE -> priorityColors.notUrgentUnimportantInt()
            }
            views.setInt(R.id.iv_complete, "setColorFilter", priorityColor)
            
            // 任务标题
            views.setTextViewText(R.id.tv_title, task.title)
            val textColor = if (task.isCompleted) 
                colorScheme.secondaryLabelInt() 
            else 
                colorScheme.labelInt()
            views.setTextColor(R.id.tv_title, textColor)
            
            views.addView(R.id.task_list, taskView)
        }
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
```

---

## 数据传输对比

### 传统方案（同步所有颜色值）

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "tasks": { ... },
  "theme": {
    "light": {
      "primary": "#F44336",
      "onPrimary": "#FFFFFF",
      "primaryContainer": "#FFCDD2",
      "onPrimaryContainer": "#B71C1C",
      "secondary": "#FF5722",
      "onSecondary": "#FFFFFF",
      "secondaryContainer": "#FFCCBC",
      "onSecondaryContainer": "#BF360C",
      "tertiary": "...",
      "surface": "...",
      "onSurface": "...",
      "surfaceVariant": "...",
      "onSurfaceVariant": "...",
      "outline": "...",
      "outlineVariant": "...",
      "shadow": "...",
      "scrim": "...",
      "inverseSurface": "...",
      "inverseOnSurface": "...",
      "inversePrimary": "...",
      "error": "...",
      "onError": "...",
      "errorContainer": "...",
      "onErrorContainer": "...",
      "primaryFixed": "...",
      "primaryFixedDim": "...",
      "onPrimaryFixed": "...",
      "onPrimaryFixedVariant": "..."
      // ... 40+ 个颜色值
    },
    "dark": { ... },  // 又是 40+ 个颜色值
    "priorityColors": { ... }
  }
}
// 数据量：~3-5 KB
```

### 新方案（只同步主题ID）

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "tasks": { ... },
  "themeConfig": {
    "themeId": "red",
    "isDarkMode": false,
    "priorityColors": null
  }
}
// 数据量：~50 bytes
// 减少 98% 数据传输量！
```

---

## 配色方案列表

| Theme ID | 主色调 (Light) | 主色调 (Dark) | 说明 |
|----------|----------------|---------------|------|
| red | #F44336 | #F44336 | 红色主题（默认） |
| blue | #2196F3 | #64B5F6 | 蓝色主题 |
| green | #4CAF50 | #81C784 | 绿色主题 |
| purple | #9C27B0 | #BA68C8 | 紫色主题 |
| orange | #FF9800 | #FFB74D | 橙色主题 |
| pink | #E91E63 | #F06292 | 粉色主题 |
| teal | #009688 | #4DB6AC | 青色主题 |
| indigo | #3F51B5 | #7986CB | 靛蓝色主题 |
| brown | #795548 | #A1887F | 棕色主题 |
| gray | #607D8B | #90A4AE | 灰色主题 |

---

## 更新触发时机

| 时机 | 操作 | 数据变化 |
|------|------|----------|
| App 启动 | 同步当前主题 | themeId, isDarkMode |
| 用户切换主题色 | 立即同步 | themeId |
| 系统深色模式切换 | 自动同步 | isDarkMode |
| 用户自定义优先级颜色 | 立即同步 | priorityColors |
| 每天凌晨 | 定时刷新 | 无（仅刷新小组件）|

---

## 注意事项

1. **主题ID映射**：确保 Flutter、iOS、Android 三端使用相同的 themeId 字符串
2. **默认主题**：所有平台默认使用 "red" 主题
3. **降级策略**：如果读取到未知的 themeId，使用默认主题
4. **优先级颜色**：如果用户没有自定义，小组件使用内置默认颜色
5. **同步时机**：主题切换时立即同步，不要等到任务数据同步时一起

---

## 实现步骤

1. **Flutter 端**：
   - 添加 `WidgetThemeConfig` 数据类
   - 实现 `WidgetThemeSyncService`
   - 在主题变化时调用同步

2. **iOS 端**：
   - 创建 `WidgetTheme.swift` 内置所有配色方案
   - 修改小组件从配置读取 themeId

3. **Android 端**：
   - 创建 `WidgetTheme.kt` 内置所有配色方案
   - 修改小组件从 SharedPreferences 读取 themeId

4. **测试**：
   - 验证所有主题颜色正确显示
   - 验证深色模式自动切换
   - 验证自定义优先级颜色生效
