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
  const TaskTagPage({required this.tag, super.key});

  final TagEntity tag;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        BlocProvider(
          create: (context) =>
              TaskListBloc(
                tasksRepository: context.read(),
                notesRepository: context.read(),
                tag: tag,
                mode: TaskListMode.today,
              )..add(
                TaskListRequested(
                  date: Jiffy.now(),
                  tagId: tag.id,
                  isCompleted: context.read<RootTaskBloc>().isCompleted,
                ),
              ),
          child: BlocBuilder<TaskListBloc, TaskListState>(
            builder: (context, state) => TaskListView(
              tasks: state.tasks,
              header: TaskTagHeader(
                icon: FontAwesomeIcons.calendar,
                title: context.l10n.today,
                backgroundColor: Colors.red,
              ),
            ),
          ),
        ),

        BlocProvider(
          create: (context) =>
              TaskListBloc(
                tasksRepository: context.read(),
                notesRepository: context.read(),
              )..add(
                TaskListRequested(
                  tagId: tag.id,
                  isCompleted: context.read<RootTaskBloc>().isCompleted,
                ),
              ),
          child: BlocBuilder<TaskListBloc, TaskListState>(
            builder: (context, state) {
              return TaskListView(
                tasks: state.tasks,
                header: TaskTagHeader(
                  icon: FontAwesomeIcons.inbox,
                  title: context.l10n.inbox,
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ),

        BlocProvider(
          create: (context) =>
              TaskListBloc(
                tasksRepository: context.read(),
                notesRepository: context.read(),
                tag: tag,
                mode: TaskListMode.overdue,
              )..add(
                TaskListRequested(
                  date: Jiffy.now(),
                  tagId: tag.id,
                  isCompleted: context.read<RootTaskBloc>().isCompleted,
                ),
              ),
          child: BlocBuilder<TaskListBloc, TaskListState>(
            builder: (context, state) => TaskListView(
              tasks: state.tasks,
              header: TaskTagHeader(
                icon: FontAwesomeIcons.clock,
                title: context.l10n.overdue,
                backgroundColor: Colors.green,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height:
                16 +
                kRootBottomBarHeight +
                MediaQuery.of(context).padding.bottom,
          ),
        ),
      ],
    );
  }
}
