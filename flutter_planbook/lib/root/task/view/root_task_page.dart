import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_calendar_view.dart';
import 'package:flutter_planbook/app/view/app_tag_icon.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/root/task/view/root_task_drawer.dart';
import 'package:flutter_planbook/root/task/view/root_task_month_title_view.dart';
import 'package:flutter_planbook/root/task/view/root_task_week_title_view.dart';
import 'package:flutter_planbook/task/month/bloc/task_month_bloc.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:flutter_planbook/task/week/bloc/task_week_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:pull_down_button/pull_down_button.dart';

@RoutePage()
class RootTaskPage extends StatelessWidget {
  const RootTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TaskWeekBloc(
            notesRepository: context.read(),
          )..add(TaskWeekDateSelected(date: Jiffy.now())),
        ),
        BlocProvider(
          create: (context) => TaskMonthBloc(
            notesRepository: context.read(),
          )..add(TaskMonthDateSelected(date: Jiffy.now())),
        ),
      ],
      child: AutoTabsRouter(
        routes: const [
          TaskInboxRoute(),
          TaskOverdueRoute(),
          TaskTodayRoute(),
          TaskWeekRoute(),
          TaskMonthRoute(),
          TaskTagRoute(),
        ],
        builder: (context, child) {
          final activeTab = RootTaskTab.values[context.tabsRouter.activeIndex];
          return BlocListener<RootTaskBloc, RootTaskState>(
            listenWhen: (previous, current) =>
                previous.tab != current.tab || activeTab != current.tab,
            listener: (context, state) {
              context.tabsRouter.setActiveIndex(state.tab.index);
            },
            child: _RootTaskPage(child: child),
          );
        },
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
      drawerEdgeDragWidth: 96,
      backgroundColor: Colors.transparent,
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
            RootTaskTab.tag =>
              BlocSelector<RootTaskBloc, RootTaskState, TagEntity?>(
                selector: (state) =>
                    state.tag ??
                    context.read<RootHomeBloc>().state.topLevelTags.firstOrNull,
                builder: (context, tag) => tag == null
                    ? const SizedBox.shrink()
                    : Row(
                        children: [
                          AppTagIcon.fromTagEntity(tag),
                          const SizedBox(width: 4),
                          Text(tag.fullName),
                        ],
                      ),
              ),
          },
        ),
        actions: [
          PullDownButton(
            itemBuilder: (context) {
              final bloc = context.read<RootTaskBloc>();
              final theme = Theme.of(context);
              return [
                if (bloc.state.tab != RootTaskTab.week &&
                    bloc.state.tab != RootTaskTab.month) ...[
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
                if (bloc.state.tab != RootTaskTab.overdue ||
                    bloc.state.tab == RootTaskTab.day ||
                    bloc.state.tab == RootTaskTab.month) ...[
                  if (bloc.state.tab != RootTaskTab.week &&
                      bloc.state.tab != RootTaskTab.month)
                    const PullDownMenuDivider.large(),
                  PullDownMenuTitle(title: Text(context.l10n.showAndHide)),
                ],
                if (bloc.state.tab != RootTaskTab.overdue)
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
                if (bloc.state.tab == RootTaskTab.day ||
                    bloc.state.tab == RootTaskTab.month) ...[
                  PullDownMenuItem(
                    icon: FontAwesomeIcons.arrowsToDot,
                    iconColor: theme.colorScheme.primary,
                    title: bloc.state.tabFocusNoteTypes[bloc.state.tab] == null
                        ? context.l10n.showFocusNote
                        : context.l10n.hideFocusNote,
                    onTap: () {
                      final noteType =
                          bloc.state.tabFocusNoteTypes[bloc.state.tab];
                      context.read<RootTaskBloc>().add(
                        RootTaskTabFocusNoteTypeChanged(
                          tab: bloc.state.tab,
                          noteType: noteType == null
                              ? switch (bloc.state.tab) {
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
