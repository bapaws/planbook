import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_view.dart';
import 'package:flutter_planbook/task/priority/bloc/task_priority_bloc.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_page.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class TaskInboxPage extends StatelessWidget {
  const TaskInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RootTaskBloc, RootTaskState>(
      buildWhen: (previous, current) =>
          previous.viewType != current.viewType ||
          previous.showCompleted != current.showCompleted,
      builder: (context, state) => AnimatedSwitcher(
        duration: Durations.medium1,
        child: switch (state.viewType) {
          RootTaskViewType.list => _TaskInboxListPage(
            showCompleted: state.showCompleted,
          ),
          RootTaskViewType.priority => _TaskInboxPriorityPage(
            showCompleted: state.showCompleted,
          ),
        },
      ),
    );
  }
}

class _TaskInboxListPage extends StatelessWidget {
  const _TaskInboxListPage({this.showCompleted = true});

  final bool showCompleted;

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
      create: (context) => TaskListBloc(
        tasksRepository: context.read(),
        notesRepository: context.read(),
        tag: tag,
      )..add(TaskListRequested(tagId: tag?.id, isCompleted: showCompleted)),
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
          ),
        ),
      ),
    );
  }
}

class _TaskInboxPriorityPage extends StatelessWidget {
  const _TaskInboxPriorityPage({this.showCompleted = true});

  final bool showCompleted;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = TaskPriorityBloc(
          tasksRepository: context.read(),
          notesRepository: context.read(),
        );
        _onRequested(bloc: bloc, isCompleted: showCompleted ? null : false);
        return bloc;
      },
      child: BlocListener<RootTaskBloc, RootTaskState>(
        listenWhen: (previous, current) =>
            previous.showCompleted != current.showCompleted,
        listener: (context, state) {
          final bloc = context.read<TaskPriorityBloc>();
          _onRequested(
            bloc: bloc,
            isCompleted: state.showCompleted ? null : false,
          );
        },
        child: const TaskPriorityPage(
          mode: TaskListMode.today,
        ),
      ),
    );
  }

  void _onRequested({
    required TaskPriorityBloc bloc,
    bool? isCompleted,
  }) {
    bloc
      ..add(
        TaskPriorityRequested(
          priority: TaskPriority.high,
          isCompleted: isCompleted,
        ),
      )
      ..add(
        TaskPriorityRequested(
          priority: TaskPriority.medium,
          isCompleted: isCompleted,
        ),
      )
      ..add(
        TaskPriorityRequested(
          priority: TaskPriority.low,
          isCompleted: isCompleted,
        ),
      )
      ..add(
        TaskPriorityRequested(
          priority: TaskPriority.none,
          isCompleted: isCompleted,
        ),
      );
  }
}
