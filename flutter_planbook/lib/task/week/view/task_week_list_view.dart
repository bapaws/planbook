import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/source/view/task_source_panel.dart'
    show TaskSourcePanel;
import 'package:flutter_planbook/task/time_block/view/task_time_block_demo_banner.dart';
import 'package:flutter_planbook/task/today/view/task_focus_view.dart';
import 'package:flutter_planbook/task/week/bloc/task_week_bloc.dart';
import 'package:flutter_planbook/task/week/view/task_week_calendar_view.dart';
import 'package:flutter_planbook/task/week/view/task_week_list_day_group.dart';
import 'package:flutter_planbook/task/week/view/task_week_list_day_tasks.dart';
import 'package:planbook_repository/planbook_repository.dart';

/// 周视图列表布局
///
/// 顶部展示本周重点与本周总结，下方按天分组：左侧日期、右侧任务。
/// [trailing] 显示在日列表右侧（例如 [TaskSourcePanel]）。
/// 非会员以演示数据展示，并引导升级 PRO。
class TaskWeekListView extends StatelessWidget {
  const TaskWeekListView({
    required this.weekDays,
    this.trailing,
    this.isDemo = false,
    super.key,
  });

  final List<Jiffy> weekDays;

  /// 日列表右侧附加面板（需自行提供对应 Bloc）
  final Widget? trailing;

  /// 是否为演示模式（非会员）
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final bottomBarHeight =
        kRootBottomBarHeight + MediaQuery.of(context).padding.bottom;
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
                // banner 只盖左侧列表，不覆盖侧栏（与时间块一致）。
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = taskWeekListCrossAxisCount(
                      constraints.maxWidth -
                          TaskWeekListDayGroup.dayHeaderExtent,
                    );
                    final list = CustomScrollView(
                      slivers: [
                        for (final day in weekDays)
                          TaskWeekListDayGroup(
                            day: day,
                            crossAxisCount: crossAxisCount,
                            isDemo: isDemo,
                          ),
                        _buildBottomSafeAreaSliver(context),
                        // 演示 banner 浮在底部，额外留出高度避免遮挡末尾任务
                        if (isDemo)
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 56),
                          ),
                      ],
                    );
                    if (!isDemo) return list;
                    return Stack(
                      children: [
                        list,
                        Positioned(
                          bottom: bottomBarHeight,
                          left: 0,
                          right: 8,
                          child: const AppDemoBanner(),
                        ),
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

  Widget _buildBottomSafeAreaSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: kRootBottomBarHeight + MediaQuery.of(context).padding.bottom,
      ),
    );
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
