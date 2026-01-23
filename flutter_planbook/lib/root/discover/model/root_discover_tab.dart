import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum RootDiscoverTab {
  journal,
  focusMindMap,
  summaryMindMap;

  IconData get icon {
    return switch (this) {
      RootDiscoverTab.journal => FontAwesomeIcons.bookOpen,
      RootDiscoverTab.focusMindMap => FontAwesomeIcons.snowflake,
      RootDiscoverTab.summaryMindMap => FontAwesomeIcons.snowflake,
    };
  }

  Color get color {
    return switch (this) {
      RootDiscoverTab.journal => Colors.blue,
      RootDiscoverTab.focusMindMap => Colors.red,
      RootDiscoverTab.summaryMindMap => Colors.green,
    };
  }

  String getName(BuildContext context) {
    return switch (this) {
      RootDiscoverTab.journal => context.l10n.planbook,
      RootDiscoverTab.focusMindMap => context.l10n.focusMindMap,
      RootDiscoverTab.summaryMindMap => context.l10n.summaryMindMap,
    };
  }
}
