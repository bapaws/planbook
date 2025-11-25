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
      builder: (context, state) {
        return AppCalendarView(
          date: state.date,
          calendarFormat: state.calendarFormat,
          onDateSelected: (date) {
            context.read<TaskTodayCubit>().onDateSelected(date);
          },
          child: BlocSelector<RootTaskBloc, RootTaskState, RootTaskViewType>(
            selector: (state) => state.viewType,
            builder: (context, viewType) => AnimatedSwitcher(
              duration: Durations.medium1,
              child: switch (viewType) {
                RootTaskViewType.list => const _TaskTodayListPage(),
                RootTaskViewType.priority => const TaskPriorityPage(
                  mode: TaskListMode.today,
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
  const _TaskTodayListPage();

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
        tag: tag,
        mode: TaskListMode.today,
      )..add(TaskListRequested(date: Jiffy.now(), tagId: tag?.id)),
      child: BlocListener<TaskTodayCubit, TaskTodayState>(
        listener: (context, state) {
          context.read<TaskListBloc>().add(
            TaskListRequested(date: state.date, tagId: tag?.id),
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

class _TaskTodayPriorityPage extends StatelessWidget {
  const _TaskTodayPriorityPage();

  @override
  Widget build(BuildContext context) {
    return const TaskPriorityPage(
      mode: TaskListMode.today,
    );
  }
}
