import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
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
          onPressed: () {},
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
            child: AnimatedSwitcher(
              duration: animationDuration,
              child: Icon(
                FontAwesomeIcons.square,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
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
