import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:flutter_planbook/task/list/view/task_drag_operation.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/database.dart';
import 'package:planbook_api/database/note_type.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_core/planbook_core.dart';

/// 八宫格第一格的笔记正文（本周重点 / 本周总结）。
class TaskWeekFocusCell extends StatelessWidget {
  const TaskWeekFocusCell({
    required this.note,
    required this.noteType,
    this.onTaskDropped,
    super.key,
  });

  final Note? note;
  final NoteType noteType;
  final ValueChanged<TaskEntity>? onTaskDropped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = note?.content == null || note!.content!.isEmpty;
    final emptyStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.outlineVariant,
    );
    final filledStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
    );
    final child = ColoredBox(
      color: theme.colorScheme.surface,
      child: GestureDetector(
        onTap: () {
          context.router.push(
            NoteNewTypeRoute(
              initialNote: note,
              type: noteType,
              focusAt: note?.focusAt ?? Jiffy.now(),
            ),
          );
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
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
      ),
    );

    return TaskDragTarget(
      onAccept: onTaskDropped,
      operation: TaskDragOperation.noteAppend,
      child: SizedBox.expand(child: child),
    );
  }
}
