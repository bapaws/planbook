import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_view.dart';
import 'package:flutter_planbook/task/tag/view/task_tag_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

@RoutePage()
class TaskTagPage extends StatelessWidget {
  const TaskTagPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RootTaskBloc, RootTaskState>(
      listener: (context, state) => state.tag,
      child: CustomScrollView(
        slivers: [
          _buildTaskList(context, TaskListMode.today),
          _buildTaskList(context, TaskListMode.inbox),
          _buildTaskList(context, TaskListMode.overdue),

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

  Widget _buildTaskList(BuildContext context, TaskListMode mode) {
    return BlocProvider(
      create: (context) =>
          TaskListBloc(
            settingsRepository: context.read(),
            tasksRepository: context.read(),
            notesRepository: context.read(),
            mode: mode,
          )..add(
            TaskListRequested(
              date: Jiffy.now(),
              tagId: context.read<RootTaskBloc>().state.tag?.id,
              isCompleted: context.read<RootTaskBloc>().isCompleted,
            ),
          ),
      child: BlocListener<RootTaskBloc, RootTaskState>(
        listenWhen: (previous, current) => previous.tag != current.tag,
        listener: (context, state) {
          context.read<TaskListBloc>().add(
            TaskListRequested(
              date: Jiffy.now(),
              tagId: state.tag?.id,
              isCompleted: context.read<RootTaskBloc>().isCompleted,
            ),
          );
        },
        child: BlocBuilder<TaskListBloc, TaskListState>(
          builder: (context, state) => TaskListView(
            tasks: state.tasks,
            header: switch (mode) {
              TaskListMode.today => TaskTagHeader(
                icon: FontAwesomeIcons.calendar,
                title: context.l10n.today,
                backgroundColor: Colors.green,
              ),
              TaskListMode.inbox => TaskTagHeader(
                icon: FontAwesomeIcons.inbox,
                title: context.l10n.inbox,
                backgroundColor: Colors.blue,
              ),
              TaskListMode.overdue => TaskTagHeader(
                icon: FontAwesomeIcons.clock,
                title: context.l10n.overdue,
                backgroundColor: Colors.red,
              ),
              _ => throw UnimplementedError(),
            },
          ),
        ),
      ),
    );
  }
}
