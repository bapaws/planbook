import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/settings/task_priority_style.dart';

extension TaskPriorityStyleX on TaskPriorityStyle {
  String getTitle(BuildContext context) => switch (this) {
    TaskPriorityStyle.solidColorBackground => context.l10n.solidColorBackground,
    TaskPriorityStyle.numberIcon => context.l10n.numberIcon,
  };

  IconData getIcon() => switch (this) {
    TaskPriorityStyle.solidColorBackground => FontAwesomeIcons.solidSquare,
    TaskPriorityStyle.numberIcon => FontAwesomeIcons.hashtag,
  };
}
