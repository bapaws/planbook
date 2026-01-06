import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:planbook_api/database/database.dart';
import 'package:planbook_api/database/note_type.dart';

class JournalDayFocusView extends StatelessWidget {
  const JournalDayFocusView({
    required this.note,
    required this.noteType,
    super.key,
  });

  final Note? note;
  final NoteType noteType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.surfaceContainer,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
            ),
            height: 21,
            decoration: BoxDecoration(
              color: noteType.isFocus
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${context.l10n.dailyFocus} 🎯',
              style: noteType.isFocus
                  ? theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    )
                  : theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
            ),
          ),
          const SizedBox(
            height: 8,
            width: double.infinity,
          ),
          AnimatedSwitcher(
            duration: Durations.medium1,
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            ),
            child: Text(
              note?.content?.replaceAll('\n', ' ') ??
                  noteType.getHintText(context.l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: note == null
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
