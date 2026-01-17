import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

const kJournalDailyDateViewHeight = 48.0;

class JournalDailyDateView extends StatelessWidget {
  const JournalDailyDateView({required this.date, super.key});

  final Jiffy date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          date.date.toString().padLeft(2, '0'),
          style: theme.textTheme.headlineLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 4, height: kJournalDailyDateViewHeight),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.MMM,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              date.EEEE,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
