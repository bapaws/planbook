import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/task/detail/bloc/task_detail_bloc.dart';
import 'package:planbook_api/entity/task_entity.dart';

class TaskDetailHeader extends StatelessWidget {
  const TaskDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocSelector<TaskDetailBloc, TaskDetailState, TaskEntity?>(
      selector: (state) => state.task,
      builder: (context, task) {
        if (task == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Text(
                task.title,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ],
        );
      },
    );
  }
}
