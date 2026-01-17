import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:planbook_api/database/note_type.dart';

extension NoteTypeX on NoteType {
  String getTitle(AppLocalizations l10n) {
    return switch (this) {
      NoteType.dailyFocus => l10n.dailyFocus,
      NoteType.dailySummary => l10n.dailySummary,
      NoteType.weeklyFocus => l10n.weeklyFocus,
      NoteType.weeklySummary => l10n.weeklySummary,
      NoteType.monthlyFocus => l10n.monthlyFocus,
      NoteType.monthlySummary => l10n.monthlySummary,
      NoteType.yearlyFocus => l10n.yearlyFocus,
      NoteType.yearlySummary => l10n.yearlySummary,
      NoteType.journal => l10n.note,
    };
  }

  String getHintText(AppLocalizations l10n) {
    return switch (this) {
      NoteType.dailyFocus => l10n.thinkAboutDailyFocus,
      NoteType.dailySummary => l10n.thinkAboutDailySummary,
      NoteType.weeklyFocus => l10n.thinkAboutWeeklyFocus,
      NoteType.weeklySummary => l10n.thinkAboutWeeklySummary,
      NoteType.monthlyFocus => l10n.thinkAboutMonthlyFocus,
      NoteType.monthlySummary => l10n.thinkAboutMonthlySummary,
      NoteType.yearlyFocus => l10n.thinkAboutYearlyFocus,
      NoteType.yearlySummary => l10n.thinkAboutYearlySummary,
      NoteType.journal => l10n.noteTitleHint,
    };
  }

  ColorScheme getColorScheme(BuildContext context) {
    return switch (this) {
      NoteType.yearlyFocus || NoteType.yearlySummary => context.redColorScheme,
      NoteType.monthlyFocus ||
      NoteType.monthlySummary => context.blueColorScheme,
      NoteType.weeklyFocus ||
      NoteType.weeklySummary => context.amberColorScheme,
      NoteType.dailyFocus || NoteType.dailySummary => context.greenColorScheme,
      _ => context.greyColorScheme,
    };
  }
}
