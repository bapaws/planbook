import 'package:flutter/material.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:table_calendar/table_calendar.dart';

class TaskWeekCalendarView extends StatelessWidget {
  const TaskWeekCalendarView({
    required this.date,
    required this.onDateSelected,
    super.key,
  });

  final Jiffy date;
  final ValueChanged<Jiffy> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TableCalendar<void>(
      focusedDay: date.dateTime,
      firstDay: DateTime.utc(1970),
      lastDay: DateTime.utc(2500, 12, 31),
      rowHeight: 36,
      headerVisible: false,
      rangeStartDay: date.startOf(Unit.week).dateTime,
      rangeEndDay: date.endOf(Unit.week).dateTime,
      startingDayOfWeek: switch (date.startOfWeek) {
        StartOfWeek.monday => StartingDayOfWeek.monday,
        StartOfWeek.saturday => StartingDayOfWeek.saturday,
        StartOfWeek.sunday => StartingDayOfWeek.sunday,
      },
      // selectedDayPredicate: (day) {
      //   return Jiffy.parseFromDateTime(day).isSame(
      //     Jiffy.now(),
      //     unit: Unit.week,
      //   );
      // },
      // sixWeekMonthsEnforced: true,
      weekNumbersVisible: true,
      onDaySelected: (selectedDay, focusedDay) {
        onDateSelected(Jiffy.parseFromDateTime(selectedDay).toLocal());
      },
      calendarStyle: CalendarStyle(
        cellMargin: EdgeInsets.zero,
        isTodayHighlighted: false,
        weekendTextStyle: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 12,
        ),
        weekNumberTextStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 12,
        ),
        todayTextStyle: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontSize: 12,
        ),
        defaultTextStyle: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 12,
        ),
        outsideTextStyle: TextStyle(
          color: theme.colorScheme.outlineVariant,
          fontSize: 12,
        ),
        selectedTextStyle: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontSize: 12,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        rangeStartTextStyle: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 12,
        ),
        rangeStartDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        rangeEndTextStyle: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 12,
        ),
        rangeEndDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        rangeHighlightColor: theme.colorScheme.primaryContainer,
        withinRangeTextStyle: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontSize: 12,
        ),
        // withinRangeDecoration: BoxDecoration(
        //   color: theme.colorScheme.primaryContainer,
        //   shape: BoxShape.circle,
        // ),
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}
