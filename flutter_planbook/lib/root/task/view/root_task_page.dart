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
import 'package:flutter_planbook/task/today/cubit/task_today_cubit.dart';
import 'package:flutter_planbook/task/today/view/task_today_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:pull_down_button/pull_down_button.dart';

@RoutePage()
class RootTaskPage extends StatelessWidget {
  const RootTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              RootTaskBloc(
                  tasksRepository: context.read(),
                )
                ..add(const RootTaskRequested())
                ..add(
                  const RootTaskTaskCountRequested(mode: TaskListMode.inbox),
                )
                ..add(
                  const RootTaskTaskCountRequested(mode: TaskListMode.today),
                )
                ..add(
                  const RootTaskTaskCountRequested(mode: TaskListMode.overdue),
                ),
        ),
        BlocProvider(
          create: (context) => TaskTodayCubit(),
        ),
      ],
      child: _RootTaskPage(),
    );
  }
}

class _RootTaskPage extends StatelessWidget {
  _RootTaskPage();

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
              TaskListMode.today => BlocBuilder<TaskTodayCubit, TaskTodayState>(
                buildWhen: (previous, current) =>
                    previous.date != current.date ||
                    previous.calendarFormat != current.calendarFormat,
                builder: (context, state) {
                  return AppCalendarDateView(
                    date: state.date,
                    calendarFormat: state.calendarFormat,
                    onDateSelected: (date) {
                      context.read<TaskTodayCubit>().onDateSelected(date);
                    },
                    onCalendarFormatChanged: (calendarFormat) {
                      context.read<TaskTodayCubit>().onCalendarFormatChanged(
                        calendarFormat,
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
          CupertinoButton(
            onPressed: () => context.read<RootTaskBloc>().add(
              const RootTaskViewTypeChanged(),
            ),
            child: BlocSelector<RootTaskBloc, RootTaskState, RootTaskViewType>(
              selector: (state) => state.viewType,
              builder: (context, viewType) => Icon(
                switch (viewType) {
                  RootTaskViewType.list => FontAwesomeIcons.list,
                  RootTaskViewType.priority => FontAwesomeIcons.solidFlag,
                },
              ),
            ),
          ),
          PullDownButton(
            itemBuilder: (context) {
              final bloc = context.read<RootTaskBloc>();
              return [
                PullDownMenuItem(
                  title: context.l10n.list,
                  onTap: () => context.read<RootTaskBloc>().add(
                    const RootTaskViewTypeChanged(
                      viewType: RootTaskViewType.list,
                    ),
                  ),
                ),
                PullDownMenuItem(
                  icon: FontAwesomeIcons.solidCircleCheck,
                  title: bloc.state.showCompleted
                      ? context.l10n.hideCompleted
                      : context.l10n.showCompleted,
                  onTap: () => context.read<RootTaskBloc>().add(
                    const RootTaskViewTypeChanged(
                      viewType: RootTaskViewType.priority,
                    ),
                  ),
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
