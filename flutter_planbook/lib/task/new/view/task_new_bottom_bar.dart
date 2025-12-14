import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/task/new/cubit/task_new_cubit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

class TaskNewBottomBar extends StatelessWidget {
  const TaskNewBottomBar({this.focusNode, super.key});

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocSelector<TaskNewCubit, TaskNewState, bool>(
      selector: (state) => state.isInbox,
      builder: (context, isInbox) {
        return Row(
          children: [
            const SizedBox(width: 6),
            BlocSelector<TaskNewCubit, TaskNewState, TaskPriority>(
              selector: (state) => state.priority,
              builder: (context, priority) {
                final brightness = Theme.of(context).brightness;
                final colorScheme = ColorScheme.fromSeed(
                  seedColor: priority.color,
                  brightness: brightness,
                );
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size.square(kMinInteractiveDimension),
                  onPressed: () {
                    _onTagPressed(context, TaskNewFocus.priority);
                  },
                  child: Icon(
                    FontAwesomeIcons.solidFlag,
                    color: colorScheme.primary,
                  ),
                );
              },
            ),
            BlocSelector<TaskNewCubit, TaskNewState, List<TagEntity>>(
              selector: (state) => state.tags,
              builder: (context, tags) {
                final brightness = Theme.of(context).brightness;
                final colorScheme = brightness == Brightness.dark
                    ? tags.firstOrNull?.dark
                    : tags.firstOrNull?.light;
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size.square(kMinInteractiveDimension),
                  onPressed: () {
                    _onTagPressed(context, TaskNewFocus.tags);
                  },
                  child: Icon(
                    FontAwesomeIcons.tags,
                    color: colorScheme?.primary ?? Colors.grey.shade400,
                  ),
                );
              },
            ),
            if (!isInbox) ...[
              BlocSelector<TaskNewCubit, TaskNewState, Jiffy?>(
                selector: (state) => state.startAt,
                builder: (context, startAt) {
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size.square(kMinInteractiveDimension),
                    child: Icon(
                      FontAwesomeIcons.solidClock,
                      color: startAt != null
                          ? colorScheme.tertiary
                          : Colors.grey.shade400,
                    ),
                    onPressed: () {
                      if (!context.read<AppPurchasesBloc>().isPremium) {
                        context.router.push(const AppPurchasesRoute());
                        return;
                      }
                      _onTagPressed(context, TaskNewFocus.time);
                    },
                  );
                },
              ),
              BlocSelector<TaskNewCubit, TaskNewState, RecurrenceRule?>(
                selector: (state) => state.recurrenceRule,
                builder: (context, recurrenceRule) {
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size.square(kMinInteractiveDimension),
                    child: Icon(
                      FontAwesomeIcons.arrowsRotate,
                      color: recurrenceRule != null
                          ? colorScheme.tertiary
                          : Colors.grey.shade400,
                    ),
                    onPressed: () {
                      _onTagPressed(context, TaskNewFocus.recurrence);
                    },
                  );
                },
              ),
            ],
            const Spacer(),
            BlocBuilder<TaskNewCubit, TaskNewState>(
              builder: (context, state) {
                return AnimatedSwitcher(
                  duration: Durations.extralong1,
                  child: state.status == PageStatus.loading
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          minimumSize: const Size.square(
                            kMinInteractiveDimension,
                          ),
                          onPressed:
                              state.title.trim().isEmpty ||
                                  state.status == PageStatus.loading
                              ? null
                              : context.read<TaskNewCubit>().onSave,
                          child: const Icon(
                            FontAwesomeIcons.solidPaperPlane,
                          ),
                        ),
                ).shakeX(animate: state.status == PageStatus.failure);
              },
            ),
          ].animate(interval: 50.ms).fade(duration: 250.ms),
        );
      },
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
