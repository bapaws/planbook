import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:planbook_api/database/task_priority.dart';

extension TaskPriorityX on TaskPriority {
  ColorScheme getColorScheme(BuildContext context) => switch (this) {
    TaskPriority.high => context.redColorScheme,
    TaskPriority.medium => context.blueColorScheme,
    TaskPriority.low => context.amberColorScheme,
    TaskPriority.none => context.greenColorScheme,
  };
}
