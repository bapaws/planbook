import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:jiffy/jiffy.dart';

class DiscoverJournalDateView extends StatelessWidget {
  const DiscoverJournalDateView({
    required this.date,
    this.onDateChanged,
    super.key,
  });

  final Jiffy date;
  final ValueChanged<Jiffy>? onDateChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      minimumSize: Size.zero,
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(8),
      onPressed: () {
        final renderBox = context.findRenderObject() as RenderBox?;
        showCupertinoCalendarPicker(
          context,
          widgetRenderBox: renderBox,
          minimumDateTime: DateTime(1970),
          initialDateTime: date.dateTime,
          maximumDateTime: DateTime(2500, 12, 31),
          mainColor: colorScheme.primary,
          firstDayOfWeekIndex: switch (date.startOfWeek) {
            StartOfWeek.monday => DateTime.monday,
            StartOfWeek.saturday => DateTime.saturday,
            StartOfWeek.sunday => DateTime.sunday,
          },
          timeLabel: context.l10n.time,
          dismissBehavior: CalendarDismissBehavior.onOusideTapOrDateSelect,
          onDateSelected: (date) {
            onDateChanged?.call(
              Jiffy.parseFromDateTime(date),
            );
          },
        );
      },
      child: Text(
        date.toLocal().yMMMd,
        style: textTheme.titleMedium?.copyWith(
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
