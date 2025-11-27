import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_calendar_view.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_header.dart';
import 'package:flutter_planbook/task/list/view/task_list_view.dart';
import 'package:flutter_planbook/task/priority/bloc/task_priority_bloc.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_page.dart';
import 'package:flutter_planbook/task/today/cubit/task_today_cubit.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

@RoutePage()
class TaskTodayPage extends StatelessWidget {
  const TaskTodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskTodayCubit, TaskTodayState>(
      builder: (context, todayState) {
        return AppCalendarView(
          date: todayState.date,
          calendarFormat: todayState.calendarFormat,
          onDateSelected: (date) {
            context.read<TaskTodayCubit>().onDateSelected(date);
          },
          child: BlocBuilder<RootTaskBloc, RootTaskState>(
            buildWhen: (previous, current) =>
                previous.viewType != current.viewType ||
                previous.showCompleted != current.showCompleted,
            builder: (context, rootTaskState) => AnimatedSwitcher(
              duration: Durations.medium1,
              child: switch (rootTaskState.viewType) {
                RootTaskViewType.list => _TaskTodayListPage(
                  day: todayState.date,
                  showCompleted: rootTaskState.showCompleted,
                ),
                RootTaskViewType.priority => _TaskTodayPriorityPage(
                  day: todayState.date,
                  showCompleted: rootTaskState.showCompleted,
                ),
              },
            ),
          ),
        );
      },
    );
  }
}

class _TaskTodayListPage extends StatelessWidget {
  const _TaskTodayListPage({this.day, this.showCompleted = true});

  final Jiffy? day;
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
      create: (context) =>
          TaskListBloc(
            tasksRepository: context.read(),
            notesRepository: context.read(),
            tag: tag,
            mode: TaskListMode.today,
          )..add(
            TaskListRequested(
              date: day,
              tagId: tag?.id,
              showCompleted: showCompleted,
            ),
          ),
      child: MultiBlocListener(
        listeners: [
          BlocListener<RootTaskBloc, RootTaskState>(
            listenWhen: (previous, current) =>
                previous.showCompleted != current.showCompleted,
            listener: (context, state) {
              final date = context.read<TaskTodayCubit>().state.date;
              context.read<TaskListBloc>().add(
                TaskListRequested(
                  date: date,
                  tagId: tag?.id,
                  showCompleted: state.showCompleted,
                ),
              );
            },
          ),
          BlocListener<TaskTodayCubit, TaskTodayState>(
            listenWhen: (previous, current) => previous.date != current.date,
            listener: (context, state) {
              final showCompleted = context
                  .read<RootTaskBloc>()
                  .state
                  .showCompleted;
              context.read<TaskListBloc>().add(
                TaskListRequested(
                  date: state.date,
                  tagId: tag?.id,
                  showCompleted: showCompleted,
                ),
              );
            },
          ),
        ],
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

class _TaskTodayPriorityPage extends StatelessWidget {
  const _TaskTodayPriorityPage({this.day, this.showCompleted = true});

  final Jiffy? day;
  final bool showCompleted;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = TaskPriorityBloc(
          tasksRepository: context.read(),
          notesRepository: context.read(),
          mode: TaskListMode.today,
        );
        _onRequested(
          bloc: bloc,
          date: day,
          showCompleted: showCompleted,
        );
        return bloc;
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<TaskTodayCubit, TaskTodayState>(
            listenWhen: (previous, current) => previous.date != current.date,
            listener: (context, state) {
              final bloc = context.read<TaskPriorityBloc>();
              _onRequested(
                bloc: bloc,
                date: state.date,
                showCompleted: showCompleted,
              );
            },
          ),
          BlocListener<RootTaskBloc, RootTaskState>(
            listenWhen: (previous, current) =>
                previous.showCompleted != current.showCompleted,
            listener: (context, state) {
              final bloc = context.read<TaskPriorityBloc>();
              _onRequested(
                bloc: bloc,
                showCompleted: state.showCompleted,
              );
            },
          ),
        ],
        child: const TaskPriorityPage(
          mode: TaskListMode.today,
        ),
      ),
    );
  }

  void _onRequested({
    required TaskPriorityBloc bloc,
    Jiffy? date,
    bool showCompleted = true,
  }) {
    bloc
      ..add(
        TaskPriorityRequested(
          date: date,
          priority: TaskPriority.high,
          showCompleted: showCompleted,
        ),
      )
      ..add(
        TaskPriorityRequested(
          date: date,
          priority: TaskPriority.medium,
          showCompleted: showCompleted,
        ),
      )
      ..add(
        TaskPriorityRequested(
          date: date,
          priority: TaskPriority.low,
          showCompleted: showCompleted,
        ),
      )
      ..add(
        TaskPriorityRequested(
          date: date,
          priority: TaskPriority.none,
          showCompleted: showCompleted,
        ),
      );
  }
}
