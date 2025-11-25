import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/task_entity.dart';

extension TaskListModeX on TaskListMode {
  IconData get icon {
    return switch (this) {
      TaskListMode.inbox => FontAwesomeIcons.inbox,
      TaskListMode.today => FontAwesomeIcons.calendar,
      TaskListMode.overdue => FontAwesomeIcons.clock,
      TaskListMode.tag => FontAwesomeIcons.hashtag,
    };
  }

  Color get color {
    return switch (this) {
      TaskListMode.inbox => Colors.blue,
      TaskListMode.today => Colors.green,
      TaskListMode.overdue => Colors.red,
      TaskListMode.tag => Colors.orange,
    };
  }

  String getName(BuildContext context) {
    return switch (this) {
      TaskListMode.inbox => context.l10n.inbox,
      TaskListMode.today => context.l10n.today,
      TaskListMode.overdue => context.l10n.overdue,
      TaskListMode.tag => context.l10n.tag,
    };
  }
}
