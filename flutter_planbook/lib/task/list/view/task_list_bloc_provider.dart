import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/root/task/model/root_task_tab.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:planbook_api/database/task_priority.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_core/data/page_status.dart';

class TaskListBlocProvider extends StatelessWidget {
  const TaskListBlocProvider({
    required this.child,
    required this.requestEvent,
    this.tagId,
    this.mode = TaskListMode.today,
    this.priority,
    super.key,
  });

  final String? tagId;
  final TaskListMode mode;
  final TaskPriority? priority;
  final Widget child;
  final ValueGetter<TaskListEvent> requestEvent;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskListBloc(
        tasksRepository: context.read(),
        notesRepository: context.read(),
        settingsRepository: context.read(),
        mode: mode,
        priority: priority,
      )..add(requestEvent()),
      child: MultiBlocListener(
        listeners: [
          BlocListener<RootTaskBloc, RootTaskState>(
            listenWhen: (previous, current) =>
                previous.showCompleted != current.showCompleted,
            listener: (context, state) {
              final event = requestEvent();
              context.read<TaskListBloc>().add(event);
            },
          ),
          BlocListener<TaskListBloc, TaskListState>(
            listenWhen: (previous, current) =>
                previous.currentTaskNote != current.currentTaskNote &&
                current.currentTaskNote != null,
            listener: (context, state) {
              context.router.push(
                NoteNewRoute(
                  initialNote: state.currentTaskNote,
                ),
              );
            },
          ),

          BlocListener<TaskListBloc, TaskListState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == PageStatus.loading) {
                if (EasyLoading.isShow) return;
                EasyLoading.show();
              } else if (EasyLoading.isShow) {
                EasyLoading.dismiss();
              }
            },
          ),

          if (tagId != null)
            BlocListener<RootTaskBloc, RootTaskState>(
              listenWhen: (previous, current) =>
                  previous.tag != current.tag && current.tab == RootTaskTab.tag,
              listener: (context, state) {
                final event = requestEvent();
                context.read<TaskListBloc>().add(event);
              },
            ),
        ],
        child: child,
      ),
    );
  }
}
