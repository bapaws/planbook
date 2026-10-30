import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_planbook/l10n/l10n.dart';

extension ColorSchemeJsonX on ColorScheme {
  Map<String, int> toJson() => {
    'primary': primary.value,
    'onPrimary': onPrimary.value,
    'primaryContainer': primaryContainer.value,
    'onPrimaryContainer': onPrimaryContainer.value,
    'secondary': secondary.value,
    'onSecondary': onSecondary.value,
    'secondaryContainer': secondaryContainer.value,
    'onSecondaryContainer': onSecondaryContainer.value,
    'tertiary': tertiary.value,
    'onTertiary': onTertiary.value,
    'tertiaryContainer': tertiaryContainer.value,
    'onTertiaryContainer': onTertiaryContainer.value,
    'error': error.value,
    'onError': onError.value,
    'errorContainer': errorContainer.value,
    'onErrorContainer': onErrorContainer.value,
    'background': surface.value,
    'onBackground': onSurface.value,
    'surface': surface.value,
    'onSurface': onSurface.value,
    'surfaceVariant': surfaceContainerHighest.value,
    'onSurfaceVariant': onSurfaceVariant.value,
    'surfaceContainerLowest': surfaceContainerLowest.value,
    'surfaceContainerLow': surfaceContainerLow.value,
    'surfaceContainer': surfaceContainer.value,
    'surfaceContainerHigh': surfaceContainerHigh.value,
    'surfaceContainerHighest': surfaceContainerHighest.value,
    'outline': outline.value,
    'outlineVariant': outlineVariant.value,
    'shadow': shadow.value,
    'scrim': scrim.value,
    'inverseSurface': inverseSurface.value,
    'onInverseSurface': onInverseSurface.value,
    'inversePrimary': inversePrimary.value,
    'surfaceTint': surfaceTint.value,
  };
}

enum AppSeedColors {
  yellow,
  green,
  blue,
  red,
  pink,
  purple,
  orange,
  teal,
  indigo;

  // 主题只依赖种子色与亮暗模式，避免用户资料等状态变化时重复计算配色。
  static final _lightThemes = <AppSeedColors, ThemeData>{};
  static final _darkThemes = <AppSeedColors, ThemeData>{};

  factory AppSeedColors.fromHex(String hex) {
    return AppSeedColors.values.firstWhere(
      (e) => e.hex == hex,
      orElse: () => AppSeedColors.yellow,
    );
  }

  String get hex => color.toARGB32().toRadixString(16).substring(2);
  String getName(BuildContext context) => switch (this) {
    AppSeedColors.yellow => context.l10n.yellow,
    AppSeedColors.green => context.l10n.green,
    AppSeedColors.blue => context.l10n.blue,
    AppSeedColors.red => context.l10n.red,
    AppSeedColors.pink => context.l10n.pink,
    AppSeedColors.purple => context.l10n.purple,
    AppSeedColors.orange => context.l10n.orange,
    AppSeedColors.teal => context.l10n.teal,
    AppSeedColors.indigo => context.l10n.indigo,
  };

  Color get color => switch (this) {
    AppSeedColors.yellow => Colors.yellow,
    AppSeedColors.green => Colors.green,
    AppSeedColors.blue => Colors.blue,
    AppSeedColors.red => Colors.red,
    AppSeedColors.pink => Colors.pink,
    AppSeedColors.purple => Colors.purple,
    AppSeedColors.orange => Colors.orange,
    AppSeedColors.teal => Colors.teal,
    AppSeedColors.indigo => Colors.indigo,
  };

  ThemeData get light => _lightThemes.putIfAbsent(this, _buildLightTheme);

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: color,
    );
    const textTheme = TextTheme();
    return ThemeData(
      splashColor: Colors.transparent,
      scaffoldBackgroundColor: Colors.grey.shade100,
      splashFactory: NoSplash.splashFactory,
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 20,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          systemNavigationBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
          // Android 使用 statusBarIconBrightness
          statusBarIconBrightness: Brightness.dark,
          // iOS 使用 statusBarBrightness（light 主题用 light = 黑色图标）
          statusBarBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
        ),
      ),
      dividerColor: colorScheme.surfaceContainerHighest,
      colorScheme: colorScheme,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  ThemeData get dark => _darkThemes.putIfAbsent(this, _buildDarkTheme);

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: color,
    );
    const textTheme = TextTheme();
    return ThemeData(
      splashColor: Colors.transparent,
      scaffoldBackgroundColor: Colors.grey.shade900,
      splashFactory: NoSplash.splashFactory,
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 20,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        toolbarHeight: kMinInteractiveDimension,
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          systemNavigationBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
          // Android 使用 statusBarIconBrightness
          statusBarIconBrightness: Brightness.light,
          // iOS 使用 statusBarBrightness（dark 主题用 dark = 白色图标）
          statusBarBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
      ),
      // bottomNavigationBarTheme: BottomNavigationBarThemeData
      dividerColor: colorScheme.surfaceContainerHighest,
      colorScheme: colorScheme,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
