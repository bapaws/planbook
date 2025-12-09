import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_view.dart';
import 'package:flutter_svg/svg.dart';

@RoutePage()
class TaskListPage extends StatelessWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskListBloc(
        tasksRepository: context.read(),
        notesRepository: context.read(),
      ),
      child: const _TaskListPage(),
    );
  }
}

class _TaskListPage extends StatelessWidget {
  const _TaskListPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskListBloc, TaskListState>(
      builder: (context, state) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: state.tasks.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        24 +
                        kBottomNavigationBarHeight +
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/Summer-Collection.svg',
                    width: 280,
                    height: 280,
                  ),
                ),
              )
            : TaskListView(
                tasks: state.tasks,
              ),
      ),
    );
  }
}
