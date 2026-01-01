import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
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
    return BlocSelector<TaskMonthBloc, TaskMonthState, Note?>(
      selector: (state) => state.note,
      builder: (context, note) => TaskFocusView(
        note: note,
        type: NoteType.monthlyFocus,
        onTap: () {
          final focusAt = context.read<TaskMonthBloc>().state.date;
          context.router.push(
            NoteFocusRoute(
              initialNote: note,
              type: NoteType.monthlyFocus,
              focusAt: focusAt,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, Jiffy day) {
    return TaskListBlocProvider(
      key: ValueKey(day.dateKey),
      requestEvent: () => TaskListDayAllRequested(
        date: day,
        isCompleted: context.read<RootTaskBloc>().isCompleted,
      ),
      child: TaskMonthCell(day: day),
    );
  }

  /// 获取一周中每天的名称
  List<String> _getWeekdayNames(Jiffy date) {
    final startOfWeek = date.startOf(Unit.week);
    return List.generate(7, (index) => startOfWeek.add(days: index).E);
  }
}
