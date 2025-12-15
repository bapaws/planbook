import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/recurrence_rule.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:table_calendar/table_calendar.dart';

enum RecurrenceEndType {
  endAt,
  occurrenceCount,
}

@RoutePage()
class TaskNewRecurrenceEndAtPage extends StatefulWidget {
  const TaskNewRecurrenceEndAtPage({
    required this.minimumDateTime,
    required this.initialRecurrenceEnd,
    required this.onRecurrenceEndChanged,
    super.key,
  });

  final Jiffy? minimumDateTime;
  final RecurrenceEnd? initialRecurrenceEnd;

  final ValueChanged<RecurrenceEnd?> onRecurrenceEndChanged;

  @override
  State<TaskNewRecurrenceEndAtPage> createState() =>
      _TaskNewRecurrenceEndAtPageState();
}

class _TaskNewRecurrenceEndAtPageState
    extends State<TaskNewRecurrenceEndAtPage> {
  Jiffy get minimumDateTime => widget.minimumDateTime ?? Jiffy.now();
  Jiffy get maximumDateTime => minimumDateTime.add(years: 100);

  late RecurrenceEndType _recurrenceEndType = RecurrenceEndType.endAt;

  late Jiffy _focusedDate = minimumDateTime;
  Jiffy? _selectedDate;
  late int _occurrenceCount = 2;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecurrenceEnd != null) {
      _recurrenceEndType = widget.initialRecurrenceEnd!.endAt != null
          ? RecurrenceEndType.endAt
          : RecurrenceEndType.occurrenceCount;
    }
    if (widget.initialRecurrenceEnd?.endAt != null) {
      _selectedDate = _focusedDate = widget.initialRecurrenceEnd!.endAt!;
    }
    if (widget.initialRecurrenceEnd?.occurrenceCount != null) {
      _occurrenceCount = widget.initialRecurrenceEnd!.occurrenceCount!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return AppPageScaffold(
      borderRadius: BorderRadius.circular(16),
      constraints: BoxConstraints(
        maxHeight:
            switch (_recurrenceEndType) {
              RecurrenceEndType.endAt =>
                kMinInteractiveDimension + 12 + 328 + kMinInteractiveDimension,
              RecurrenceEndType.occurrenceCount =>
                kMinInteractiveDimension + 12 + 216,
            } +
            16 +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          AppBar(
            leading: const NavigationBarBackButton(),
            actions: [
              CupertinoButton(
                onPressed: () {
                  widget.onRecurrenceEndChanged(null);
                  context.pop();
                },
                child: Text(
                  context.l10n.endlessly,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
            title: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / 2;
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Row(
                      children: [
                        _buildItem(context, RecurrenceEndType.endAt),
                        _buildItem(
                          context,
                          RecurrenceEndType.occurrenceCount,
                        ),
                      ],
                    ),
                    AnimatedPositioned(
                      duration: Durations.medium1,
                      bottom: 0,
                      left:
                          itemWidth * _recurrenceEndType.index +
                          (itemWidth - 24) / 2,
                      child: Container(
                        height: 4,
                        width: 24,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: Durations.medium1,
            child: switch (_recurrenceEndType) {
              RecurrenceEndType.endAt => TableCalendar<void>(
                firstDay: minimumDateTime.dateTime,
                lastDay: maximumDateTime.dateTime,
                focusedDay: _focusedDate.dateTime,
                startingDayOfWeek: switch (minimumDateTime.startOfWeek) {
                  StartOfWeek.monday => StartingDayOfWeek.monday,
                  StartOfWeek.saturday => StartingDayOfWeek.saturday,
                  StartOfWeek.sunday => StartingDayOfWeek.sunday,
                },
                // headerVisible: false,
                headerStyle: const HeaderStyle(
                  // leftChevronVisible: false,
                  // rightChevronVisible: false,
                  // titleCentered: true,
                  leftChevronMargin: EdgeInsets.zero,
                  rightChevronMargin: EdgeInsets.zero,
                  // headerPadding: EdgeInsets.symmetric(
                  //   horizontal: 12,
                  //   vertical: 8,
                  // ),
                ),
                rangeSelectionMode: RangeSelectionMode.disabled,
                calendarStyle: CalendarStyle(
                  // isTodayHighlighted: false,
                  rangeHighlightColor: Colors.red,
                  withinRangeTextStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                  selectedTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  todayDecoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                selectedDayPredicate: (day) {
                  return _selectedDate?.isSame(
                        Jiffy.parseFromDateTime(day),
                        unit: Unit.day,
                      ) ??
                      false;
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = _focusedDate = Jiffy.parseFromDateTime(
                      selectedDay,
                    );
                  });
                  widget.onRecurrenceEndChanged(
                    RecurrenceEnd.fromEndAt(_selectedDate!),
                  );
                },
                availableCalendarFormats: {
                  CalendarFormat.week: context.l10n.today,
                  CalendarFormat.month: context.l10n.today,
                },
                onFormatChanged: (format) {
                  setState(() {
                    _focusedDate = Jiffy.now();
                  });
                },
              ),
              RecurrenceEndType.occurrenceCount => SizedBox(
                // width: 160,
                height: 216,
                child: CupertinoPicker.builder(
                  scrollController: FixedExtentScrollController(
                    initialItem: _occurrenceCount,
                  ),
                  itemExtent: kMinInteractiveDimension,
                  changeReportingBehavior: ChangeReportingBehavior.onScrollEnd,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _occurrenceCount = index;
                    });
                    widget.onRecurrenceEndChanged(
                      RecurrenceEnd.fromOccurrenceCount(_occurrenceCount),
                    );
                  },
                  itemBuilder: (context, index) {
                    if (index < 2) return null;
                    return Center(child: Text((index).toString()));
                  },
                ),
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, RecurrenceEndType type) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          setState(() {
            _recurrenceEndType = type;
          });
        },
        child: AnimatedDefaultTextStyle(
          duration: Durations.medium1,
          style: textTheme.titleMedium!.copyWith(
            color: type == _recurrenceEndType
                ? colorScheme.onSurface
                : Colors.grey[400]!,
            fontWeight: type == _recurrenceEndType
                ? FontWeight.bold
                : FontWeight.normal,
          ),
          child: Text(
            _getTitle(context, type),
          ),
        ),
      ),
    );
  }

  String _getTitle(BuildContext context, RecurrenceEndType type) {
    final l10n = context.l10n;
    return switch (type) {
      RecurrenceEndType.endAt => l10n.endByDate,
      RecurrenceEndType.occurrenceCount => l10n.endByCount,
    };
  }
}
