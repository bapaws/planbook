import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/core/model/task_priority.dart';
import 'package:flutter_planbook/journal/priority/bloc/journal_priority_bloc.dart';
import 'package:flutter_planbook/journal/priority/view/journal_priority_list_tile.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_flag_header.dart';
import 'package:planbook_repository/planbook_repository.dart';

class JournalPriorityListView extends StatelessWidget {
  const JournalPriorityListView({
    required this.priority,
    super.key,
  });

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final colorScheme = priority.getColorScheme(context);
    return BlocSelector<
      JournalPriorityBloc,
      JournalPriorityState,
      List<TaskEntity>
    >(
      selector: (state) => state.tasks[priority] ?? [],
      builder: (context, tasks) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskPriorityFlagHeader(
              priority: priority,
              colorScheme: colorScheme,
            ),
            for (final task in tasks)
              JournalPriorityListTile(
                key: ValueKey(task.id),
                task: task,
              ),
          ],
        );
      },
    );
  }
}
