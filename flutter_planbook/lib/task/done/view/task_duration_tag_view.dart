import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';

class TaskDurationTagView extends StatelessWidget {
  const TaskDurationTagView({
    required this.startAt,
    required this.endAt,
    required this.isAllDay,
    this.colorScheme,
    super.key,
  });

  final Jiffy? startAt;
  final Jiffy? endAt;
  final bool isAllDay;
  final ColorScheme? colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colorScheme?.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FontAwesomeIcons.solidClock,
            size: 12,
            color: colorScheme?.tertiary,
          ),
          const SizedBox(width: 4),
          Text(
            isAllDay
                ? context.l10n.allDay
                : '${startAt!.toLocal().jm} - ${endAt!.toLocal().jm}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme?.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}
