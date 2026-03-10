import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';

class DiscoverJournalDateChangeView extends StatelessWidget {
  const DiscoverJournalDateChangeView({
    required this.date,
    this.onDateChanged,
    super.key,
  });

  final Jiffy date;
  final ValueChanged<Jiffy>? onDateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CupertinoButton(
          minimumSize: const Size.square(kMinInteractiveDimension),
          onPressed: () {
            onDateChanged?.call(date.subtract(days: 1));
          },
          child: Icon(
            FontAwesomeIcons.chevronLeft,
            size: 14,
            color: theme.colorScheme.surfaceContainerLowest,
            shadows: [
              BoxShadow(
                color: theme.colorScheme.onSurface,
                blurRadius: 3,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        CupertinoButton(
          minimumSize: const Size(72, kMinInteractiveDimension),
          onPressed: () {
            final renderBox = context.findRenderObject() as RenderBox?;
            showCupertinoCalendarPicker(
              context,
              widgetRenderBox: renderBox,
              minimumDateTime: DateTime(1970),
              initialDateTime: date.dateTime,
              maximumDateTime: DateTime(2500, 12, 31),
              mainColor: theme.colorScheme.primary,
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
            date.toLocal().MMMd,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        CupertinoButton(
          minimumSize: const Size.square(kMinInteractiveDimension),
          onPressed: () {
            onDateChanged?.call(date.add(days: 1));
          },
          child: Icon(
            FontAwesomeIcons.chevronRight,
            size: 14,
            color: theme.colorScheme.surfaceContainerLowest,
            shadows: [
              BoxShadow(
                color: theme.colorScheme.onSurface,
                blurRadius: 3,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
