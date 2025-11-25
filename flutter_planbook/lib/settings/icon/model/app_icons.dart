import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';

enum AppIcons {
  yellow,
  green,
  blue,
  red,
  teal,
  indigo,
  pink,
  purple,
  orange;

  factory AppIcons.fromName(String name) {
    return AppIcons.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppIcons.yellow,
    );
  }

  Color get color => switch (this) {
        AppIcons.yellow => Colors.yellow,
        AppIcons.green => Colors.green,
        AppIcons.blue => Colors.blue,
        AppIcons.red => Colors.red,
        AppIcons.pink => Colors.pink,
        AppIcons.purple => Colors.purple,
        AppIcons.orange => Colors.orange,
        AppIcons.teal => Colors.teal,
        AppIcons.indigo => Colors.indigo,
      };

  String getName(BuildContext context) => switch (this) {
        AppIcons.yellow => context.l10n.yellow,
        AppIcons.green => context.l10n.green,
        AppIcons.blue => context.l10n.blue,
        AppIcons.red => context.l10n.red,
        AppIcons.pink => context.l10n.pink,
        AppIcons.purple => context.l10n.purple,
        AppIcons.orange => context.l10n.orange,
        AppIcons.teal => context.l10n.teal,
        AppIcons.indigo => context.l10n.indigo,
      };

  String get iconName =>
      'Logo-${name.substring(0, 1).toUpperCase()}${name.substring(1)}';
}
