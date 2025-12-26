import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:sliver_tools/sliver_tools.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({
    required this.tasks,
    this.onTaskPressed,
    this.onTaskCompleted,
    this.onTaskDeleted,
    this.onTaskEdited,
    this.header,
    this.onTaskDelayed,
    super.key,
  });

  final Widget? header;
  final List<TaskEntity> tasks;

  final ValueChanged<TaskEntity>? onTaskPressed;
  final ValueChanged<TaskEntity>? onTaskCompleted;
  final ValueChanged<TaskEntity>? onTaskDeleted;
  final ValueChanged<TaskEntity>? onTaskEdited;

  final ValueChanged<TaskEntity>? onTaskDelayed;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TaskListBloc, TaskListState>(
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
        ),
        BlocListener<TaskListBloc, TaskListState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == PageStatus.loading) {
              EasyLoading.show();
            } else if (EasyLoading.isShow) {
              EasyLoading.dismiss();
            }
          },
        ),
      ],
      child: TaskSliverList(
        tasks: tasks,
        header: header,
        onTaskPressed: onTaskPressed,
        onTaskCompleted: onTaskCompleted,
        onTaskDeleted: onTaskDeleted,
        onTaskEdited: onTaskEdited,
        onTaskDelayed: onTaskDelayed,
      ),
    );
  }
}

class TaskSliverList extends StatelessWidget {
  const TaskSliverList({
    required this.tasks,
    this.header,
    this.onTaskPressed,
    this.onTaskCompleted,
    this.onTaskDeleted,
    this.onTaskEdited,
    this.onTaskDelayed,
    super.key,
  });

  final Widget? header;
  final List<TaskEntity> tasks;

  final ValueChanged<TaskEntity>? onTaskPressed;
  final ValueChanged<TaskEntity>? onTaskCompleted;
  final ValueChanged<TaskEntity>? onTaskDeleted;
  final ValueChanged<TaskEntity>? onTaskEdited;
  final ValueChanged<TaskEntity>? onTaskDelayed;

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      pushPinnedChildren: true,
      children: [
        if (header != null && tasks.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(child: header),
          ),
        SliverAnimatedPaintExtent(
          duration: Durations.medium1,
          child: SliverList.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final nextTask = index < tasks.length - 1
                  ? tasks[index + 1]
                  : null;
              return TaskListTile(
                key: ValueKey(task),
                task: task,
                titleTextStyle: Theme.of(context).textTheme.titleMedium,
                isExpanded: nextTask?.parentId == task.id,
                onPressed: (task) {
                  if (onTaskPressed != null) {
                    onTaskPressed!(task);
                  } else {
                    context.router.push(TaskDetailRoute(taskId: task.id));
                  }
                },
                onCompleted: (task) {
                  if (onTaskCompleted != null) {
                    onTaskCompleted!(task);
                  } else {
                    context.read<TaskListBloc>().add(
                      TaskListCompleted(task: task),
                    );
                  }
                },
                onDeleted: (task) {
                  if (onTaskDeleted != null) {
                    onTaskDeleted!(task);
                  } else {
                    context.read<TaskListBloc>().add(
                      TaskListDeleted(taskId: task.id),
                    );
                  }
                },
                onEdited: (task) {
                  context.router.push(TaskNewRoute(initialTask: task));
                },
                onDelayed: (task) {
                  if (onTaskDelayed != null) {
                    onTaskDelayed!(task);
                  } else {
                    context.read<TaskListBloc>().add(
                      TaskListTaskDelayed(task: task),
                    );
                  }
                },
                onExpanded: (task) {
                  context.read<TaskListBloc>().add(
                    TaskListTaskExpanded(task: task),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
