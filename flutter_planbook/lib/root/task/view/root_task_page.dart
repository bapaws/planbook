import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_calendar_view.dart';
import 'package:flutter_planbook/app/view/app_tag_icon.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/view/root_task_drawer.dart';
import 'package:flutter_planbook/task/inbox/view/task_inbox_page.dart';
import 'package:flutter_planbook/task/overdue/view/task_overdue_page.dart';
import 'package:flutter_planbook/task/tag/view/task_tag_page.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:flutter_planbook/task/today/view/task_today_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:pull_down_button/pull_down_button.dart';

@RoutePage()
class RootTaskPage extends StatelessWidget {
  RootTaskPage({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
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
        title: BlocBuilder<RootTaskBloc, RootTaskState>(
          buildWhen: (previous, current) =>
              previous.tab != current.tab || previous.tag != current.tag,
          builder: (context, state) => AnimatedSwitcher(
            duration: Durations.medium1,
            child: switch (state.tab) {
              TaskListMode.today => BlocBuilder<TaskTodayBloc, TaskTodayState>(
                builder: (context, state) {
                  return AppCalendarDateView(
                    date: state.date,
                    calendarFormat: state.calendarFormat,
                    onDateSelected: (date) {
                      context.read<TaskTodayBloc>().add(
                        TaskTodayDateSelected(date: date),
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
              TaskListMode.inbox => Text(context.l10n.inbox),
              TaskListMode.overdue => Text(context.l10n.overdue),
              TaskListMode.tag => Row(
                children: [
                  AppTagIcon.fromTagEntity(state.tag!),
                  const SizedBox(width: 4),
                  Text(state.tag!.fullName),
                ],
              ),
            },
          ),
        ),
        actions: [
          // CupertinoButton(
          //   onPressed: () => context.read<RootTaskBloc>().add(
          //     const RootTaskViewTypeChanged(),
          //   ),
          //   child: BlocSelector<RootTaskBloc, RootTaskState, RootTaskViewType>(
          //     selector: (state) => state.viewType,
          //     builder: (context, viewType) => Icon(
          //       switch (viewType) {
          //         RootTaskViewType.list => FontAwesomeIcons.list,
          //         RootTaskViewType.priority => FontAwesomeIcons.solidFlag,
          //       },
          //     ),
          //   ),
          // ),
          PullDownButton(
            itemBuilder: (context) {
              final bloc = context.read<RootTaskBloc>();
              final theme = Theme.of(context);
              return [
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
                if (bloc.state.tab != TaskListMode.overdue) ...[
                  const PullDownMenuDivider.large(),
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
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<RootTaskBloc, RootTaskState>(
      buildWhen: (previous, current) =>
          previous.tab != current.tab || previous.tag != current.tag,
      builder: (context, state) => AnimatedSwitcher(
        duration: Durations.medium1,
        child: switch (state.tab) {
          TaskListMode.today => const TaskTodayPage(),
          TaskListMode.inbox => const TaskInboxPage(),
          TaskListMode.overdue => const TaskOverduePage(),
          TaskListMode.tag => TaskTagPage(
            key: ValueKey(state.tag!.id),
            tag: state.tag!,
          ),
        },
      ),
    );
  }
}
