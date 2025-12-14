import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/list/view/task_list_view.dart';
import 'package:flutter_planbook/task/picker/bloc/task_picker_bloc.dart';
import 'package:flutter_planbook/task/tag/view/task_tag_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class TaskPickerPage extends StatelessWidget {
  const TaskPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TaskPickerBloc(
              tasksRepository: context.read(),
            )
            ..add(const TaskPickerInboxRequested())
            ..add(const TaskPickerTodayRequested()),
      child: AppPageScaffold(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.vertical -
              64,
        ),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: const _TaskPickerPage(),
      ),
    );
  }
}

class _TaskPickerPage extends StatelessWidget {
  const _TaskPickerPage();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // controller: PrimaryScrollController.of(context),
      slivers: [
        const SliverAppBar(
          forceMaterialTransparency: true,
          leading: NavigationBarCloseButton(),
        ),
        BlocSelector<TaskPickerBloc, TaskPickerState, List<TaskEntity>>(
          selector: (state) => state.inboxTasks,
          builder: (context, inboxTasks) => TaskSliverList(
            tasks: inboxTasks,
            header: TaskTagHeader(
              icon: FontAwesomeIcons.inbox,
              title: context.l10n.inbox,
              backgroundColor: Colors.blue,
            ),
            onTaskCompleted: (task) {
              context.router.maybePop(task);
            },
            onTaskPressed: (task) {
              context.router.maybePop(task);
            },
          ),
        ),
        BlocSelector<TaskPickerBloc, TaskPickerState, List<TaskEntity>>(
          selector: (state) => state.todayTasks,
          builder: (context, todayTasks) => TaskSliverList(
            tasks: todayTasks,
            header: TaskTagHeader(
              icon: FontAwesomeIcons.calendar,
              title: context.l10n.today,
              backgroundColor: Colors.red,
            ),
            onTaskCompleted: (task) {
              context.router.maybePop(task);
            },
            onTaskPressed: (task) {
              context.router.maybePop(task);
            },
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom),
        ),
      ],
    );
  }
}
