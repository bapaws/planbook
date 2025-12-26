import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/week/bloc/task_week_bloc.dart';
import 'package:flutter_planbook/task/week/view/task_week_calendar_view.dart';
import 'package:flutter_planbook/task/week/view/task_week_cell.dart';
import 'package:flutter_planbook/task/week/view/task_week_focus_cell.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class TaskWeekPage extends StatelessWidget {
  const TaskWeekPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskWeekBloc, TaskWeekState>(
      builder: (context, state) {
        return _TaskWeekPage(weekDays: state.weekDays);
      },
    );
  }
}

class _TaskWeekPage extends StatelessWidget {
  const _TaskWeekPage({required this.weekDays});

  final List<Jiffy> weekDays;

  static const spacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return AnimatedSwitcher(
      duration: Durations.medium1,
      child: isLandscape
          ? _buildLandscapeLayout(context)
          : _buildPortraitLayout(context),
    );
  }

  Widget _buildCalendarView(BuildContext context) {
    return BlocSelector<TaskWeekBloc, TaskWeekState, bool>(
      key: const ValueKey('calendar_view'),
      selector: (state) => state.isCalendarExpanded,
      builder: (context, isExpanded) => AnimatedSwitcher(
        duration: Durations.medium1,
        transitionBuilder: (child, animation) =>
            SizeTransition(sizeFactor: animation, child: child),
        child: isExpanded
            ? TaskWeekCalendarView(
                date: weekDays[0],
                onDateSelected: (date) {
                  context.read<TaskWeekBloc>().add(
                    TaskWeekDateSelected(date: date),
                  );
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  /// 横屏布局: 2行4列
  Widget _buildLandscapeLayout(BuildContext context) {
    return Column(
      children: [
        _buildCalendarView(context),
        Expanded(
          child: Row(
            children: [
              _buildInboxCell(context),
              _buildDayCell(context, 0),
              _buildDayCell(context, 1),
              _buildDayCell(context, 2),
            ],
          ),
        ),
        const SizedBox(height: spacing),
        Expanded(
          child: Row(
            children: [
              _buildDayCell(context, 3),
              _buildDayCell(context, 4),
              _buildDayCell(context, 5),
              _buildDayCell(context, 6),
            ],
          ),
        ),
        SizedBox(
          height: kRootBottomBarHeight + MediaQuery.of(context).padding.bottom,
        ),
      ],
    );
  }

  /// 竖屏布局: 4行2列
  Widget _buildPortraitLayout(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildCalendarView(context),
        Divider(
          height: 1,
          color: theme.colorScheme.surfaceContainer,
        ),
        Expanded(
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildInboxCell(context),
                VerticalDivider(
                  width: 1,
                  color: theme.colorScheme.surfaceContainer,
                  thickness: 1,
                ),
                _buildDayCell(context, 0),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: theme.colorScheme.surfaceContainer,
        ),
        Expanded(
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildDayCell(context, 1),
                VerticalDivider(
                  width: 1,
                  color: theme.colorScheme.surfaceContainer,
                  thickness: 1,
                ),
                _buildDayCell(context, 2),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: theme.colorScheme.surfaceContainer,
        ),
        Expanded(
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildDayCell(context, 3),
                VerticalDivider(
                  width: 1,
                  color: theme.colorScheme.surfaceContainer,
                  thickness: 1,
                ),
                _buildDayCell(context, 4),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: theme.colorScheme.surfaceContainer,
        ),
        Expanded(
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildDayCell(context, 5),
                VerticalDivider(
                  width: 1,
                  color: theme.colorScheme.surfaceContainer,
                  thickness: 1,
                ),
                _buildDayCell(context, 6),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: theme.colorScheme.surfaceContainer,
        ),
        SizedBox(
          height: kRootBottomBarHeight + MediaQuery.of(context).padding.bottom,
        ),
      ],
    );
  }

  Widget _buildInboxCell(BuildContext context) {
    return BlocSelector<TaskWeekBloc, TaskWeekState, Note?>(
      selector: (state) => state.note,
      builder: (context, note) => TaskWeekFocusCell(note: note),
    );
  }

  Widget _buildDayCell(BuildContext context, int index) {
    final day = weekDays[index];
    return BlocProvider(
      key: ValueKey(day.dateKey),
      create: (context) =>
          TaskListBloc(
            tasksRepository: context.read(),
            notesRepository: context.read(),
            settingsRepository: context.read(),
            mode: TaskListMode.today,
          )..add(
            TaskListDayAllRequested(
              date: day,
              isCompleted: context.read<RootTaskBloc>().isCompleted,
            ),
          ),
      child: BlocListener<RootTaskBloc, RootTaskState>(
        listenWhen: (previous, current) =>
            previous.showCompleted != current.showCompleted,
        listener: (context, state) {
          context.read<TaskListBloc>().add(
            TaskListDayAllRequested(
              date: day,
              isCompleted: state.isCompleted,
            ),
          );
        },
        child: TaskWeekCell(
          title: day.E,
          subtitle: day.date.toString(),
          day: day,
          colorScheme: _getColorScheme(context, day),
        ),
      ),
    );
  }

  ColorScheme _getColorScheme(BuildContext context, Jiffy day) {
    switch (day.dateTime.weekday) {
      case DateTime.monday:
        return context.greyColorScheme;
      case DateTime.tuesday:
        return context.blueColorScheme;
      case DateTime.wednesday:
        return context.amberColorScheme;
      case DateTime.thursday:
        return context.purpleColorScheme;
      case DateTime.friday:
        return context.blueColorScheme;
      case DateTime.saturday:
        return context.pinkColorScheme;
      case DateTime.sunday:
        return context.redColorScheme;
      default:
        return context.brownColorScheme;
    }
  }
}
