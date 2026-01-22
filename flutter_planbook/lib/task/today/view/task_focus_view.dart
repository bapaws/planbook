import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/today/view/task_focus_header_view.dart';
import 'package:planbook_api/database/database.dart';
import 'package:planbook_api/database/note_type.dart';

class TaskFocusView extends StatelessWidget {
  const TaskFocusView({
    required this.note,
    required this.noteType,
    required this.onTap,
    required this.onMindMapTapped,
    super.key,
  });

  final Note? note;

  final NoteType noteType;
  final VoidCallback onTap;
  final VoidCallback onMindMapTapped;

  RootTaskTab get tab => switch (noteType) {
    NoteType.dailyFocus => RootTaskTab.day,
    NoteType.dailySummary => RootTaskTab.day,
    NoteType.weeklyFocus => RootTaskTab.week,
    NoteType.weeklySummary => RootTaskTab.week,
    NoteType.monthlyFocus => RootTaskTab.month,
    NoteType.monthlySummary => RootTaskTab.month,
    // NoteType.yearlyFocus => RootTaskTab.year,
    _ => throw UnimplementedError(),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      key: ValueKey(noteType),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(
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
            TaskFocusHeaderView(
              noteType: noteType,
              tab: tab,
              onMindMapTapped: onMindMapTapped,
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
              child: Padding(
                key: ValueKey(noteType),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  note?.content ?? noteType.getHintText(context.l10n),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: note == null
                        ? theme.colorScheme.outlineVariant
                        : theme.colorScheme.primary,
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
