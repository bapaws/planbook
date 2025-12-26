import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_api/database/task_priority.dart';

extension TaskPriorityX on TaskPriority {
  ColorScheme getColorScheme(BuildContext context) => switch (this) {
    TaskPriority.high => context.redColorScheme,
    TaskPriority.medium => context.blueColorScheme,
    TaskPriority.low => context.amberColorScheme,
    TaskPriority.none => context.greenColorScheme,
  };

  String getTitle(AppLocalizations l10n) => switch (this) {
    TaskPriority.high => l10n.importantUrgent,
    TaskPriority.medium => l10n.importantNotUrgent,
    TaskPriority.low => l10n.urgentUnimportant,
    TaskPriority.none => l10n.notUrgentUnimportant,
  };
}
