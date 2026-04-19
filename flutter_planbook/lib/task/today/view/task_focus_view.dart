import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/today/view/task_focus_header_view.dart';
import 'package:planbook_api/database/database.dart';
import 'package:planbook_api/database/note_type.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_core/planbook_core.dart';

class TaskFocusView extends StatelessWidget {
  const TaskFocusView({
    required this.note,
    required this.noteType,
    required this.onTap,
    required this.onMindMapTapped,
    this.onTaskDropped,
    super.key,
  });

  final Note? note;

  final NoteType noteType;
  final VoidCallback onTap;
  final VoidCallback onMindMapTapped;

  /// 拖入任务时回调，将任务标题追加到笔记内容（已完成 ✅ / 未完成 ❌）
  final ValueChanged<TaskEntity>? onTaskDropped;

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
    final isEmpty = note?.content == null || note!.content!.isEmpty;
    final emptyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.outlineVariant,
    );
    final filledStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
    );
    final content = GestureDetector(
      key: ValueKey(noteType),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
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
            const SizedBox(height: 8, width: double.infinity),
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
                child: isEmpty
                    ? onTaskDropped != null
                        ? SequentialRotatingText(
                            key: ValueKey(noteType),
                            messages: [
                              noteType.getHintText(context.l10n),
                              context.l10n.taskFocusEmptyDragTaskHint,
                            ],
                            style: emptyStyle,
                          )
                        : Text(
                            noteType.getHintText(context.l10n),
                            style: emptyStyle,
                          )
                    : Text(
                        note!.content!,
                        style: filledStyle,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
    if (onTaskDropped == null) return content;
    return DragTarget<TaskEntity>(
      onAcceptWithDetails: (details) => onTaskDropped!(details.data),
      builder: (context, candidateData, rejectedData) => content,
    );
  }
}
