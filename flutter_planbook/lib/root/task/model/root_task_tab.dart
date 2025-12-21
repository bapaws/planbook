import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/task_entity.dart';

enum RootTaskTab {
  inbox,
  overdue,
  day,
  week,
  tag;

  TaskListMode? get mode => switch (this) {
    inbox => TaskListMode.inbox,
    overdue => TaskListMode.overdue,
    day => TaskListMode.today,
    _ => null,
  };

  IconData get icon {
    return switch (this) {
      RootTaskTab.inbox => FontAwesomeIcons.inbox,
      RootTaskTab.day => FontAwesomeIcons.calendar,
      RootTaskTab.overdue => FontAwesomeIcons.clock,
      RootTaskTab.week => FontAwesomeIcons.calendarWeek,
      RootTaskTab.tag => FontAwesomeIcons.hashtag,
    };
  }

  Color get color {
    return switch (this) {
      RootTaskTab.inbox => Colors.blue,
      RootTaskTab.day => Colors.green,
      RootTaskTab.overdue => Colors.red,
      RootTaskTab.week => Colors.orange,
      RootTaskTab.tag => Colors.purple,
    };
  }

  String getName(BuildContext context) {
    return switch (this) {
      RootTaskTab.inbox => context.l10n.inbox,
      RootTaskTab.day => context.l10n.today,
      RootTaskTab.overdue => context.l10n.overdue,
      RootTaskTab.week => context.l10n.thisWeek,
      _ => throw UnimplementedError(),
    };
  }
}
