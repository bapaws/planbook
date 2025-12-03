import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

class JournalDayDateView extends StatelessWidget {
  const JournalDayDateView({required this.date, super.key});

  final Jiffy date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // AppIcon(
        //   FontAwesomeIcons.calendar,
        //   backgroundColor: theme.colorScheme.primaryContainer,
        //   foregroundColor: theme.colorScheme.primary,
        // ),
        // const SizedBox(width: 8),
        // Text(context.l10n.date, style: theme.textTheme.titleMedium),
        // const Spacer(),
        Text(
          date.date.toString(),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date.MMM,
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              date.EEEE,
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
