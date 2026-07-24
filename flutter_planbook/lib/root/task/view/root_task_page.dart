import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/activity/view/app_activity_notice_app_bar_action.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_calendar_view.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/root/task/view/root_task_drawer.dart';
import 'package:flutter_planbook/root/task/view/root_task_month_title_view.dart';
import 'package:flutter_planbook/root/task/view/root_task_week_title_view.dart';
import 'package:flutter_planbook/task/month/bloc/task_month_bloc.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:flutter_planbook/task/week/bloc/task_week_bloc.dart';
import 'package:flutter_planbook/task/week/model/task_week_view_mode.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:pull_down_button/pull_down_button.dart';

@RoutePage()
class RootTaskPage extends StatelessWidget {
  const RootTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TaskWeekBloc(
            notesRepository: context.read(),
            l10n: l10n,
          )..add(TaskWeekDateSelected(date: Jiffy.now())),
        ),
        BlocProvider(
          create: (context) => TaskMonthBloc(
            notesRepository: context.read(),
            l10n: l10n,
          )..add(TaskMonthDateSelected(date: Jiffy.now())),
        ),
      ],
      child: BlocListener<RootTaskBloc, RootTaskState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == PageStatus.loading) {
            EasyLoading.show(maskType: EasyLoadingMaskType.clear);
          } else if (EasyLoading.isShow) {
            EasyLoading.dismiss();
          }
        },
        child: AutoTabsRouter.tabBar(
          routes: const [
            TaskInboxRoute(),
            TaskOverdueRoute(),
            TaskTodayRoute(),
            TaskWeekRoute(),
            TaskMonthRoute(),
          ],
          builder: (context, child, controller) => _RootTaskPage(child: child),
        ),
      ),
    );
  }
}

class _RootTaskPage extends StatelessWidget {
  _RootTaskPage({required this.child});

  final Widget child;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final activeIndex = context.tabsRouter.activeIndex;
    final tab = RootTaskTab.values[activeIndex];
    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const RootTaskDrawer(),
      drawerEdgeDragWidth: 72,
      backgroundColor: Colors.transparent,
      showBackground: false,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: CupertinoButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          child: const Icon(FontAwesomeIcons.bars),
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: AnimatedSwitcher(
          duration: Durations.medium1,
          child: switch (tab) {
            RootTaskTab.day => BlocBuilder<TaskTodayBloc, TaskTodayState>(
              builder: (context, state) {
                return AppCalendarDateView(
                  date: state.date,
                  calendarFormat: state.calendarFormat,
                  onDateSelected: (date) {
                    final isCompleted =
                        context.read<RootTaskBloc>().state.showCompleted
                        ? null
                        : false;
                    context.read<TaskTodayBloc>().add(
                      TaskTodayDateSelected(
                        date: date,
                        isCompleted: isCompleted,
                      ),
                    );
                  },
                  onCalendarFormatChanged: (calendarFormat) {
                    context.read<TaskTodayBloc>().add(
                      TaskTodayCalendarFormatChanged(
                        calendarFormat: calendarFormat,
                      ),
                    );
                  },
                );
              },
            ),
            RootTaskTab.inbox => Text(context.l10n.inbox),
            RootTaskTab.overdue => Text(context.l10n.overdue),
            RootTaskTab.week => const RootTaskWeekTitleView(),
            RootTaskTab.month => const RootTaskMonthTitleView(),
          },
        ),
        actions: [
          const AppActivityNoticeAppBarActions(),
          _buildViewTypeSwitcher(context, tab),
          PullDownButton(
            itemBuilder: (context) {
              final activeIndex = context.tabsRouter.activeIndex;
              final tab = RootTaskTab.values[activeIndex];
              final bloc = context.read<RootTaskBloc>();
              final theme = Theme.of(context);
              return [
                if (tab == RootTaskTab.inbox || tab == RootTaskTab.overdue) ...[
                  PullDownMenuTitle(title: Text(context.l10n.selectViewType)),
                  PullDownMenuItem.selectable(
                    icon: FontAwesomeIcons.list,
                    iconColor: theme.colorScheme.primary,
                    title: context.l10n.list,
                    selected: bloc.state.viewType == RootTaskViewType.list,
                    onTap: () => context.read<RootTaskBloc>().add(
                      const RootTaskViewTypeChanged(
                        viewType: RootTaskViewType.list,
                      ),
                    ),
                  ),
                  PullDownMenuItem.selectable(
                    icon: FontAwesomeIcons.solidFlag,
                    iconColor: theme.colorScheme.primary,
                    title: context.l10n.quadrant,
                    selected: bloc.state.viewType == RootTaskViewType.priority,
                    onTap: () => context.read<RootTaskBloc>().add(
                      const RootTaskViewTypeChanged(
                        viewType: RootTaskViewType.priority,
                      ),
                    ),
                  ),
                ],
                if (tab != RootTaskTab.overdue ||
                    tab == RootTaskTab.day ||
                    tab == RootTaskTab.month) ...[
                  if (tab == RootTaskTab.inbox || tab == RootTaskTab.overdue)
                    const PullDownMenuDivider.large(),
                  PullDownMenuTitle(title: Text(context.l10n.showAndHide)),
                ],
                if (tab != RootTaskTab.overdue)
                  PullDownMenuItem(
                    icon: FontAwesomeIcons.solidCircleCheck,
                    iconColor: theme.colorScheme.primary,
                    title: bloc.state.showCompleted
                        ? context.l10n.hideCompleted
                        : context.l10n.showCompleted,
                    onTap: () => context.read<RootTaskBloc>().add(
                      const RootTaskShowCompletedChanged(),
                    ),
                  ),
                if (tab == RootTaskTab.day || tab == RootTaskTab.month) ...[
                  PullDownMenuItem(
                    icon: FontAwesomeIcons.arrowsToDot,
                    iconColor: theme.colorScheme.primary,
                    title: bloc.state.tabFocusNoteTypes[tab] == null
                        ? context.l10n.showFocusNote
                        : context.l10n.hideFocusNote,
                    onTap: () {
                      final noteType = bloc.state.tabFocusNoteTypes[tab];
                      context.read<RootTaskBloc>().add(
                        RootTaskTabFocusNoteTypeChanged(
                          tab: tab,
                          noteType: noteType == null
                              ? switch (tab) {
                                  RootTaskTab.day => NoteType.dailyFocus,
                                  RootTaskTab.week => NoteType.weeklyFocus,
                                  RootTaskTab.month => NoteType.monthlyFocus,
                                  _ => throw UnimplementedError(),
                                }
                              : null,
                        ),
                      );
                    },
                  ),
                ],
                if (tab == RootTaskTab.day || tab == RootTaskTab.week)
                  PullDownMenuItem(
                    icon: FontAwesomeIcons.tableColumns,
                    iconColor: theme.colorScheme.primary,
                    title: bloc.state.showSourcePanel
                        ? context.l10n.hideSourcePanel
                        : context.l10n.showSourcePanel,
                    onTap: () => context.read<RootTaskBloc>().add(
                      const RootTaskSourcePanelVisibilityChanged(),
                    ),
                  ),
                const PullDownMenuDivider.large(),
                PullDownMenuItem(
                  icon: FontAwesomeIcons.arrowsRotate,
                  iconColor: theme.colorScheme.primary,
                  title: context.l10n.refresh,
                  onTap: () {
                    context.read<RootTaskBloc>().add(
                      const RootTaskRefreshRequested(),
                    );
                  },
                ),
              ];
            },
            buttonBuilder: (context, showMenu) => CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(kMinInteractiveDimension),
              onPressed: showMenu,
              child: const Icon(FontAwesomeIcons.ellipsis),
            ),
          ),
        ],
      ),
      body: child,
    );
  }

  Widget _buildViewTypeSwitcher(BuildContext context, RootTaskTab tab) {
    final theme = Theme.of(context);
    return switch (tab) {
      RootTaskTab.day =>
        BlocSelector<RootTaskBloc, RootTaskState, RootTaskViewType>(
          selector: (state) => state.viewType,
          builder: (context, viewType) => PullDownButton(
            itemBuilder: (context) => [
              PullDownMenuTitle(title: Text(context.l10n.selectViewType)),
              PullDownMenuItem.selectable(
                icon: FontAwesomeIcons.tags,
                iconColor: theme.colorScheme.primary,
                title: context.l10n.tagList,
                selected: viewType == RootTaskViewType.list,
                onTap: () => context.read<RootTaskBloc>().add(
                  const RootTaskViewTypeChanged(
                    viewType: RootTaskViewType.list,
                  ),
                ),
              ),
              PullDownMenuItem.selectable(
                icon: FontAwesomeIcons.solidFlag,
                iconColor: theme.colorScheme.primary,
                title: context.l10n.quadrant,
                selected: viewType == RootTaskViewType.priority,
                onTap: () => context.read<RootTaskBloc>().add(
                  const RootTaskViewTypeChanged(
                    viewType: RootTaskViewType.priority,
                  ),
                ),
              ),
              PullDownMenuItem.selectable(
                icon: FontAwesomeIcons.tableCells,
                iconColor: theme.colorScheme.primary,
                title: context.l10n.timeBlock,
                selected: viewType == RootTaskViewType.timeBlock,
                onTap: () => context.read<RootTaskBloc>().add(
                  const RootTaskViewTypeChanged(
                    viewType: RootTaskViewType.timeBlock,
                  ),
                ),
              ),
            ],
            buttonBuilder: (context, showMenu) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: showMenu,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(kMinInteractiveDimension),
                onPressed: () {
                  final next = switch (viewType) {
                    RootTaskViewType.list => RootTaskViewType.priority,
                    RootTaskViewType.priority => RootTaskViewType.timeBlock,
                    RootTaskViewType.timeBlock => RootTaskViewType.list,
                  };
                  context.read<RootTaskBloc>().add(
                    RootTaskViewTypeChanged(viewType: next),
                  );
                },
                child: Icon(
                  switch (viewType) {
                    RootTaskViewType.list => FontAwesomeIcons.tags,
                    RootTaskViewType.priority => FontAwesomeIcons.solidFlag,
                    RootTaskViewType.timeBlock => FontAwesomeIcons.tableCells,
                  },
                ),
              ),
            ),
          ),
        ),
      RootTaskTab.week =>
        BlocSelector<TaskWeekBloc, TaskWeekState, TaskWeekViewMode>(
          selector: (state) => state.viewMode,
          builder: (context, viewMode) => PullDownButton(
            itemBuilder: (context) => [
              PullDownMenuTitle(title: Text(context.l10n.selectViewType)),
              PullDownMenuItem.selectable(
                icon: FontAwesomeIcons.tableCells,
                iconColor: theme.colorScheme.primary,
                title: context.l10n.octant,
                selected: viewMode == TaskWeekViewMode.grid,
                onTap: () => context.read<TaskWeekBloc>().add(
                  const TaskWeekViewModeChanged(
                    viewMode: TaskWeekViewMode.grid,
                  ),
                ),
              ),
              PullDownMenuItem.selectable(
                icon: FontAwesomeIcons.listUl,
                iconColor: theme.colorScheme.primary,
                title: context.l10n.list,
                selected: viewMode == TaskWeekViewMode.list,
                onTap: () => context.read<TaskWeekBloc>().add(
                  const TaskWeekViewModeChanged(
                    viewMode: TaskWeekViewMode.list,
                  ),
                ),
              ),
            ],
            buttonBuilder: (context, showMenu) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: showMenu,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(kMinInteractiveDimension),
                onPressed: () {
                  final next = viewMode == TaskWeekViewMode.grid
                      ? TaskWeekViewMode.list
                      : TaskWeekViewMode.grid;
                  context.read<TaskWeekBloc>().add(
                    TaskWeekViewModeChanged(viewMode: next),
                  );
                },
                child: Icon(
                  viewMode == TaskWeekViewMode.grid
                      ? FontAwesomeIcons.tableCells
                      : FontAwesomeIcons.listUl,
                ),
              ),
            ),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  // Widget _buildBody(BuildContext context) {
  //   return BlocBuilder<RootTaskBloc, RootTaskState>(
  //     buildWhen: (previous, current) =>
  //         previous.tab != current.tab || previous.tag != current.tag,
  //     builder: (context, state) => AnimatedSwitcher(
  //       duration: Durations.medium1,
  //       child: switch (state.tab) {
  //         RootTaskTab.day => const TaskTodayPage(),
  //         RootTaskTab.inbox => const TaskInboxPage(),
  //         RootTaskTab.overdue => const TaskOverduePage(),
  //         RootTaskTab.week => const TaskWeekPage(),
  //         RootTaskTab.month => const TaskMonthPage(),
  //         RootTaskTab.tag => TaskTagPage(
  //           key: ValueKey(state.tag!.id),
  //           tag: state.tag!,
  //         ),
  //       },
  //     ),
  //   );
  // }
}
