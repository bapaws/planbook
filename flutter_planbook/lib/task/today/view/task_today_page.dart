import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_calendar_view.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_bloc_provider.dart';
import 'package:flutter_planbook/task/list/view/task_list_header.dart';
import 'package:flutter_planbook/task/list/view/task_list_view.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_page.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:flutter_planbook/task/today/view/task_focus_view.dart';
import 'package:planbook_api/planbook_api.dart';

@RoutePage()
class TaskTodayPage extends StatelessWidget {
  const TaskTodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskTodayBloc, TaskTodayState>(
      builder: (context, todayState) {
        return Column(
          children: [
            AppCalendarView<TaskEntity>(
              date: todayState.date,
              calendarFormat: todayState.calendarFormat,
              // eventLoader: (day) {
              //   final date = Jiffy.parseFromDateTime(day);
              //   final count = todayState.taskCounts[date.dateKey];
              //   if (count == null) {
              //     context.read<TaskTodayBloc>().add(
              //       TaskTodayTaskCountRequested(date),
              //     );
              //     return [];
              //   }
              //   return [];
              // },
              onDateSelected: (date) {
                context.read<TaskTodayBloc>().add(
                  TaskTodayDateSelected(
                    date: date,
                    isCompleted: context.read<RootTaskBloc>().isCompleted,
                  ),
                );
              },
            ),
            TaskFocusView(
              note: todayState.focusNote,
              type: NoteType.dailyFocus,
              onTap: () {
                final note = todayState.focusNote;
                final focusAt = context.read<TaskTodayBloc>().state.date;
                context.router.push(
                  NoteFocusRoute(
                    initialNote: note,
                    type: NoteType.dailyFocus,
                    focusAt: focusAt,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<RootTaskBloc, RootTaskState>(
                buildWhen: (previous, current) =>
                    previous.viewType != current.viewType ||
                    previous.showCompleted != current.showCompleted ||
                    previous.priorityStyle != current.priorityStyle,
                builder: (context, rootTaskState) => AnimatedSwitcher(
                  duration: Durations.medium1,
                  child: switch (rootTaskState.viewType) {
                    RootTaskViewType.list => const _TaskTodayListPage(),
                    RootTaskViewType.priority => TaskPriorityPage(
                      style: rootTaskState.priorityStyle,
                      mode: TaskListMode.today,
                      date: todayState.date,
                      isCompleted: rootTaskState.isCompleted,
                    ),
                  },
                ),
              ),
            ),
          ],
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
    return TaskListBlocProvider(
      key: tag != null ? ValueKey(tag.id) : const ValueKey('no-tag'),
      requestEvent: () => TaskListRequested(
        date: context.read<TaskTodayBloc>().state.date,
        tagId: tag?.id,
        isCompleted: context.read<RootTaskBloc>().isCompleted,
      ),
      child: BlocListener<TaskTodayBloc, TaskTodayState>(
        listenWhen: (previous, current) => previous.date != current.date,
        listener: (context, state) {
          context.read<TaskListBloc>().add(
            TaskListRequested(
              date: state.date,
              tagId: tag?.id,
              isCompleted: context.read<RootTaskBloc>().isCompleted,
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
