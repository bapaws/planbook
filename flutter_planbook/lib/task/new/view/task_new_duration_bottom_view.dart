import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/new/cubit/task_new_cubit.dart';
import 'package:flutter_planbook/task/new/view/duration_text.dart';
import 'package:jiffy/jiffy.dart';

class TaskNewDurationBottomView extends StatelessWidget {
  const TaskNewDurationBottomView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 12),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          onPressed: () {
            _onDurationEnabledChanged(
              context,
              context.read<TaskNewCubit>().state.startAt == null,
            );
          },
          child: Row(
            children: [
              Text(
                context.l10n.duration,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              BlocSelector<TaskNewCubit, TaskNewState, bool>(
                selector: (state) => state.startAt != null,
                builder: (context, enabled) {
                  return CupertinoSwitch(
                    value: enabled,
                    onChanged: (value) {
                      _onDurationEnabledChanged(context, value);
                    },
                  );
                },
              ),
            ],
          ),
        ),
        BlocBuilder<TaskNewCubit, TaskNewState>(
          buildWhen: (previous, current) =>
              previous.startAt != current.startAt ||
              previous.endAt != current.endAt,
          builder: (context, state) => AnimatedSwitcher(
            duration: Durations.medium1,
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            ),
            child: state.startAt != null && state.endAt != null
                ? Column(
                    children: [
                      Divider(
                        indent: 12,
                        endIndent: 12,
                        height: 24,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child:
                                BlocSelector<
                                  TaskNewCubit,
                                  TaskNewState,
                                  Jiffy?
                                >(
                                  selector: (state) => state.startAt,
                                  builder: (context, startAt) {
                                    return CupertinoButton(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.l10n.startTime,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.outline,
                                                ),
                                          ),
                                          const SizedBox(
                                            width: double.infinity,
                                            height: 6,
                                          ),
                                          Text(
                                            startAt?.toLocal().jm ?? '12:00AM',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                          ),
                                        ],
                                      ),
                                      onPressed: () {
                                        _onStartTimeTapped(context, startAt);
                                      },
                                    );
                                  },
                                ),
                          ),

                          Row(
                            children: [
                              SizedBox(
                                width: 16,
                                child: Divider(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              const SizedBox(width: 6),
                              DurationText(
                                duration: state.endAt!.dateTime.difference(
                                  state.startAt!.dateTime,
                                ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 16,
                                child: Divider(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child:
                                BlocSelector<
                                  TaskNewCubit,
                                  TaskNewState,
                                  Jiffy?
                                >(
                                  selector: (state) => state.endAt,
                                  builder: (context, endAt) {
                                    return CupertinoButton(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            context.l10n.endTime,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.outline,
                                                ),
                                          ),
                                          const SizedBox(
                                            width: double.infinity,
                                            height: 6,
                                          ),
                                          Text(
                                            endAt?.toLocal().jm ?? '12:00PM',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                          ),
                                        ],
                                      ),
                                      onPressed: () {
                                        _onEndTimeTapped(context, state.endAt);
                                      },
                                    );
                                  },
                                ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                      Divider(
                        indent: 12,
                        endIndent: 12,
                        height: 24,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.l10n.allDay,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            BlocSelector<TaskNewCubit, TaskNewState, bool>(
                              selector: (state) => state.isAllDay,
                              builder: (context, isAllDay) {
                                return CupertinoSwitch(
                                  value: isAllDay,
                                  onChanged: (value) {
                                    context
                                        .read<TaskNewCubit>()
                                        .onIsAllDayChanged(
                                          isAllDay: value,
                                        );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        onPressed: () {
                          final isAllDay = context
                              .read<TaskNewCubit>()
                              .state
                              .isAllDay;
                          context.read<TaskNewCubit>().onIsAllDayChanged(
                            isAllDay: !isAllDay,
                          );
                        },
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
        SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  void _onDurationEnabledChanged(BuildContext context, bool value) {
    if (value) {
      final now = Jiffy.now();
      context.read<TaskNewCubit>().onStartAtChanged(now);
      context.read<TaskNewCubit>().onEndAtChanged(now.add(hours: 1));
    } else {
      context.read<TaskNewCubit>().onStartAtChanged(null);
      context.read<TaskNewCubit>().onEndAtChanged(null);

      /// 如果 duration 被禁用，则将焦点设置为标题
      FocusScope.of(context).requestFocus();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (context.mounted) {
          context.read<TaskNewCubit>().onFocusChanged(
            TaskNewFocus.title,
          );
        }
      });
    }
  }

  void _onStartTimeTapped(BuildContext context, Jiffy? startAt) {
    showCupertinoTimePicker(
      context,
      widgetRenderBox: context.findRenderObject() as RenderBox?,
      initialTime: TimeOfDay.fromDateTime(startAt!.toLocal().dateTime),
      onTimeChanged: (time) {
        context.read<TaskNewCubit>().onStartAtChanged(
          Jiffy.parseFromList([
            startAt.year,
            startAt.month,
            startAt.date,
            time.hour,
            time.minute,
          ]),
        );
      },
    );
  }

  void _onEndTimeTapped(BuildContext context, Jiffy? endAt) {
    showCupertinoTimePicker(
      context,
      widgetRenderBox: context.findRenderObject() as RenderBox?,
      initialTime: TimeOfDay.fromDateTime(endAt!.toLocal().dateTime),
      onTimeChanged: (time) {
        context.read<TaskNewCubit>().onEndAtChanged(
          Jiffy.parseFromList([
            endAt.year,
            endAt.month,
            endAt.date,
            time.hour,
            time.minute,
          ]),
        );
      },
    );
  }
}
