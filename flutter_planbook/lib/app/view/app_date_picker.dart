import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:jiffy/jiffy.dart';

enum AppDatePickerMode {
  date,
  time,
  dateTime;

  bool get containsDate => this == date || this == dateTime;
  bool get containsTime => this == time || this == dateTime;
}

class AppDatePicker extends StatefulWidget {
  const AppDatePicker({
    this.date,
    this.minimumDateTime,
    this.maximumDateTime,
    this.onDateChanged,
    this.mode = AppDatePickerMode.dateTime,
    this.spacing = 8,
    this.dateColor,
    this.dateTextStyle,
    this.timeColor,
    this.timeTextStyle,
    super.key,
  });

  final Jiffy? date;
  final ValueChanged<Jiffy>? onDateChanged;
  final AppDatePickerMode mode;
  final double spacing;

  final Jiffy? minimumDateTime;
  final Jiffy? maximumDateTime;

  final Color? dateColor;
  final TextStyle? dateTextStyle;
  final Color? timeColor;
  final TextStyle? timeTextStyle;

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  late Jiffy _selectedDate;
  Jiffy get selectedDate => _selectedDate;
  set selectedDate(Jiffy value) {
    if (value == _selectedDate) return;
    setState(() {
      _selectedDate = value;
    });
  }

  late AppDatePickerMode _mode;
  AppDatePickerMode get mode => _mode;
  set mode(AppDatePickerMode value) {
    if (value == _mode) return;
    setState(() {
      _mode = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date ?? Jiffy.now();
    _mode = widget.mode;
  }

  @override
  void didUpdateWidget(covariant AppDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date && widget.date != null) {
      selectedDate = widget.date!;
    }
    if (oldWidget.mode != widget.mode) {
      mode = widget.mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: Durations.medium1,
          transitionBuilder: (child, animation) => SizeTransition(
            axis: Axis.horizontal,
            sizeFactor: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: mode.containsDate
              ? Builder(
                  builder: (context) {
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      color: widget.dateColor ?? colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () {
                        final renderBox =
                            context.findRenderObject() as RenderBox?;
                        showCupertinoCalendarPicker(
                          context,
                          widgetRenderBox: renderBox,
                          minimumDateTime:
                              widget.minimumDateTime?.dateTime ??
                              DateTime(1970),
                          initialDateTime: selectedDate.dateTime,
                          maximumDateTime:
                              widget.maximumDateTime?.dateTime ??
                              DateTime(2500, 12, 31),
                          mainColor: colorScheme.primary,
                          firstDayOfWeekIndex:
                              switch (selectedDate.startOfWeek) {
                                StartOfWeek.monday => DateTime.monday,
                                StartOfWeek.saturday => DateTime.saturday,
                                StartOfWeek.sunday => DateTime.sunday,
                              },
                          timeLabel: context.l10n.time,
                          onDateTimeChanged: (dateTime) {
                            widget.onDateChanged?.call(
                              Jiffy.parseFromList([
                                dateTime.year,
                                dateTime.month,
                                dateTime.day,
                                selectedDate.hour,
                                selectedDate.minute,
                              ]),
                            );
                          },
                        );
                      },
                      child: Text(
                        selectedDate.toLocal().yMMMd,
                        style:
                            widget.dateTextStyle ??
                            textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                      ),
                    );
                  },
                )
              : null,
        ),
        AnimatedSwitcher(
          duration: Durations.medium1,
          transitionBuilder: (child, animation) => SizeTransition(
            axis: Axis.horizontal,
            sizeFactor: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: mode.containsDate && mode.containsTime
              ? SizedBox(width: widget.spacing)
              : null,
        ),
        AnimatedSwitcher(
          duration: Durations.medium1,
          transitionBuilder: (child, animation) => SizeTransition(
            axis: Axis.horizontal,
            sizeFactor: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: mode.containsTime
              ? Builder(
                  builder: (context) {
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      color: widget.timeColor ?? colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () {
                        final renderBox =
                            context.findRenderObject() as RenderBox?;
                        showCupertinoTimePicker(
                          context,
                          widgetRenderBox: renderBox,
                          minimumTime: widget.minimumDateTime?.dateTime != null
                              ? TimeOfDay.fromDateTime(
                                  widget.minimumDateTime!.dateTime,
                                )
                              : null,
                          maximumTime: widget.maximumDateTime?.dateTime != null
                              ? TimeOfDay.fromDateTime(
                                  widget.maximumDateTime!.dateTime,
                                )
                              : null,
                          initialTime: TimeOfDay.fromDateTime(
                            selectedDate.dateTime,
                          ),
                          onTimeChanged: (time) {
                            widget.onDateChanged?.call(
                              Jiffy.parseFromList([
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.date,
                                time.hour,
                                time.minute,
                              ]),
                            );
                          },
                        );
                      },
                      child: Text(
                        selectedDate.toLocal().jm,
                        style:
                            widget.timeTextStyle ??
                            textTheme.titleMedium?.copyWith(
                              color: colorScheme.tertiary,
                            ),
                      ),
                    );
                  },
                )
              : null,
        ),
      ],
    );
  }
}
