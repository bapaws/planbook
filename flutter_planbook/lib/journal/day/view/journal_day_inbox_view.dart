import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_view.dart';
import 'package:jiffy/jiffy.dart';

class JournalDayInboxView extends StatelessWidget {
  const JournalDayInboxView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskListBloc(
        tasksRepository: context.read(),
        notesRepository: context.read(),
      )..add(TaskListRequested(date: Jiffy.now(), isCompleted: true)),
      child: BlocBuilder<TaskListBloc, TaskListState>(
        builder: (context, state) => CustomScrollView(
          slivers: [TaskListView(tasks: state.tasks)],
        ),
      ),
    );
  }
}
