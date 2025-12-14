import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/model/recurrence_frequency.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/new/cubit/task_new_cubit.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/recurrence_rule.dart';

class TaskNewRecurrenceRuleView extends StatefulWidget {
  const TaskNewRecurrenceRuleView({
    required this.initialRecurrenceRule,
    super.key,
  });

  final RecurrenceRule? initialRecurrenceRule;

  @override
  State<TaskNewRecurrenceRuleView> createState() =>
      _TaskNewRecurrenceRuleViewState();
}

class _TaskNewRecurrenceRuleViewState extends State<TaskNewRecurrenceRuleView> {
  RecurrenceFrequency _selectedFrequency = RecurrenceFrequency.daily;

  RecurrenceFrequency get selectedFrequency => _selectedFrequency;
  set selectedFrequency(RecurrenceFrequency value) {
    if (value == _selectedFrequency) return;
    setState(() {
      _selectedFrequency = value;
    });
  }

  int get selectedFrequencyIndex => _selectedFrequency.index;

  late FixedExtentScrollController _everyScrollController;
  late FixedExtentScrollController _frequencyScrollController;

  @override
  void initState() {
    super.initState();
    _everyScrollController = FixedExtentScrollController(
      initialItem: widget.initialRecurrenceRule?.interval ?? 1,
    );
    _frequencyScrollController = FixedExtentScrollController(
      initialItem: widget.initialRecurrenceRule?.frequency.index ?? 0,
    );
  }

  void _onRepeatEnabledChanged(BuildContext context, bool value) {
    final bloc = context.read<TaskNewCubit>();
    if (value) {
      const recurrenceRule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
      );
      bloc.onRecurrenceRuleChanged(recurrenceRule);
    } else {
      bloc.onRecurrenceRuleChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 12),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          onPressed: () {
            _onRepeatEnabledChanged(
              context,
              context.read<TaskNewCubit>().state.recurrenceRule == null,
            );
          },
          child: Row(
            children: [
              Text(
                context.l10n.repeat,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              BlocSelector<TaskNewCubit, TaskNewState, bool>(
                selector: (state) => state.recurrenceRule != null,
                builder: (context, enabled) {
                  return CupertinoSwitch(
                    value: enabled,
                    onChanged: (value) {
                      _onRepeatEnabledChanged(context, value);
                    },
                  );
                },
              ),
            ],
          ),
        ),
        BlocSelector<TaskNewCubit, TaskNewState, RecurrenceRule?>(
          selector: (state) => state.recurrenceRule,
          builder: (context, recurrenceRule) {
            return AnimatedSwitcher(
              duration: Durations.medium1,
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              ),
              child: recurrenceRule == null
                  ? null
                  : Column(
                      children: [
                        Divider(
                          indent: 12,
                          endIndent: 12,
                          height: 24,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final screenWidth = constraints.maxWidth;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: (screenWidth * 0.2).floorToDouble(),
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: Text(
                                      context.l10n.every,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: (screenWidth * 0.05).floorToDouble(),
                                ),
                                SizedBox(
                                  width: (screenWidth * 0.45).roundToDouble(),
                                  height: 216,
                                  child: CupertinoPicker.builder(
                                    itemExtent: kMinInteractiveDimension,
                                    scrollController: _everyScrollController,
                                    onSelectedItemChanged: (index) {},
                                    itemBuilder: (context, index) {
                                      if (index < 1) return null;
                                      return Center(
                                        child: Text((index).toString()),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: (screenWidth * 0.05).floorToDouble(),
                                ),
                                SizedBox(
                                  width: (screenWidth * 0.25).floorToDouble(),
                                  height: 216,
                                  child: CupertinoPicker(
                                    itemExtent: kMinInteractiveDimension,
                                    scrollController:
                                        _frequencyScrollController,
                                    changeReportingBehavior:
                                        ChangeReportingBehavior.onScrollEnd,
                                    onSelectedItemChanged: (index) {
                                      selectedFrequency =
                                          RecurrenceFrequency.values[index];
                                    },
                                    selectionOverlay: null,
                                    children: [
                                      for (final frequency
                                          in RecurrenceFrequency.values)
                                        Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: Text(
                                            frequency.getEveryUnitName(
                                              context.l10n,
                                            ),
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        AnimatedSwitcher(
                          duration: Durations.medium1,
                          transitionBuilder: (child, animation) =>
                              SizeTransition(
                                sizeFactor: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                          child: switch (selectedFrequency) {
                            RecurrenceFrequency.daily =>
                              const SizedBox.shrink(),
                            RecurrenceFrequency.weekly =>
                              const TaskNewRecurrenceRuleWeeklyView(),
                            RecurrenceFrequency.monthly =>
                              const TaskNewRecurrenceRuleMonthlyView(),
                            RecurrenceFrequency.yearly =>
                              const TaskNewRecurrenceRuleYearlyView(),
                          },
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
                            children: [
                              Text(
                                context.l10n.ends,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              BlocSelector<
                                TaskNewCubit,
                                TaskNewState,
                                RecurrenceEnd?
                              >(
                                selector: (state) =>
                                    state.recurrenceRule?.recurrenceEnd,
                                builder: (context, recurrenceEnd) {
                                  var title = context.l10n.endlessly;
                                  if (recurrenceEnd?.endAt != null) {
                                    title = context.l10n.endsOn(
                                      recurrenceEnd?.endAt?.yMMMd ?? '',
                                    );
                                  }
                                  if (recurrenceEnd?.occurrenceCount != null) {
                                    title = context.l10n.endsIn(
                                      recurrenceEnd?.occurrenceCount ?? 2,
                                    );
                                  }
                                  return Text(
                                    title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: recurrenceEnd == null
                                          ? theme.colorScheme.outline
                                          : theme.colorScheme.primary,
                                    ),
                                  );
                                },
                              ),
                              const CupertinoListTileChevron(),
                            ],
                          ),
                          onPressed: () {
                            context.router.push(
                              TaskNewRecurrenceEndAtRoute(
                                initialRecurrenceEnd: context
                                    .read<TaskNewCubit>()
                                    .state
                                    .recurrenceRule
                                    ?.recurrenceEnd,
                                minimumDateTime: context
                                    .read<TaskNewCubit>()
                                    .state
                                    .date,
                                onRecurrenceEndChanged: (RecurrenceEnd? value) {
                                  final recurrenceRule = context
                                      .read<TaskNewCubit>()
                                      .state
                                      .recurrenceRule;
                                  context
                                      .read<TaskNewCubit>()
                                      .onRecurrenceRuleChanged(
                                        recurrenceRule?.copyWith(
                                          recurrenceEnd: () => value,
                                        ),
                                      );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            );
          },
        ),
        SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

class TaskNewRecurrenceRuleDailyView extends StatelessWidget {
  const TaskNewRecurrenceRuleDailyView({
    required this.onDaysChanged,
    super.key,
  });

  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 216,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Every',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 160,
            height: 216,
            child: CupertinoPicker.builder(
              itemExtent: kMinInteractiveDimension,
              onSelectedItemChanged: onDaysChanged,
              itemBuilder: (context, index) {
                if (index < 1) return null;
                return Center(child: Text((index).toString()));
              },
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Day',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class TaskNewRecurrenceRuleWeeklyView extends StatelessWidget {
  const TaskNewRecurrenceRuleWeeklyView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = Jiffy.now().startOf(Unit.week);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child:
          BlocSelector<TaskNewCubit, TaskNewState, List<RecurrenceDayOfWeek>>(
            selector: (state) => state.recurrenceRule?.daysOfWeek ?? [],
            builder: (context, daysOfWeek) {
              final buttons = <Widget>[];
              for (var i = 0; i < 7; i++) {
                final date = now.add(days: i);
                final isSelected = daysOfWeek.any(
                  (day) =>
                      day.dayOfTheWeek ==
                      Weekday.fromDateTimeWeekday(date.dateTime.weekday),
                );
                buttons.add(
                  CupertinoButton(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    child: Text(
                      date.E,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    onPressed: () {
                      _onDayOfWeekButtonPressed(context, date);
                    },
                  ),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: buttons,
              );
            },
          ),
    );
  }

  void _onDayOfWeekButtonPressed(BuildContext context, Jiffy date) {
    final recurrenceRule =
        context.read<TaskNewCubit>().state.recurrenceRule ??
        const RecurrenceRule(frequency: RecurrenceFrequency.weekly);
    final daysOfWeek = [...?recurrenceRule.daysOfWeek];
    final index = daysOfWeek.indexWhere(
      (day) =>
          day.dayOfTheWeek ==
          Weekday.fromDateTimeWeekday(date.dateTime.weekday),
    );
    if (index != -1) {
      daysOfWeek.removeAt(index);
      context.read<TaskNewCubit>().onRecurrenceRuleChanged(
        recurrenceRule.copyWith(daysOfWeek: daysOfWeek),
      );
    } else {
      daysOfWeek.add(
        RecurrenceDayOfWeek.day(
          Weekday.fromDateTimeWeekday(date.dateTime.weekday),
        ),
      );
      context.read<TaskNewCubit>().onRecurrenceRuleChanged(
        recurrenceRule.copyWith(daysOfWeek: daysOfWeek),
      );
    }
  }
}

class TaskNewRecurrenceRuleMonthlyView extends StatelessWidget {
  const TaskNewRecurrenceRuleMonthlyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class TaskNewRecurrenceRuleYearlyView extends StatelessWidget {
  const TaskNewRecurrenceRuleYearlyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
