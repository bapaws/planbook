import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/week/view/task_week_header.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/database.dart';
import 'package:planbook_api/database/note_type.dart';

class TaskFocusCell extends StatelessWidget {
  const TaskFocusCell({required this.note, super.key});

  final Note? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: theme.colorScheme.surface,
        onPressed: () {
          context.router.push(
            NoteFocusRoute(
              initialNote: note,
              type: NoteType.weeklyFocus,
              focusAt: note?.focusAt ?? Jiffy.now(),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskWeekHeader(
              title: '${context.l10n.weeklyFocus} 🎯',
              colorScheme: theme.colorScheme,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Text(
                    note?.title ?? context.l10n.thinkAboutWeeklyFocus,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: note == null
                          ? theme.colorScheme.outlineVariant
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
