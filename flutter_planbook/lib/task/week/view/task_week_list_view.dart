import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:flutter_planbook/task/list/view/task_drag_to_day.dart';
import 'package:flutter_planbook/task/list/view/task_list_bloc_provider.dart';
import 'package:flutter_planbook/task/list/view/task_list_delete_dialog_listener.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:flutter_planbook/task/source/view/task_source_panel.dart'
    show TaskSourcePanel;
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:flutter_planbook/task/today/view/task_focus_view.dart';
import 'package:flutter_planbook/task/week/bloc/task_week_bloc.dart';
import 'package:flutter_planbook/task/week/view/task_week_calendar_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

/// 周视图列表布局
///
/// 顶部展示本周重点与本周总结，下方按天分组：左侧日期、右侧任务。
/// [trailing] 显示在日列表右侧（例如 [TaskSourcePanel]）。
class TaskWeekListView extends StatelessWidget {
  const TaskWeekListView({
    required this.weekDays,
    this.trailing,
    super.key,
  });

  final List<Jiffy> weekDays;

  /// 日列表右侧附加面板（需自行提供对应 Bloc）
  final Widget? trailing;

  /// 左侧日期列宽度，与 [_buildDayGroup] 中 [SliverConstrainedCrossAxis] 一致。
  static const _dayHeaderExtent = 64.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendar(context),
        _buildFocusSummaryGroup(context),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                // 列数只随视口宽度变化，提到外层算一次，避免每天 SliverLayoutBuilder
                // 在滚动几何变化时反复重建整组 Grid。
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = _weekListCrossAxisCount(
                      constraints.maxWidth - _dayHeaderExtent,
                    );
                    return CustomScrollView(
                      slivers: [
                        // const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        for (final day in weekDays)
                          _buildDayGroup(context, day, crossAxisCount),
                        _buildBottomSafeAreaSliver(context),
                      ],
                    );
                  },
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context) {
    return BlocSelector<TaskWeekBloc, TaskWeekState, bool>(
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

  Widget _buildFocusSummaryGroup(BuildContext context) {
    return BlocSelector<RootTaskBloc, RootTaskState, NoteType>(
      selector: (state) =>
          state.tabFocusNoteTypes[RootTaskTab.week] ?? NoteType.weeklyFocus,
      builder: (context, noteType) {
        final bloc = context.read<TaskWeekBloc>();
        final note = noteType.isFocus
            ? bloc.state.focusNote
            : bloc.state.summaryNote;
        return TaskFocusView(
          note: note,
          noteType: noteType,
          onTap: () => _openNoteEditor(context, note, noteType),
          onMindMapTapped: () => _openMindMap(context, noteType),
          onTaskDropped: (task) => bloc.add(
            TaskWeekNoteTaskAppended(
              task: task,
              noteType: noteType,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayGroup(
    BuildContext context,
    Jiffy day,
    int crossAxisCount,
  ) {
    final colorScheme = _getColorScheme(context, day);
    return TaskListBlocProvider(
      requestEvent: () => TaskListDayAllRequested(
        date: day,
        isCompleted: context.read<RootTaskBloc>().isCompleted,
        selectedTagIds: context.read<RootTaskBloc>().state.selectedTagIds,
      ),
      child: TaskListDeleteDialogListener(
        child: SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          sliver: SliverCrossAxisGroup(
            slivers: [
              SliverConstrainedCrossAxis(
                maxExtent: _dayHeaderExtent,
                sliver: SliverToBoxAdapter(
                  child: _TaskWeekListDayHeader(
                    day: day,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
              _TaskWeekListDayTasksSliver(
                day: day,
                colorScheme: colorScheme,
                crossAxisCount: crossAxisCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSafeAreaSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: kRootBottomBarHeight + MediaQuery.of(context).padding.bottom,
      ),
    );
  }

  ColorScheme _getColorScheme(BuildContext context, Jiffy day) {
    switch (day.dateTime.weekday) {
      case DateTime.monday:
        return context.greyColorScheme;
      case DateTime.tuesday:
        return context.indigoColorScheme;
      case DateTime.wednesday:
        return context.pinkColorScheme;
      case DateTime.thursday:
        return context.purpleColorScheme;
      case DateTime.friday:
        return context.blueColorScheme;
      case DateTime.saturday:
        return context.redColorScheme;
      case DateTime.sunday:
        return context.amberColorScheme;
      default:
        return context.brownColorScheme;
    }
  }

  void _openNoteEditor(BuildContext context, Note? note, NoteType noteType) {
    context.router.push(
      NoteNewTypeRoute(
        initialNote: note,
        type: noteType,
        focusAt: note?.focusAt ?? context.read<TaskWeekBloc>().state.date,
      ),
    );
  }

  void _openMindMap(BuildContext context, NoteType noteType) {
    final date = context.read<TaskWeekBloc>().state.date;
    context.read<RootDiscoverBloc>().add(
      noteType.isFocus
          ? RootDiscoverFocusDateChanged(date: date, type: noteType)
          : RootDiscoverSummaryDateChanged(date: date, type: noteType),
    );
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

/// 列表视图每天的左侧日期列
class _TaskWeekListDayHeader extends StatelessWidget {
  const _TaskWeekListDayHeader({
    required this.day,
    required this.colorScheme,
  });

  final Jiffy day;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = day.isSame(Jiffy.now(), unit: Unit.day);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _navigateToDay(context),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday
                  ? colorScheme.primary
                  : colorScheme.primaryContainer,
            ),
          ),
          child: Column(
            children: [
              Text(
                day.E,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                day.date.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDay(BuildContext context) {
    context.tabsRouter.setActiveIndex(RootTaskTab.day.index);
    final isCompleted = context.read<RootTaskBloc>().isCompleted;
    context.read<TaskTodayBloc>().add(
      TaskTodayDateSelected(date: day, isCompleted: isCompleted),
    );
  }
}

/// 列表视图每天的任务网格
class _TaskWeekListDayTasksSliver extends StatelessWidget {
  const _TaskWeekListDayTasksSliver({
    required this.day,
    required this.colorScheme,
    required this.crossAxisCount,
  });

  final Jiffy day;
  final ColorScheme colorScheme;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TaskListBloc, TaskListState, List<TaskEntity>>(
      selector: (state) => state.tasks,
      builder: (context, tasks) => SliverTaskDragTarget(
        onAccept: (task) => TaskDropArea.moveTaskToDay(context, task, day),
        sliver: tasks.isEmpty
            ? const SliverToBoxAdapter(child: SizedBox(height: 64))
            : SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 4,
                  mainAxisExtent: 36,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTaskTile(
                    context,
                    tasks[index],
                    index < tasks.length - 1 ? tasks[index + 1] : null,
                  ),
                  childCount: tasks.length,
                ),
              ),
      ),
    );
  }

  Widget _buildTaskTile(
    BuildContext context,
    TaskEntity task,
    TaskEntity? nextTask,
  ) {
    final tile = TaskListTile.week(
      key: ValueKey(task),
      task: task,
      isExpanded: nextTask?.parentId == task.id,
      onPressed: (t) => context.router.push(
        TaskDetailRoute(
          taskId: t.id,
          occurrenceAt: t.occurrence?.occurrenceAt,
        ),
      ),
      onCompleted: (t) => context.read<TaskListBloc>().add(
        TaskListCompleted(task: t),
      ),
      onDeleted: (t) => context.read<TaskListBloc>().add(
        TaskListDeleteRequested(task: t),
      ),
      onEdited: (t) => context.router.push(
        TaskDetailRoute(
          taskId: t.id,
          occurrenceAt: t.occurrence?.occurrenceAt,
        ),
      ),
      onExpanded: (t) => context.read<TaskListBloc>().add(
        TaskListTaskExpanded(task: t),
      ),
    );
    return TaskDraggable(
      task: task,
      feedbackBuilder: _buildDragFeedback,
      child: tile,
    );
  }

  Widget _buildDragFeedback(BuildContext context, TaskEntity task) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: colorScheme.surfaceContainerLowest,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            height: 28,
            child: TaskListTile.week(task: task),
          ),
          const Positioned(
            top: -8,
            right: -8,
            child: Icon(
              FontAwesomeIcons.circlePlus,
              size: 18,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

int _weekListCrossAxisCount(double crossAxisExtent) {
  if (crossAxisExtent < 300) return 1;
  if (crossAxisExtent < 520) return 2;
  if (crossAxisExtent < 800) return 3;
  if (crossAxisExtent < 1100) return 4;
  return 5;
}
