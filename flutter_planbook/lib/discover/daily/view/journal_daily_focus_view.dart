import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_header.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/database/database.dart';
import 'package:planbook_api/database/note_type.dart';

class JournalDailyFocusView extends StatelessWidget {
  const JournalDailyFocusView({
    required this.note,
    required this.noteType,
    required this.colorScheme,
    super.key,
  });

  final Note? note;
  final NoteType noteType;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        JournalDailyHeader(
          title: noteType.getTitle(context.l10n),
          icon: Icon(
            FontAwesomeIcons.arrowsToDot,
            size: 14,
            color: colorScheme.primary,
          ),
          iconColor: colorScheme.onPrimaryContainer,
          iconBackgroundColor: colorScheme.primaryContainer,
          badgeColor: colorScheme.primaryContainer,
          badgeTextColor: colorScheme.onPrimaryContainer,
        ),
        const SizedBox(height: 12),
        Text(
          note?.content?.replaceAll('\n', ' ') ??
              noteType.getHintText(context.l10n),
          style: theme.textTheme.bodySmall?.copyWith(
            color: note == null
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
