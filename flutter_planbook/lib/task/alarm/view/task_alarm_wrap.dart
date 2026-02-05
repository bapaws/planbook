import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

class TaskAlarmWrap extends StatelessWidget {
  const TaskAlarmWrap({required this.alarms, this.onAlarmsChanged, super.key});

  final List<EventAlarm> alarms;
  final ValueChanged<List<EventAlarm>>? onAlarmsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (int index = 0; index < alarms.length; index++)
          CupertinoButton.tinted(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            minimumSize: Size.zero,
            borderRadius: BorderRadius.circular(8),
            onPressed: () {
              final newAlarms = List<EventAlarm>.from(alarms)..removeAt(index);
              onAlarmsChanged?.call(newAlarms);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getAlarmText(context, alarms[index]),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  FontAwesomeIcons.solidCircleXmark,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
      ].animate().fade(duration: 300.ms),
    );
  }

  String _getAlarmText(BuildContext context, EventAlarm alarm) {
    return switch (alarm.type) {
      AlertType.absolute => alarm.absoluteAt?.format() ?? '',
      AlertType.scheduled => _getScheduledAlarmText(context, alarm),
      _ => '',
    };
  }

  String _getScheduledAlarmText(BuildContext context, EventAlarm alarm) {
    var text = '';
    if (alarm.dayOffset == null || alarm.dayOffset == 0) {
      text += context.l10n.onTheDay;
    } else {
      text += context.l10n.dayEarly(alarm.dayOffset!);
    }
    return '$text '
        '${(alarm.hour ?? 9).toString().padLeft(2, '0')}:'
        '${(alarm.minute ?? 0).toString().padLeft(2, '0')}';
  }
}
