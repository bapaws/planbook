import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/journal/model/journal_date.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/database/note_type.dart';

class DiscoverJournalDateChangeView extends StatelessWidget {
  const DiscoverJournalDateChangeView({
    required this.date,
    required this.onDateChanged,
    super.key,
  });

  final JournalDate date;
  final ValueChanged<JournalDate> onDateChanged;

  String _title(BuildContext context) {
    final l10n = context.l10n;
    if (date.isCoverPage || date.isBackCoverPage) return '${date.year}';
    if (date.isMonthHighlightPage) {
      return NoteType.monthlyFocus.noteTitle(date.monthStart, l10n);
    }
    if (date.isMonthSummaryPage) {
      return NoteType.monthlySummary.noteTitle(date.monthStart, l10n);
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
          child: const Icon(
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
          child: const Icon(
            FontAwesomeIcons.chevronRight,
            size: 14,
          ),
        ),
      ],
    );
  }
}
