import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:planbook_repository/planbook_repository.dart';

/// 动画退场或同一帧日期变化后，旧卡片不能打开旧笔记。
void openPeriodNoteEditor(
  BuildContext context, {
  required PeriodNoteSnapshot displayed,
  required PeriodNoteSnapshot Function() current,
}) {
  if (!context.mounted) return;
  final latest = current();
  if (!latest.canWrite || latest.target != displayed.target) {
    return;
  }
  if (latest.note != null &&
      latest.note!.userId != context.read<NotesRepository>().userId) {
    return;
  }
  context.router.push(
    NoteNewTypeRoute(
      initialNote: latest.note,
      type: latest.target.type,
      focusAt: latest.target.focusAt,
    ),
  );
}
