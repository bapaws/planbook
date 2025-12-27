import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:flutter_planbook/task/detail/bloc/task_detail_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TaskDetailBottomBar extends StatelessWidget {
  const TaskDetailBottomBar({super.key});

  static const Duration animationDuration = Durations.short4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () {
            final task = context.read<TaskDetailBloc>().state.task;
            if (task == null) return;
            context.router.push(TaskDoneRoute(task: task));
          },
          child: Container(
            width: kRootBottomBarItemHeight * 2,
            height: kRootBottomBarItemHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(kRootBottomBarItemHeight),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.surfaceContainerHighest,
                  blurRadius: 12,
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: BlocBuilder<TaskDetailBloc, TaskDetailState>(
              builder: (context, state) {
                final task = state.task;

                return AnimatedSwitcher(
                  duration: animationDuration,
                  child: task == null
                      ? const SizedBox.shrink()
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              task.isCompleted
                                  ? context.l10n.uncompleteTask
                                  : context.l10n.completeTask,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            if (!task.isCompleted && task.children.isNotEmpty)
                              Text(
                                context.l10n.incompleteSubtasksCount(
                                  task.children
                                      .where((child) => !child.isCompleted)
                                      .length,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                );
              },
            ),
          ),
        ),

        const Spacer(),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () {
            final task = context.read<TaskDetailBloc>().state.task;
            context.router.push(NoteNewRoute(initialTask: task));
          },
          child: Container(
            width: kRootBottomBarItemHeight,
            height: kRootBottomBarItemHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(kRootBottomBarItemHeight),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.surfaceContainerHighest,
                  blurRadius: 12,
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Icon(
              FontAwesomeIcons.featherPointed,
              size: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
