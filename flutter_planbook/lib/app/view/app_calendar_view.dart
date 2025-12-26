import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:table_calendar/table_calendar.dart';

final firstDay = DateTime.utc(2020);
final lastDay = DateTime.utc(2050, 12, 31);

class AppCalendarDateView extends StatelessWidget {
  const AppCalendarDateView({
    required this.date,
    required this.calendarFormat,
    required this.onDateSelected,
    required this.onCalendarFormatChanged,
    super.key,
  });

  final Jiffy date;
  final CalendarFormat calendarFormat;
  final ValueChanged<Jiffy> onDateSelected;
  final ValueChanged<CalendarFormat> onCalendarFormatChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () {
            onDateSelected(Jiffy.now());
          },
          child: Text(
            _buildTimelineTitle(context, date),
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size.square(
            kMinInteractiveDimensionCupertino,
          ),
          onPressed: () {
            onCalendarFormatChanged(
              calendarFormat == CalendarFormat.week
                  ? CalendarFormat.month
                  : CalendarFormat.week,
            );
          },
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(
                kMinInteractiveDimension,
              ),
            ),
            child: AnimatedRotation(
              turns: calendarFormat == CalendarFormat.week ? 0 : 0.25,
              duration: Durations.medium1,
              child: Icon(
                FontAwesomeIcons.chevronRight,
                size: 12,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _buildTimelineTitle(BuildContext context, Jiffy date) {
    final now = Jiffy.now();
    if (date.isSame(now, unit: Unit.day)) {
      return '${date.MMM}, ${context.l10n.today}';
    }
    if (date.isSame(now.subtract(days: 1), unit: Unit.day)) {
      return '${date.MMM}, ${context.l10n.yesterday}';
    }
    if (date.isSame(now.add(days: 1), unit: Unit.day)) {
      return '${date.MMM}, ${context.l10n.tomorrow}';
    }
    return date.MMM;
  }
}

class AppCalendarView<T> extends StatelessWidget {
  AppCalendarView({
    required this.onDateSelected,
    Jiffy? date,
    this.calendarFormat = CalendarFormat.week,
    super.key,
    this.eventLoader,
  }) : date = date ?? Jiffy.now().toUtc();

  final Jiffy date;
  final CalendarFormat calendarFormat;

  final ValueChanged<Jiffy> onDateSelected;
  final List<T> Function(DateTime day)? eventLoader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TableCalendar<T>(
      firstDay: firstDay,
      lastDay: lastDay,
      focusedDay: date.dateTime,
      startingDayOfWeek: switch (date.startOfWeek) {
        StartOfWeek.monday => StartingDayOfWeek.monday,
        StartOfWeek.saturday => StartingDayOfWeek.saturday,
        StartOfWeek.sunday => StartingDayOfWeek.sunday,
      },
      headerVisible: false,
      headerStyle: const HeaderStyle(
        leftChevronVisible: false,
        rightChevronVisible: false,
        headerPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
      rangeSelectionMode: RangeSelectionMode.disabled,
      selectedDayPredicate: (day) {
        return date.isSame(
          Jiffy.parseFromDateTime(day),
          unit: Unit.day,
        );
      },
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
        weekendStyle: TextStyle(
          color: theme.colorScheme.outline,
          fontSize: 10,
        ),
      ),
      calendarStyle: CalendarStyle(
        // isTodayHighlighted: false,
        rangeHighlightColor: Colors.red,
        withinRangeTextStyle: TextStyle(
          color: theme.primaryColor,
        ),
        selectedTextStyle: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
        ),
        todayDecoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
          shape: BoxShape.circle,
        ),
      ),
      eventLoader: eventLoader,
      onDaySelected: (selectedDay, focusedDay) {
        onDateSelected(Jiffy.parseFromDateTime(selectedDay));
      },
      calendarFormat: calendarFormat,
    );
  }
}

// class AppCalendarView extends StatefulWidget {
//   AppCalendarView({
//     required this.child,
//     required this.onDateSelected,
//     Jiffy? date,
//     this.calendarFormat = CalendarFormat.week,
//     super.key,
//   }) : date = date ?? Jiffy.now();

//   final Widget child;
//   final Jiffy date;
//   final CalendarFormat calendarFormat;

//   final ValueChanged<Jiffy> onDateSelected;

//   @override
//   State<AppCalendarView> createState() => _AppCalendarViewState();
// }

// class _AppCalendarViewState extends State<AppCalendarView> {
//   late Jiffy _date;
//   late CalendarFormat _calendarFormat;
//   bool _canSwitchToMonth = true; // 是否可以在下拉时切换到 month

//   bool _handleScrollNotification(ScrollNotification notification) {
//     final offset = notification.metrics.pixels;
//     if (notification is ScrollEndNotification) {
//       _canSwitchToMonth = offset <= 0;
//     }
//     if (notification is ScrollUpdateNotification &&
//         notification.dragDetails != null) {
//       if (_canSwitchToMonth && _calendarFormat == CalendarFormat.week) {
//         if (offset <= 0 &&
//             notification.scrollDelta != null &&
//             notification.scrollDelta! < 0) {
//           setState(() {
//             _calendarFormat = CalendarFormat.month;
//           });
//           _canSwitchToMonth = false;
//           return false;
//         }
//       }

//       if (offset > 0 &&
//           notification.scrollDelta != null &&
//           notification.scrollDelta! > 0 &&
//           _calendarFormat == CalendarFormat.month) {
//         setState(() {
//           _calendarFormat = CalendarFormat.week;
//         });
//         return false;
//       }
//     }
//     return false;
//   }

//   @override
//   void initState() {
//     _date = widget.date;
//     _calendarFormat = widget.calendarFormat;
//     super.initState();
//   }

//   @override
//   void didUpdateWidget(covariant AppCalendarView oldWidget) {
//     if (oldWidget.date != widget.date) {
//       _date = widget.date;
//     }
//     if (oldWidget.calendarFormat != widget.calendarFormat) {
//       _calendarFormat = widget.calendarFormat;
//     }
//     super.didUpdateWidget(oldWidget);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         TableCalendar<DateTime>(
//           firstDay: firstDay,
//           lastDay: lastDay,
//           focusedDay: _date.dateTime,
//           headerVisible: false,
//           headerStyle: const HeaderStyle(
//             leftChevronVisible: false,
//             rightChevronVisible: false,
//             headerPadding: EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//           ),
//           rangeSelectionMode: RangeSelectionMode.disabled,
//           selectedDayPredicate: (day) {
//             return _date.isSame(
//               Jiffy.parseFromDateTime(day),
//               unit: Unit.day,
//             );
//           },
//           calendarStyle: CalendarStyle(
//             // isTodayHighlighted: false,
//             rangeHighlightColor: Colors.red,
//             withinRangeTextStyle: TextStyle(
//               color: Theme.of(context).primaryColor,
//             ),
//             selectedTextStyle: TextStyle(
//               color: Theme.of(context).colorScheme.onPrimaryContainer,
//             ),
//             selectedDecoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.primaryContainer,
//               shape: BoxShape.circle,
//             ),
//             todayTextStyle: TextStyle(
//               color: Theme.of(context).colorScheme.onPrimaryContainer,
//             ),
//             todayDecoration: BoxDecoration(
//               border: Border.all(
//                 color: Theme.of(context).colorScheme.outlineVariant,
//               ),
//               shape: BoxShape.circle,
//             ),
//           ),
//           onDaySelected: (selectedDay, focusedDay) {
//             setState(() {
//               _date = Jiffy.parseFromDateTime(selectedDay);
//             });
//             widget.onDateSelected(_date);
//           },
//           calendarFormat: _calendarFormat,
//         ),
//         Expanded(
//           child: NotificationListener<ScrollNotification>(
//             onNotification: _handleScrollNotification,
//             child: widget.child,
//           ),
//         ),
//       ],
//     );
//   }
// }
