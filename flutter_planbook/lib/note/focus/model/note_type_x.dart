import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:planbook_api/database/note_type.dart';

extension NoteTypeX on NoteType {
  String getTitle(AppLocalizations l10n) {
    return switch (this) {
      NoteType.dailyFocus => l10n.dailyFocus,
      NoteType.weeklyFocus => l10n.weeklyFocus,
      NoteType.journal => l10n.note,
    };
  }

  String getHintText(AppLocalizations l10n) {
    return switch (this) {
      NoteType.dailyFocus => l10n.thinkAboutDailyFocus,
      NoteType.weeklyFocus => l10n.thinkAboutWeeklyFocus,
      NoteType.journal => l10n.noteTitleHint,
    };
  }
}
