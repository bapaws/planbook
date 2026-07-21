import 'package:flutter/cupertino.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_repository/planbook_repository.dart';

/// 显示重复任务删除模式选择弹窗
///
/// [hasOccurrence] 为 false 时（无 occurrence 上下文）只展示"所有事件 / 取消"
Future<RecurringTaskDeleteMode?> showDeleteModeSelectionDialog(
  BuildContext context, {
  required bool hasOccurrence,
}) async {
  return showCupertinoDialog<RecurringTaskDeleteMode>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(context.l10n.deleteModeSelection),
      actions: [
        if (hasOccurrence)
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(
              context,
              RecurringTaskDeleteMode.thisEventOnly,
            ),
            child: Text(context.l10n.thisEventOnly),
          ),
        if (hasOccurrence)
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(
              context,
              RecurringTaskDeleteMode.thisAndFutureEvents,
            ),
            child: Text(context.l10n.thisAndFutureEvents),
          ),
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(
            context,
            RecurringTaskDeleteMode.allEvents,
          ),
          child: Text(context.l10n.allEvents),
        ),
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
      ],
    ),
  );
}

/// 显示普通任务删除确认弹窗
Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(context.l10n.deleteTaskAlertTitle),
      content: Text(context.l10n.deleteTaskAlertContent),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.l10n.delete),
        ),
      ],
    ),
  );
  return result ?? false;
}
