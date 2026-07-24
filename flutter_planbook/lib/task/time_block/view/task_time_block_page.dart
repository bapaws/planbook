import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_bloc_provider.dart';
import 'package:flutter_planbook/task/time_block/bloc/task_time_block_bloc.dart';
import 'package:flutter_planbook/task/time_block/view/task_time_block_view.dart';
import 'package:jiffy/jiffy.dart';

class TaskTimeBlockPage extends StatelessWidget {
  const TaskTimeBlockPage({
    required this.date,
    super.key,
  });

  final Jiffy date;

  @override
  Widget build(BuildContext context) {
    return TaskListBlocProvider(
      key: ValueKey('time-block-$date'),
      requestEvent: () => TaskListDayAllRequested(date: date),
      child: BlocProvider(
        create: (context) {
          final tasks = context.read<TaskListBloc>().state.tasks;
          return TaskTimeBlockBloc(date: date)
            ..add(const TaskTimeBlockStarted())
            ..add(TaskTimeBlockTasksUpdated(tasks));
        },
        child: BlocListener<TaskListBloc, TaskListState>(
          listenWhen: (previous, current) => previous.tasks != current.tasks,
          listener: (context, state) {
            context.read<TaskTimeBlockBloc>().add(
              TaskTimeBlockTasksUpdated(state.tasks),
            );
          },
          child: const TaskTimeBlockView(),
        ),
      ),
    );
  }
}
