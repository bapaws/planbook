import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:table_calendar/table_calendar.dart';

@RoutePage()
class TaskDatePickerPage extends StatelessWidget {
  const TaskDatePickerPage({
    required this.date,
    this.onDateChanged,
    super.key,
  });

  final Jiffy date;
  final ValueChanged<Jiffy?>? onDateChanged;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      borderRadius: BorderRadius.circular(16),
      constraints: BoxConstraints(
        maxHeight: 480 + MediaQuery.of(context).padding.bottom,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          AppBar(
            forceMaterialTransparency: true,
            leading: const NavigationBarCloseButton(),
            actions: [
              CupertinoButton(
                onPressed: () {
                  onDateChanged?.call(null);
                  context.router.maybePop(Jiffy.now());
                },
                child: Text(context.l10n.inbox),
              ),
            ],
          ),
          TableCalendar<DateTime>(
            firstDay: DateTime.utc(1970),
            lastDay: DateTime.utc(2500, 12, 31),
            focusedDay: date.dateTime,
            startingDayOfWeek: switch (date.startOfWeek) {
              StartOfWeek.monday => StartingDayOfWeek.monday,
              StartOfWeek.saturday => StartingDayOfWeek.saturday,
              StartOfWeek.sunday => StartingDayOfWeek.sunday,
            },
            headerStyle: const HeaderStyle(
              leftChevronMargin: EdgeInsets.zero,
              leftChevronPadding: EdgeInsets.fromLTRB(8, 12, 24, 12),
              rightChevronMargin: EdgeInsets.zero,
              rightChevronPadding: EdgeInsets.fromLTRB(24, 12, 8, 12),
            ),
            rangeSelectionMode: RangeSelectionMode.disabled,
            selectedDayPredicate: (day) {
              return date.isSame(
                Jiffy.parseFromDateTime(day),
                unit: Unit.day,
              );
            },
            calendarStyle: CalendarStyle(
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
            availableCalendarFormats: {
              CalendarFormat.week: context.l10n.today,
              CalendarFormat.month: context.l10n.today,
            },
            onDaySelected: (selectedDay, focusedDay) {
              final day = Jiffy.parseFromDateTime(selectedDay);
              onDateChanged?.call(day);
              context.router.maybePop(day);
            },
            onFormatChanged: (format) {
              final day = Jiffy.now();
              onDateChanged?.call(day);
              context.router.maybePop(day);
            },
          ),
        ],
      ),
    );
  }
}
