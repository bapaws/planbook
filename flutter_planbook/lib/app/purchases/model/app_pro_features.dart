import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';

enum AppProFeatures {
  task,
  note,
  tag,
  image,
  duration,
  subTask,
  // statistics,
  // desktopWidget,
  theme,
  more;

  String getTitle(BuildContext context) => switch (this) {
    task => '🔖 ${context.l10n.task}',
    tag => '🏷️ ${context.l10n.tag}',
    note => '📝 ${context.l10n.note}',
    image => '🖼️ ${context.l10n.image}',
    duration => '⏰ ${context.l10n.duration}',
    // desktopWidget => '💻 ${context.l10n.desktopWidget}',
    theme => '🎨 ${context.l10n.theme}',
    subTask => '🔖 ${context.l10n.subtasks}',
    // statistics => '📊 ${context.l10n.statistics}',
    more => '🔥 ${context.l10n.more}',
  };

  int get basicTotal => switch (this) {
    task => 200,
    note => 200,
    tag => 3,
    _ => 0,
  };

  int? get proTotal => switch (this) {
    image => 10 * 1024 * 1024 * 1024,
    _ => null,
  };

  String getBasicText(BuildContext context) => switch (this) {
    task => '100',
    tag => '3',
    note => '200',
    // desktopWidget => context.l10n.basic,
    subTask => '✅',
    theme => context.l10n.basic,
    _ => '-',
  };

  String getProTotalText(BuildContext context) => switch (this) {
    image => '✅',
    duration => '✅',
    // desktopWidget => context.l10n.unlimited,
    theme => context.l10n.unlimited,
    // statistics => '✅',
    subTask => '✅',
    more => '✅',
    _ => '♾️',
  };
}
