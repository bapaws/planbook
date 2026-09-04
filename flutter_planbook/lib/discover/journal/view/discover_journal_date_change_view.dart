import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/journal/model/journal_date.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DiscoverJournalDateChangeView extends StatelessWidget {
  const DiscoverJournalDateChangeView({
    required this.date,
    required this.onDateChanged,
    super.key,
  });

  final JournalDate date;
  final ValueChanged<JournalDate> onDateChanged;

  String _title(BuildContext context) {
    if (date.isCoverPage || date.isBackCoverPage) return '${date.year}';
    if (date.isMonthHighlightPage) {
      return date.date.toLocal().MMM;
    }
    if (date.isMonthSummaryPage) {
      return date.date.toLocal().MMM;
    }
    return date.date.toLocal().MMMd;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CupertinoButton(
          minimumSize: const Size.square(kMinInteractiveDimension),
          onPressed: date.isCoverPage
              ? null
              : () {
                  if (date.isCoverPage) return;
                  onDateChanged(date.previous);
                },
          child: const FaIcon(
            FontAwesomeIcons.chevronLeft,
            size: 14,
          ),
        ),
        Text(
          _title(context),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        CupertinoButton(
          minimumSize: const Size.square(kMinInteractiveDimension),
          onPressed: date.isBackCoverPage
              ? null
              : () {
                  if (date.isBackCoverPage) return;
                  onDateChanged(date.next);
                },
          child: const FaIcon(
            FontAwesomeIcons.chevronRight,
            size: 14,
          ),
        ),
      ],
    );
  }
}
