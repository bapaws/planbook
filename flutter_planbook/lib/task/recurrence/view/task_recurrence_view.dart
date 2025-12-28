import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/model/recurrence_frequency_x.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
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
    final now = Jiffy.now();
    _recurrenceRule =
        widget.initialRecurrenceRule ??
        RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          daysOfWeek: [
            RecurrenceDayOfWeek.day(
              Weekday.fromDateTimeWeekday(now.dateTime.weekday),
            ),
          ],
          daysOfMonth: [now.date],
          daysOfYear: [now.month * 100 + now.date],
        );
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
            RecurrenceFrequency.monthly => TaskNewRecurrenceRuleMonthlyView(
              recurrenceRule: _recurrenceRule,
              onDaysOfMonthChanged: (daysOfMonth) {
                recurrenceRule = recurrenceRule.copyWith(
                  daysOfMonth: daysOfMonth,
                );
              },
            ),
            RecurrenceFrequency.yearly => TaskNewRecurrenceRuleYearlyView(
              recurrenceRule: _recurrenceRule,
              onChanged: (daysOfYear) {
                recurrenceRule = recurrenceRule.copyWith(
                  daysOfYear: daysOfYear,
                );
              },
            ),
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
  const TaskNewRecurrenceRuleMonthlyView({
    required this.recurrenceRule,
    required this.onDaysOfMonthChanged,
    super.key,
  });

  final RecurrenceRule recurrenceRule;
  final ValueChanged<List<int>> onDaysOfMonthChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 288,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
        ),
        itemCount: 31,
        itemBuilder: (context, index) {
          final isSelected =
              recurrenceRule.daysOfMonth?.any(
                (day) => day == index + 1,
              ) ??
              false;
          return CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () {
              _onDayOfMonthButtonPressed(context, index + 1);
            },
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: AlignmentDirectional.center,
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onDayOfMonthButtonPressed(BuildContext context, int day) {
    final daysOfMonth = [...?recurrenceRule.daysOfMonth];
    final index = daysOfMonth.indexWhere((d) => d == day);
    if (index != -1) {
      daysOfMonth.removeAt(index);
      onDaysOfMonthChanged(daysOfMonth);
    } else {
      daysOfMonth.add(day);
      onDaysOfMonthChanged(daysOfMonth);
    }
  }
}

class TaskNewRecurrenceRuleYearlyView extends StatefulWidget {
  const TaskNewRecurrenceRuleYearlyView({
    required this.recurrenceRule,
    required this.onChanged,
    super.key,
  });

  final RecurrenceRule recurrenceRule;
  final void Function(List<int> daysOfYear) onChanged;

  @override
  State<TaskNewRecurrenceRuleYearlyView> createState() =>
      _TaskNewRecurrenceRuleYearlyViewState();
}

class _TaskNewRecurrenceRuleYearlyViewState
    extends State<TaskNewRecurrenceRuleYearlyView> {
  int _currentMonth = 1;

  final List<String> shortMonths = DateFormat().dateSymbols.SHORTMONTHS;

  List<int> _daysOfYear = [];

  @override
  void initState() {
    super.initState();

    final now = Jiffy.now();
    _currentMonth = now.month;

    _daysOfYear = [...?widget.recurrenceRule.daysOfYear];
  }

  @override
  void didUpdateWidget(covariant TaskNewRecurrenceRuleYearlyView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 288 + 44,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 16),
              Text(
                shortMonths[_currentMonth - 1],
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  FontAwesomeIcons.chevronLeft,
                  size: 16,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  setState(() {
                    _currentMonth = _currentMonth == 1 ? 12 : _currentMonth - 1;
                  });
                },
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  FontAwesomeIcons.chevronRight,
                  size: 16,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  setState(() {
                    _currentMonth = _currentMonth == 12 ? 1 : _currentMonth + 1;
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 31,
              itemBuilder: (context, index) {
                return _buildDayButton(_currentMonth, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayButton(int month, int day) {
    final theme = Theme.of(context);
    final isSelected = _isSelected(month, day);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () {
        _onDaySelected(month, day);
      },
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: AlignmentDirectional.center,
          child: Text(
            '$day',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }

  bool _isSelected(int month, int day) {
    final isSelected = widget.recurrenceRule.daysOfYear?.any(
      (d) => d == month * 100 + day,
    );
    return isSelected != null && isSelected;
  }

  void _onDaySelected(int month, int day) {
    final index = _daysOfYear.indexWhere((d) => d == month * 100 + day);
    if (index != -1) {
      _daysOfYear.removeAt(index);
    } else {
      _daysOfYear.add(month * 100 + day);
    }

    setState(() {});
    widget.onChanged(_daysOfYear);
  }
}
