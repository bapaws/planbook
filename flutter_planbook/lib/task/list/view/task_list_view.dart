import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:sliver_tools/sliver_tools.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({
    required this.tasks,
    this.onTaskPressed,
    this.onTaskCompleted,
    this.onTaskDeleted,
    this.onTaskEdited,
    this.header,
    super.key,
  });

  final Widget? header;
  final List<TaskEntity> tasks;

  final ValueChanged<TaskEntity>? onTaskPressed;
  final ValueChanged<TaskEntity>? onTaskCompleted;
  final ValueChanged<TaskEntity>? onTaskDeleted;
  final ValueChanged<TaskEntity>? onTaskEdited;

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskListBloc, TaskListState>(
      listenWhen: (previous, current) =>
          previous.currentTaskNote != current.currentTaskNote &&
          current.currentTaskNote != null,
      listener: (context, state) {
        context.router.push(
          NoteNewRoute(
            initialNote: state.currentTaskNote,
          ),
        );
      },
      child: MultiSliver(
        pushPinnedChildren: true,
        children: [
          if (header != null && tasks.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(child: header),
            ),
          SliverList.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskListTile(
                key: ValueKey(task.occurrence?.id ?? task.id),
                task: task,
                onPressed: () {
                  if (onTaskPressed != null) {
                    onTaskPressed!(task);
                  } else {
                    context.router.push(TaskDetailRoute(taskId: task.id));
                  }
                },
                onCompleted: () {
                  if (onTaskCompleted != null) {
                    onTaskCompleted!(task);
                  } else {
                    context.read<TaskListBloc>().add(
                      TaskListCompleted(task: task),
                    );
                  }
                },
                onDeleted: () {
                  if (onTaskDeleted != null) {
                    onTaskDeleted!(task);
                  } else {
                    context.read<TaskListBloc>().add(
                      TaskListDeleted(taskId: task.id),
                    );
                  }
                },
                onEdited: () {
                  context.router.push(TaskNewRoute(initialTask: task));
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
