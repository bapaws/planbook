import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_delete_dialog.dart';
import 'package:planbook_repository/planbook_repository.dart';

/// 监听 TaskListBloc 的删除状态并展示对应弹窗
class TaskListDeleteDialogListener extends StatelessWidget {
  const TaskListDeleteDialogListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskListBloc, TaskListState>(
      listenWhen: (previous, current) =>
          previous.showDeleteModeSelection != current.showDeleteModeSelection ||
          previous.showDeleteConfirmation != current.showDeleteConfirmation,
      listener: _onDeleteStateChanged,
      child: child,
    );
  }

  Future<void> _onDeleteStateChanged(
    BuildContext context,
    TaskListState state,
  ) async {
    if (state.showDeleteModeSelection) {
      final task = state.pendingDeleteTask;
      final hasOccurrence = task?.occurrence?.occurrenceAt != null;
      final mode = await showDeleteModeSelectionDialog(
        context,
        hasOccurrence: hasOccurrence,
      );
      if (context.mounted) {
        context.read<TaskListBloc>().add(
          TaskListDeleteConfirmed(mode: mode),
        );
      }
    } else if (state.showDeleteConfirmation) {
      final confirmed = await showDeleteConfirmationDialog(context);
      if (context.mounted) {
        context.read<TaskListBloc>().add(
          TaskListDeleteConfirmed(
            mode: confirmed ? RecurringTaskDeleteMode.allEvents : null,
          ),
        );
      }
    }
  }
}
