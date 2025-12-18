import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_empty_task_view.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/inbox/bloc/task_inbox_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_header.dart';
import 'package:flutter_planbook/task/list/view/task_list_view.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_page.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class TaskInboxPage extends StatelessWidget {
  const TaskInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TaskInboxBloc(
            tasksRepository: context.read(),
          )..add(
            TaskInboxRequested(
              isCompleted: context.read<RootTaskBloc>().isCompleted,
            ),
          ),
      child: BlocListener<RootTaskBloc, RootTaskState>(
        listenWhen: (previous, current) =>
            previous.showCompleted != current.showCompleted,
        listener: (context, state) {
          context.read<TaskInboxBloc>().add(
            TaskInboxRequested(isCompleted: state.isCompleted),
          );
        },
        child: const _TaskInboxPage(),
      ),
    );
  }
}

class _TaskInboxPage extends StatelessWidget {
  const _TaskInboxPage();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TaskInboxBloc, TaskInboxState, bool>(
      selector: (state) => state.count == 0,
      builder: (context, isEmpty) => AnimatedSwitcher(
        duration: Durations.medium1,
        child: isEmpty
            ? const AppEmptyTaskView()
            : BlocBuilder<RootTaskBloc, RootTaskState>(
                buildWhen: (previous, current) =>
                    previous.viewType != current.viewType ||
                    previous.priorityStyle != current.priorityStyle,
                builder: (context, state) => switch (state.viewType) {
                  RootTaskViewType.list => const _TaskInboxListPage(),
                  RootTaskViewType.priority => TaskPriorityPage(
                    style: state.priorityStyle,
                    mode: TaskListMode.inbox,
                    isCompleted: context.read<RootTaskBloc>().isCompleted,
                  ),
                },
              ),
      ),
    );
  }
}

class _TaskInboxListPage extends StatelessWidget {
  const _TaskInboxListPage();

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
            tasksRepository: context.read(),
            settingsRepository: context.read(),
            notesRepository: context.read(),
            tag: tag,
          )..add(
            TaskListRequested(
              tagId: tag?.id,
              isCompleted: context.read<RootTaskBloc>().isCompleted,
            ),
          ),
      child: BlocListener<RootTaskBloc, RootTaskState>(
        listenWhen: (previous, current) =>
            previous.showCompleted != current.showCompleted,
        listener: (context, state) {
          context.read<TaskListBloc>().add(
            TaskListRequested(
              tagId: tag?.id,
              isCompleted: state.showCompleted ? null : false,
            ),
          );
        },
        child: BlocBuilder<TaskListBloc, TaskListState>(
          builder: (context, state) => TaskListView(
            tasks: state.tasks,
            header: tag != null ? TaskListHeader(tag: tag) : null,
          ),
        ),
      ),
    );
  }
}
