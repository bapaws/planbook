import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_header.dart';
import 'package:flutter_planbook/task/list/view/task_list_view.dart';
import 'package:planbook_api/planbook_api.dart';

@RoutePage()
class TaskInboxPage extends StatelessWidget {
  const TaskInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RootHomeBloc, RootHomeState, List<TagEntity>>(
      selector: (state) => state.topLevelTags,
      builder: (context, tags) => CustomScrollView(
        slivers: [
          BlocProvider(
            create: (context) => TaskListBloc(
              tasksRepository: context.read(),
            )..add(const TaskListRequested()),
            child: BlocBuilder<TaskListBloc, TaskListState>(
              builder: (context, state) => TaskListView(
                tasks: state.tasks,
              ),
            ),
          ),
          for (final tag in tags)
            BlocProvider(
              create: (context) => TaskListBloc(
                tasksRepository: context.read(),
                tag: tag,
              )..add(TaskListRequested(tagId: tag.id)),
              child: BlocBuilder<TaskListBloc, TaskListState>(
                builder: (context, state) => TaskListView(
                  tasks: state.tasks,
                  header: TaskListHeader(tag: tag),
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
      ),
    );
  }
}
