import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:planbook_api/database/recurrence_rule.dart';

extension RecurrenceFrequencyX on RecurrenceFrequency {
  String getEveryUnitName(AppLocalizations l10n) => switch (this) {
    RecurrenceFrequency.daily => l10n.everyDay,
    RecurrenceFrequency.weekly => l10n.everyWeek,
    RecurrenceFrequency.monthly => l10n.everyMonth,
    RecurrenceFrequency.yearly => l10n.everyYear,
  };
}
