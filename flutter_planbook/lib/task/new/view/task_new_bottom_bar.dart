import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/purchases/bloc/app_purchases_bloc.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/task/duration/model/task_duration_entity.dart';
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
                final colorScheme = priority.getColorScheme(context);
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size.square(kMinInteractiveDimension),
                  onPressed: () {
                    final cubit = context.read<TaskNewCubit>();
                    context.router.push(
                      TaskPriorityPickerRoute(
                        selectedPriority: cubit.state.priority,
                        onSelected: cubit.onPriorityChanged,
                      ),
                    );
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
                    final cubit = context.read<TaskNewCubit>();
                    context.router.push(
                      TagPickerRoute(
                        selectedTags: cubit.state.tags,
                        onSelected: cubit.onTagsChanged,
                      ),
                    );
                  },
                  child: Icon(
                    FontAwesomeIcons.tags,
                    color: colorScheme?.primary ?? Colors.grey.shade400,
                  ),
                );
              },
            ),
            BlocSelector<TaskNewCubit, TaskNewState, List<TaskEntity>>(
              selector: (state) => state.children,
              builder: (context, children) {
                return Badge.count(
                  isLabelVisible: children.isNotEmpty,
                  count: children.length,
                  backgroundColor: colorScheme.errorContainer,
                  offset: const Offset(-3, 3),
                  textColor: colorScheme.error,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size.square(kMinInteractiveDimension),
                    onPressed: () async {
                      final cubit = context.read<TaskNewCubit>();
                      final children = await context.router
                          .push<List<TaskEntity>>(
                            TaskNewChildRoute(subTasks: cubit.state.children),
                          );
                      if (children is! List<TaskEntity> || !context.mounted) {
                        return;
                      }
                      context.read<TaskNewCubit>().onChildrenChanged(children);
                    },
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Icon(
                        FontAwesomeIcons.shareNodes,
                        color: children.isNotEmpty
                            ? colorScheme.tertiary
                            : Colors.grey.shade400,
                      ),
                    ),
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
                    onPressed: () async {
                      if (!context.read<AppPurchasesBloc>().isPremium) {
                        await context.router.push(const AppPurchasesRoute());
                        return;
                      }
                      final cubit = context.read<TaskNewCubit>();
                      final entity = await context.router.push(
                        TaskDurationRoute(
                          startAt: cubit.state.startAt,
                          endAt: cubit.state.endAt,
                          isAllDay: false,
                        ),
                      );
                      if (entity is! TaskDurationEntity || !context.mounted) {
                        return;
                      }
                      cubit.onDurationChanged(entity);
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
                    onPressed: () async {
                      final cubit = context.read<TaskNewCubit>();
                      final recurrenceRule = await context.router.push(
                        TaskRecurrenceRoute(
                          initialRecurrenceRule: cubit.state.recurrenceRule,
                        ),
                      );
                      if (recurrenceRule is! RecurrenceRule ||
                          !context.mounted) {
                        return;
                      }
                      cubit.onRecurrenceRuleChanged(recurrenceRule);
                    },
                  );
                },
              ),
            ],
            const Spacer(),
            BlocBuilder<TaskNewCubit, TaskNewState>(
              builder: (context, state) {
                return CupertinoButton(
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
                ).shakeX(animate: state.status == PageStatus.failure);
              },
            ),
          ].animate(interval: 50.ms).fade(duration: 250.ms),
        );
      },
    );
  }
}
