import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/note_type.dart';

extension NoteTypeX on NoteType {
  /// 按笔记类型将 [focusAt] 规范为存储用的基准时间
  /// （日→当天 0 点，周→当周周一 0 点，月→当月 1 号 0 点，年→当年 1 月 1 日 0 点）
  Jiffy normalizedFocusAt(Jiffy focusAt) {
    return switch (this) {
      NoteType.dailyFocus || NoteType.dailySummary =>
        focusAt.startOf(Unit.day),
      NoteType.weeklyFocus || NoteType.weeklySummary => focusAt
          .subtract(days: focusAt.dateTime.weekday - 1)
          .startOf(Unit.day),
      NoteType.monthlyFocus || NoteType.monthlySummary =>
        focusAt.startOf(Unit.month),
      NoteType.yearlyFocus || NoteType.yearlySummary =>
        focusAt.startOf(Unit.year),
      NoteType.journal => throw UnimplementedError(),
    };
  }

  /// 根据 [focusAt] 和 [l10n] 生成该类型笔记的标准标题（用于创建/更新）
  String noteTitle(Jiffy focusAt, AppLocalizations l10n) {
    final normalized = normalizedFocusAt(focusAt);
    return switch (this) {
      NoteType.dailyFocus => l10n.dailyFocusTitle(focusAt.dateTime),
      NoteType.dailySummary => l10n.dailySummaryTitle(focusAt.dateTime),
      NoteType.weeklyFocus =>
        l10n.weeklyFocusTitle(normalized.weekOfYear),
      NoteType.weeklySummary =>
        l10n.weeklySummaryTitle(normalized.weekOfYear),
      NoteType.monthlyFocus => l10n.monthlyFocusTitle(normalized.yMMM),
      NoteType.monthlySummary => l10n.monthlySummaryTitle(normalized.yMMM),
      NoteType.yearlyFocus =>
        l10n.yearlyFocusTitle(normalized.format(pattern: 'y')),
      NoteType.yearlySummary =>
        l10n.yearlySummaryTitle(normalized.format(pattern: 'y')),
      NoteType.journal => throw UnimplementedError(),
    };
  }

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
