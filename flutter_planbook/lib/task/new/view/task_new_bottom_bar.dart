import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/task/new/cubit/task_new_cubit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/planbook_core.dart';

class TaskNewBottomBar extends StatelessWidget {
  const TaskNewBottomBar({this.focusNode, super.key});

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        BlocSelector<TaskNewCubit, TaskNewState, TaskPriority>(
          selector: (state) => state.priority,
          builder: (context, priority) {
            return CupertinoButton(
              onPressed: () {
                _onTagPressed(context, TaskNewFocus.priority);
              },
              child: Icon(
                FontAwesomeIcons.solidFlag,
                color: priority.color,
              ),
            );
          },
        ),
        BlocSelector<TaskNewCubit, TaskNewState, List<TagEntity>>(
          selector: (state) => state.tags,
          builder: (context, tags) {
            return CupertinoButton(
              onPressed: () {
                _onTagPressed(context, TaskNewFocus.tags);
              },
              child: Icon(
                FontAwesomeIcons.tags,
                color: tags.firstOrNull?.color?.toColor ?? Colors.grey.shade400,
              ),
            );
          },
        ),
        const Spacer(),
        BlocBuilder<TaskNewCubit, TaskNewState>(
          builder: (context, state) {
            return CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              onPressed:
                  state.title.trim().isEmpty ||
                      state.status == PageStatus.loading
                  ? null
                  : context.read<TaskNewCubit>().onSave,
              child: AnimatedSwitcher(
                duration: Durations.extralong1,
                child: state.status == PageStatus.loading
                    ? CupertinoActivityIndicator(
                        radius: 12,
                        color: colorScheme.onSurface,
                      )
                    : const Icon(
                        FontAwesomeIcons.solidPaperPlane,
                      ),
              ),
            ).shakeX(animate: state.status == PageStatus.failure);
          },
        ),
      ],
    );
  }

  void _onTagPressed(BuildContext context, TaskNewFocus focus) {
    final previousFocus = context.read<TaskNewCubit>().state.focus;
    if (previousFocus == focus) {
      FocusScope.of(context).requestFocus();
      context.read<TaskNewCubit>().onFocusChanged(
        TaskNewFocus.title,
      );
    } else {
      FocusScope.of(context).unfocus();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (context.mounted) {
          context.read<TaskNewCubit>().onFocusChanged(
            focus,
          );
        }
      });
    }
  }
}
