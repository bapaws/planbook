import 'package:flutter/material.dart';

/// | NAME           | SIZE |  HEIGHT |  WEIGHT |  SPACING |             |
/// |----------------|------|---------|---------|----------|-------------|
/// | displayLarge   | 57.0 |   64.0  | regular | -0.25    |             |
/// | displayMedium  | 45.0 |   52.0  | regular |  0.0     |             |
/// | displaySmall   | 36.0 |   44.0  | regular |  0.0     |             |
/// | headlineLarge  | 32.0 |   40.0  | regular |  0.0     |             |
/// | headlineMedium | 28.0 |   36.0  | regular |  0.0     |             |
/// | headlineSmall  | 24.0 |   32.0  | regular |  0.0     |             |
/// | titleLarge     | 22.0 |   28.0  | regular |  0.0     |             |
/// | titleMedium    | 16.0 |   24.0  | medium  |  0.15    |             |
/// | titleSmall     | 14.0 |   20.0  | medium  |  0.1     |             |
/// | bodyLarge      | 16.0 |   24.0  | regular |  0.5     |             |
/// | bodyMedium     | 14.0 |   20.0  | regular |  0.25    |             |
/// | bodySmall      | 12.0 |   16.0  | regular |  0.4     |             |
/// | labelLarge     | 14.0 |   20.0  | medium  |  0.1     |             |
/// | labelMedium    | 12.0 |   16.0  | medium  |  0.5     |             |
/// | labelSmall     | 11.0 |   16.0  | medium  |  0.5     |             |
class AppTextStyles {
  const AppTextStyles({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });

  factory AppTextStyles.defaults() {
    return const AppTextStyles(
      displayLarge: TextStyle(
        fontSize: 57,
        height: 64.0 / 57.0,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        height: 52.0 / 45.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        height: 44.0 / 36.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 40.0 / 32.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 36.0 / 28.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 32.0 / 24.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        height: 28.0 / 22.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 24.0 / 16.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 20.0 / 14.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 24.0 / 16.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20.0 / 14.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 16.0 / 12.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 20.0 / 14.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 16.0 / 12.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 16.0 / 11.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;

  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;

  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;

  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;

  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;
}

class AppColors {
  const AppColors({
    required this.primary,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.quaternaryLabel,
    required this.background,
    required this.secondaryBackground,
    required this.tertiaryBackground,
    required this.quaternaryBackground,
    required this.shadow,
    required this.outline,
  });

  factory AppColors.lightDefaults() => const AppColors(
    primary: Color(0xFFF44336),
    label: Color(0xFF181818),
    secondaryLabel: Color(0xFF414144),
    tertiaryLabel: Color(0xFF71717A),
    quaternaryLabel: Color(0xFFA1A1AA),
    background: Color(0xFFFFFFFF),
    secondaryBackground: Color(0xFFF4F4F5),
    tertiaryBackground: Color(0xFFE4E4E7),
    quaternaryBackground: Color(0xFFD4D4D8),
    shadow: Color(0xFF000000),
    outline: Color(0xFFE4E4E7),
  );

  factory AppColors.darkDefaults() => const AppColors(
    primary: Color(0xFFF44336),
    label: Color(0xFFFFFFFF),
    secondaryLabel: Color(0xFFE4E4E7),
    tertiaryLabel: Color(0xFFD4D4D8),
    quaternaryLabel: Color(0xFFC4C4C4),
    background: Color(0xFF000000),
    secondaryBackground: Color(0xFF181818),
    tertiaryBackground: Color(0xFF282828),
    quaternaryBackground: Color(0xFF383838),
    shadow: Color(0xFF000000),
    outline: Color(0xFFE4E4E7),
  );

  final Color primary;

  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color quaternaryLabel;

  final Color background;
  final Color secondaryBackground;
  final Color tertiaryBackground;
  final Color quaternaryBackground;

  final Color shadow;
  final Color outline;
}

class AppStyles extends ChangeNotifier {
  AppStyles._();
  static final _instance = AppStyles._();

  late final _text = AppTextStyles.defaults();
  AppColors _colors = AppColors.lightDefaults();

  static TextStyle get displayLarge => _instance._text.displayLarge;
  static TextStyle get displayMedium => _instance._text.displayMedium;
  static TextStyle get displaySmall => _instance._text.displaySmall;

  static TextStyle get headlineLarge => _instance._text.headlineLarge;
  static TextStyle get headlineMedium => _instance._text.headlineMedium;
  static TextStyle get headlineSmall => _instance._text.headlineSmall;

  static TextStyle get titleLarge => _instance._text.titleLarge;
  static TextStyle get titleMedium => _instance._text.titleMedium;
  static TextStyle get titleSmall => _instance._text.titleSmall;

  static TextStyle get bodyLarge => _instance._text.bodyLarge;
  static TextStyle get bodyMedium => _instance._text.bodyMedium;
  static TextStyle get bodySmall => _instance._text.bodySmall;

  static TextStyle get labelLarge => _instance._text.labelLarge;
  static TextStyle get labelMedium => _instance._text.labelMedium;
  static TextStyle get labelSmall => _instance._text.labelSmall;

  static Color get primary => _instance._colors.primary;

  static Color get label => _instance._colors.label;
  static Color get secondaryLabel => _instance._colors.secondaryLabel;
  static Color get tertiaryLabel => _instance._colors.tertiaryLabel;
  static Color get quaternaryLabel => _instance._colors.quaternaryLabel;

  static Color get background => _instance._colors.background;
  static Color get secondaryBackground => _instance._colors.secondaryBackground;
  static Color get tertiaryBackground => _instance._colors.tertiaryBackground;
  static Color get quaternaryBackground =>
      _instance._colors.quaternaryBackground;

  static Color get shadow => _instance._colors.shadow;
  static Color get outline => _instance._colors.outline;

  static void onPlatformBrightnessChanged(Brightness brightness) {
    _instance._colors = brightness == Brightness.light
        ? AppColors.lightDefaults()
        : AppColors.darkDefaults();
    _instance.notifyListeners();
  }
}
