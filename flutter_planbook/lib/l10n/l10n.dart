import 'package:flutter/widgets.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';

export 'package:flutter_planbook/l10n/gen/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
