import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/model/recurrence_frequency.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/recurrence_rule.dart';

class TaskRecurrenceView extends StatefulWidget {
  const TaskRecurrenceView({
    required this.onRecurrenceRuleChanged,
    this.taskDate,
    this.initialRecurrenceRule,
    super.key,
  });

  final Jiffy? taskDate;
  final RecurrenceRule? initialRecurrenceRule;
  final ValueChanged<RecurrenceRule?> onRecurrenceRuleChanged;

  @override
  State<TaskRecurrenceView> createState() => _TaskRecurrenceViewState();
}

class _TaskRecurrenceViewState extends State<TaskRecurrenceView> {
  RecurrenceFrequency get selectedFrequency => _recurrenceRule.frequency;

  late FixedExtentScrollController _everyScrollController;
  late FixedExtentScrollController _frequencyScrollController;

  late RecurrenceRule _recurrenceRule;
  RecurrenceRule get recurrenceRule => _recurrenceRule;
  set recurrenceRule(RecurrenceRule value) {
    if (value == _recurrenceRule) return;
    setState(() {
      _recurrenceRule = value;
    });
    widget.onRecurrenceRuleChanged(value);
  }

  @override
  void initState() {
    super.initState();
    _recurrenceRule =
        widget.initialRecurrenceRule ??
        const RecurrenceRule(frequency: RecurrenceFrequency.daily);
    _everyScrollController = FixedExtentScrollController(
      initialItem: widget.initialRecurrenceRule?.interval ?? 1,
    );
    _frequencyScrollController = FixedExtentScrollController(
      initialItem: widget.initialRecurrenceRule?.frequency.index ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final recurrenceEnd = _recurrenceRule.recurrenceEnd;
    var title = context.l10n.endlessly;
    if (recurrenceEnd?.endAt != null) {
      title = context.l10n.endsOn(recurrenceEnd?.endAt?.yMMMd ?? '');
    }
    if (recurrenceEnd?.occurrenceCount != null) {
      title = context.l10n.endsIn(recurrenceEnd?.occurrenceCount ?? 2);
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: (screenWidth * 0.2).floorToDouble(),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  context.l10n.every,
                  style: theme.textTheme.titleLarge?.copyWith(
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
                onSelectedItemChanged: (index) {
                  recurrenceRule = recurrenceRule.copyWith(
                    interval: index,
                  );
                },
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
                scrollController: _frequencyScrollController,
                changeReportingBehavior: ChangeReportingBehavior.onScrollEnd,
                onSelectedItemChanged: (index) {
                  recurrenceRule = recurrenceRule.copyWith(
                    frequency: RecurrenceFrequency.values[index],
                  );
                },
                selectionOverlay: null,
                children: [
                  for (final frequency in RecurrenceFrequency.values)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        frequency.getEveryUnitName(
                          context.l10n,
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: Durations.medium1,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
          child: switch (selectedFrequency) {
            RecurrenceFrequency.daily => const SizedBox.shrink(),
            RecurrenceFrequency.weekly => TaskNewRecurrenceRuleWeeklyView(
              recurrenceRule: _recurrenceRule,
              onDaysOfWeekChanged: (daysOfWeek) {
                recurrenceRule = recurrenceRule.copyWith(
                  daysOfWeek: daysOfWeek,
                );
              },
            ),
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
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: recurrenceEnd == null
                      ? theme.colorScheme.outline
                      : theme.colorScheme.primary,
                ),
              ),
              const CupertinoListTileChevron(),
            ],
          ),
          onPressed: () {
            context.router.push(
              TaskNewRecurrenceEndAtRoute(
                initialRecurrenceEnd: _recurrenceRule.recurrenceEnd,
                minimumDateTime: widget.taskDate,
                onRecurrenceEndChanged: (RecurrenceEnd? value) {
                  recurrenceRule = recurrenceRule.copyWith(
                    recurrenceEnd: () => value,
                  );
                },
              ),
            );
          },
        ),
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
    required this.recurrenceRule,
    required this.onDaysOfWeekChanged,
    super.key,
  });

  final RecurrenceRule recurrenceRule;
  final ValueChanged<List<RecurrenceDayOfWeek>> onDaysOfWeekChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = Jiffy.now().startOf(Unit.week);
    final buttons = <Widget>[];
    for (var i = 0; i < 7; i++) {
      final date = now.add(days: i);
      final isSelected =
          recurrenceRule.daysOfWeek?.any(
            (day) =>
                day.dayOfTheWeek ==
                Weekday.fromDateTimeWeekday(date.dateTime.weekday),
          ) ??
          false;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: buttons,
      ),
    );
  }

  void _onDayOfWeekButtonPressed(BuildContext context, Jiffy date) {
    final daysOfWeek = [...?recurrenceRule.daysOfWeek];
    final index = daysOfWeek.indexWhere(
      (day) =>
          day.dayOfTheWeek ==
          Weekday.fromDateTimeWeekday(date.dateTime.weekday),
    );
    if (index != -1) {
      daysOfWeek.removeAt(index);
      onDaysOfWeekChanged(daysOfWeek);
    } else {
      daysOfWeek.add(
        RecurrenceDayOfWeek.day(
          Weekday.fromDateTimeWeekday(date.dateTime.weekday),
        ),
      );
      onDaysOfWeekChanged(daysOfWeek);
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
