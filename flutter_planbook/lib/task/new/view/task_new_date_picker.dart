import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/task/new/cubit/task_new_cubit.dart';
import 'package:intl/intl.dart';
import 'package:planbook_repository/planbook_repository.dart';

class TaskNewDatePicker extends StatelessWidget {
  const TaskNewDatePicker({this.date, this.onDateChanged, super.key});

  final Jiffy? date;
  final ValueChanged<Jiffy?>? onDateChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final now = Jiffy.now();
    final startOfWeek = now.startOf(Unit.week);

    return SizedBox(
      height: 360 + MediaQuery.of(context).padding.bottom,
      child: CalendarDatePicker2(
        config: CalendarDatePicker2Config(
          calendarType: CalendarDatePicker2Type.single,
          firstDayOfWeek: startOfWeek.dateTime.weekday,
          // calendarViewMode: CalendarDatePicker2Mode.monthYear,
          dayTextStyle: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          selectedDayTextStyle: textTheme.bodyLarge?.copyWith(
            color: colorScheme.surface,
          ),
          selectedDayHighlightColor: colorScheme.onSurface,
          selectedRangeHighlightColor: colorScheme.onSurface,
          disabledDayTextStyle: textTheme.bodyLarge?.copyWith(
            color: Colors.grey[400],
          ),
          weekdayLabels: DateFormat().dateSymbols.SHORTWEEKDAYS,
          weekdayLabelTextStyle: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          // centerAlignModePicker: true,
          disableModePicker: false,
          controlsTextStyle: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          animateToDisplayedMonthDate: false,
          customModePickerIcon: const SizedBox.shrink(),
          hideYearPickerDividers: true,
          useAbbrLabelForMonthModePicker: true,
        ),
        value: [date?.dateTime ?? DateTime.now()],
        onValueChanged: (dates) {
          context.read<TaskNewCubit>().onDueAtChanged(
            Jiffy.parseFromDateTime(dates.first),
          );
          context.read<TaskNewCubit>().onFocusChanged(TaskNewFocus.title);
          FocusScope.of(context).requestFocus();
        },
      ),
    );
  }
}
