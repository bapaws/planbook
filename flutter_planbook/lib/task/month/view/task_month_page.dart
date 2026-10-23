import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/focus/view/open_period_note_editor.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_bloc_provider.dart';
import 'package:flutter_planbook/task/month/bloc/task_month_bloc.dart';
import 'package:flutter_planbook/task/month/view/task_month_calendar_view.dart';
import 'package:flutter_planbook/task/month/view/task_month_cell.dart';
import 'package:flutter_planbook/task/today/view/task_focus_view.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class TaskMonthPage extends StatelessWidget {
  const TaskMonthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskMonthBloc, TaskMonthState>(
      // 日期网格只随日期集合变化；笔记更新由重点区域独立监听。
      buildWhen: (previous, current) => previous.weeks != current.weeks,
      builder: (context, state) {
        return _TaskMonthPage(weeks: state.weeks);
      },
    );
  }
}

class _TaskMonthPage extends StatelessWidget {
  const _TaskMonthPage({required this.weeks});

  final List<List<Jiffy?>> weeks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendarView(context),
        // 月重点区域
        _buildFocusCell(context),
        const SizedBox(height: 8),
        // 星期标题
        _buildWeekdayHeader(context),
        // 日期网格
        Expanded(child: _buildMonthGrid(context, weeks)),
        SizedBox(
          height: kRootBottomBarHeight + MediaQuery.of(context).padding.bottom,
        ),
      ],
    );
  }

  Widget _buildCalendarView(BuildContext context) {
    return BlocBuilder<TaskMonthBloc, TaskMonthState>(
      buildWhen: (previous, current) =>
          previous.isCalendarExpanded != current.isCalendarExpanded ||
          previous.date != current.date,
      builder: (context, state) => AnimatedSwitcher(
        duration: Durations.medium1,
        transitionBuilder: (child, animation) =>
            SizeTransition(sizeFactor: animation, child: child),
        child: state.isCalendarExpanded
            ? TaskMonthCalendarView(
                date: state.date,
                onDateSelected: (date) {
                  context.read<TaskMonthBloc>().add(
                    TaskMonthDateSelected(date: date),
                  );
                },
              )
            : null,
      ),
    );
  }

  /// 构建星期标题行
  Widget _buildWeekdayHeader(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay =
        weeks.firstOrNull?.firstWhere((day) => day != null) ?? Jiffy.now();
    final weekdayNames = _getWeekdayNames(firstDay);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: weekdayNames.map((name) {
          return Expanded(
            child: Center(
              child: Text(
                name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建月份网格
  Widget _buildMonthGrid(BuildContext context, List<List<Jiffy?>> weeks) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dayWidth = constraints.maxWidth / 7;
        final dayHeight = constraints.maxHeight / weeks.length;
        return Column(
          children: weeks
              .map(
                (week) => SizedBox(
                  width: constraints.maxWidth,
                  height: dayHeight,
                  child: Row(
                    children: week
                        .map(
                          (day) => SizedBox(
                            width: dayWidth,
                            height: dayHeight,
                            child: day != null
                                ? _buildDayCell(context, day)
                                : const SizedBox.shrink(),
                          ),
                        )
                        .toList(),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildFocusCell(BuildContext context) {
    return BlocSelector<RootTaskBloc, RootTaskState, NoteType?>(
      selector: (state) => state.tabFocusNoteTypes[RootTaskTab.month],
      builder: (context, noteType) {
        return AnimatedSwitcher(
          duration: Durations.medium1,
          transitionBuilder: (child, animation) =>
              SizeTransition(sizeFactor: animation, child: child),
          child: noteType == null
              ? const SizedBox.shrink()
              : _buildFocusView(context, noteType),
        );
      },
    );
  }

  Widget _buildFocusView(BuildContext context, NoteType noteType) {
    return BlocSelector<TaskMonthBloc, TaskMonthState, PeriodNoteSnapshot>(
      selector: (state) => state.noteSnapshot(noteType),
      builder: (context, snapshot) {
        return TaskFocusView(
          note: snapshot.note,
          isReady: snapshot.canWrite,
          noteType: noteType,
          onTap: () => openPeriodNoteEditor(
            context,
            displayed: snapshot,
            current: () =>
                context.read<TaskMonthBloc>().state.noteSnapshot(noteType),
          ),
          onMindMapTapped: () {
            _addDiscoverEvent(context, noteType);
            _navigateToRootDiscover(context, noteType);
          },
          onTaskDropped: (task) {
            context.read<TaskMonthBloc>().add(
              TaskMonthNoteTaskAppended(
                task: task,
                noteType: noteType,
                target: snapshot.target,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDayCell(BuildContext context, Jiffy day) {
    return TaskListBlocProvider(
      key: ValueKey(day.dateKey),
      requestEvent: () => TaskListDayAllRequested(
        date: day,
        isCompleted: context.read<RootTaskBloc>().isCompleted,
        selectedTagIds: context.read<RootTaskBloc>().state.selectedTagIds,
      ),
      child: TaskMonthCell(day: day),
    );
  }

  /// 获取一周中每天的名称
  List<String> _getWeekdayNames(Jiffy date) {
    final startOfWeek = date.startOf(Unit.week);
    return List.generate(7, (index) => startOfWeek.add(days: index).E);
  }

  void _addDiscoverEvent(BuildContext context, NoteType noteType) {
    final date = context.read<TaskMonthBloc>().state.date;
    context.read<RootDiscoverBloc>().add(
      noteType.isFocus
          ? RootDiscoverFocusDateChanged(date: date, type: noteType)
          : RootDiscoverSummaryDateChanged(date: date, type: noteType),
    );
  }

  void _navigateToRootDiscover(BuildContext context, NoteType noteType) {
    AutoRouter.of(context).navigate(
      RootHomeRoute(
        children: [
          RootDiscoverRoute(
            children: [
              if (noteType.isFocus)
                const DiscoverFocusRoute()
              else
                const DiscoverSummaryRoute(),
            ],
          ),
        ],
      ),
    );
  }
}
