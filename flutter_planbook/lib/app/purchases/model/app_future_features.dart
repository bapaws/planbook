import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_repository/planbook_repository.dart';

// enum AppFutureFeatures {
//   customTemplate,
//   customTab,
//   desktopWidget,
//   statistics,
//   searchAndFilter,
//   more;

//   String getTitle(BuildContext context) => switch (this) {
//         desktopWidget => '📱 ${context.l10n.desktopWidget}',
//         customTab => '🗓️ ${context.l10n.customTab}',
//         customTemplate => '📋 ${context.l10n.customTemplate}',
//         statistics => '📊 ${context.l10n.statistics}',
//         searchAndFilter => '🔍 ${context.l10n.searchAndFilter}',
//         more => '🔥 ${context.l10n.more}',
//       };

//   String getReleaseDate() => switch (this) {
//         desktopWidget => Jiffy.parseFromList([2025, 5]).yMMM,
//         customTab => Jiffy.parseFromList([2025, 4]).yMMM,
//         customTemplate => Jiffy.parseFromList([2025, 3]).yMMM,
//         statistics => Jiffy.parseFromList([2025, 7]).yMMM,
//         searchAndFilter => Jiffy.parseFromList([2025, 9]).yMMM,
//         more => '...',
//       };

//   String getYearlyPrice(BuildContext context) => switch (this) {
//         customTemplate => '¥38',
//         customTab => '¥48',
//         desktopWidget => '¥58',
//         statistics => '¥68',
//         searchAndFilter => '¥68',
//         more => '...',
//       };

//   String getLifetimePrice(BuildContext context) => switch (this) {
//         desktopWidget => '¥68',
//         customTab => '¥88',
//         customTemplate => '¥98',
//         statistics => '¥128',
//         searchAndFilter => '❎',
//         more => '❎',
//       };
// }

enum AppFutureFeatures {
  subtask,
  statistics,
  desktopWidget,

  more;

  String getTitle(BuildContext context) => switch (this) {
    desktopWidget => '💻 ${context.l10n.desktopWidget}',

    subtask => '🔖 ${context.l10n.subtask}',
    statistics => '📊 ${context.l10n.statistics}',
    more => '🔥 ${context.l10n.more}',
  };

  int get basicTotal => switch (this) {
    _ => 0,
  };

  int? get proTotal => switch (this) {
    _ => null,
  };

  String get releaseDate => switch (this) {
    subtask => Jiffy.parseFromList([2026, 1]).yMMM,
    statistics => Jiffy.parseFromList([2026, 2]).yMMM,
    desktopWidget => Jiffy.parseFromList([2026, 3]).yMMM,
    more => '...',
  };

  String getBasicText(BuildContext context) => switch (this) {
    desktopWidget => context.l10n.basic,
    _ => '-',
  };

  String getProTotalText(BuildContext context) => switch (this) {
    desktopWidget => context.l10n.unlimited,
    statistics => '✅',
    subtask => '✅',
    more => '✅',
  };
}
