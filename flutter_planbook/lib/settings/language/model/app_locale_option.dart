import 'package:flutter/widgets.dart';

/// 应用可选语言项
class AppLocaleOption {
  const AppLocaleOption({
    required this.locale,
    required this.nativeName,
  });

  /// `null` 表示跟随系统
  final Locale? locale;
  final String nativeName;

  static const options = <AppLocaleOption>[
    AppLocaleOption(locale: Locale('en'), nativeName: 'English'),
    AppLocaleOption(
      locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      nativeName: '简体中文',
    ),
    AppLocaleOption(
      locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      nativeName: '繁體中文',
    ),
    AppLocaleOption(locale: Locale('zh'), nativeName: '中文'),
    AppLocaleOption(locale: Locale('de'), nativeName: 'Deutsch'),
    AppLocaleOption(locale: Locale('es'), nativeName: 'Español'),
    AppLocaleOption(locale: Locale('fr'), nativeName: 'Français'),
    AppLocaleOption(locale: Locale('it'), nativeName: 'Italiano'),
    AppLocaleOption(locale: Locale('ja'), nativeName: '日本語'),
    AppLocaleOption(locale: Locale('ko'), nativeName: '한국어'),
    AppLocaleOption(locale: Locale('pt'), nativeName: 'Português'),
    AppLocaleOption(locale: Locale('ru'), nativeName: 'Русский'),
  ];

  static Locale? fromStorageKey(String? key) {
    if (key == null || key.isEmpty) return null;
    final parts = key.split('_');
    if (parts.length >= 2 && parts[0] == 'zh') {
      return Locale.fromSubtags(languageCode: 'zh', scriptCode: parts[1]);
    }
    return Locale(parts[0]);
  }

  static String? toStorageKey(Locale? locale) {
    if (locale == null) return null;
    if (locale.languageCode == 'zh' && locale.scriptCode != null) {
      return '${locale.languageCode}_${locale.scriptCode}';
    }
    return locale.languageCode;
  }

  static bool isSameLocale(Locale? a, Locale? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.languageCode == b.languageCode && a.scriptCode == b.scriptCode;
  }
}
