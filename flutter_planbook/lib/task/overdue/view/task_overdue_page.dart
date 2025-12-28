import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_empty_task_view.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_header.dart';
import 'package:flutter_planbook/task/list/view/task_list_view.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_page.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

@RoutePage()
class TaskOverduePage extends StatelessWidget {
  const TaskOverduePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RootTaskBloc, RootTaskState>(
      buildWhen: (previous, current) =>
          previous.viewType != current.viewType ||
          previous.taskCounts != current.taskCounts ||
          previous.priorityStyle != current.priorityStyle,
      builder: (context, state) => AnimatedSwitcher(
        duration: Durations.medium1,
        child: switch (state.viewType) {
          RootTaskViewType.list =>
            state.taskCounts[TaskListMode.overdue] == 0
                ? const AppEmptyTaskView()
                : const _TaskOverdueListPage(),
          RootTaskViewType.priority => TaskPriorityPage(
            style: state.priorityStyle,
            mode: TaskListMode.overdue,
            isCompleted: state.showCompleted ? null : false,
          ),
        },
      ),
    );
  }
}

class _TaskOverdueListPage extends StatelessWidget {
  const _TaskOverdueListPage();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RootHomeBloc, RootHomeState, List<TagEntity>>(
      selector: (state) => state.topLevelTags,
      builder: (context, tags) => CustomScrollView(
        slivers: [
          _buildTaskList(context),
          for (final tag in tags) _buildTaskList(context, tag: tag),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  16 +
                  kRootBottomBarHeight +
                  MediaQuery.of(context).padding.bottom,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, {TagEntity? tag}) {
    return BlocProvider(
      key: tag != null ? ValueKey(tag.id) : const ValueKey('no-tag'),
      create: (context) =>
          TaskListBloc(
            settingsRepository: context.read(),
            tasksRepository: context.read(),
            notesRepository: context.read(),
            tag: tag,
            mode: TaskListMode.overdue,
          )..add(
            TaskListRequested(tagId: tag?.id),
          ),
      child: BlocListener<RootTaskBloc, RootTaskState>(
        listenWhen: (previous, current) =>
            previous.showCompleted != current.showCompleted,
        listener: (context, state) {
          context.read<TaskListBloc>().add(
            TaskListRequested(tagId: tag?.id),
          );
        },
        child: BlocBuilder<TaskListBloc, TaskListState>(
          builder: (context, state) => TaskListView(
            tasks: state.tasks,
            header: tag != null ? TaskListHeader(tag: tag) : null,
            onTaskDelayed: (task) {
              context.read<TaskListBloc>().add(
                TaskListTaskDelayed(task: task, delayTo: Jiffy.now()),
              );
            },
          ),
        ),
      ),
    );
  }
}
