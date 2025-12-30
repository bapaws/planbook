import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_date_picker.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/duration/model/task_duration_entity.dart';
import 'package:jiffy/jiffy.dart';

enum TaskDurationSelectionMode {
  startAt,
  endAt,
  duration,
}

class TaskDurationView extends StatefulWidget {
  const TaskDurationView({
    required this.entity,
    required this.onValueChanged,
    super.key,
  });

  final TaskDurationEntity entity;
  final ValueChanged<TaskDurationEntity> onValueChanged;

  @override
  State<TaskDurationView> createState() => _TaskDurationViewState();
}

class _TaskDurationViewState extends State<TaskDurationView> {
  late bool _isAllDay = widget.entity.isAllDay;
  bool get isAllDay => _isAllDay;
  set isAllDay(bool value) {
    if (value == _isAllDay) return;
    setState(() {
      _isAllDay = value;
      if (value) {
        _startAt = _startAt.startOf(Unit.day);
        _endAt = _endAt.endOf(Unit.day);
      } else {
        final now = Jiffy.now().startOf(Unit.hour).add(hours: 1);
        _startAt = Jiffy.parseFromList([
          _startAt.year,
          _startAt.month,
          _startAt.date,
          now.hour,
          now.minute,
        ]);
        _endAt = _startAt.add(hours: 1);
      }
    });
    widget.onValueChanged(
      TaskDurationEntity(startAt: startAt, endAt: endAt, isAllDay: value),
    );
  }

  late Jiffy _startAt;
  Jiffy get startAt => _startAt;
  set startAt(Jiffy value) {
    if (value == _startAt) return;
    setState(() {
      if (_isAllDay) {
        _startAt = value.startOf(Unit.day);
      } else {
        _startAt = value;
      }
      if (_endAt.isBefore(value)) {
        if (isAllDay) {
          _endAt = value.endOf(Unit.day);
        } else {
          _endAt = value.add(hours: 1);
        }
      }
    });
    widget.onValueChanged(
      TaskDurationEntity(startAt: value, endAt: endAt, isAllDay: isAllDay),
    );
  }

  late Jiffy _endAt;
  Jiffy get endAt => _endAt;
  set endAt(Jiffy value) {
    if (value == _endAt) return;
    setState(() {
      if (_isAllDay) {
        _endAt = value.endOf(Unit.day);
      } else {
        _endAt = value;
      }
      if (_startAt.isAfter(value)) {
        if (isAllDay) {
          _startAt = value.startOf(Unit.day);
        } else {
          _startAt = value.subtract(hours: 1);
        }
      }
    });
    widget.onValueChanged(
      TaskDurationEntity(startAt: startAt, endAt: value, isAllDay: isAllDay),
    );
  }

  TaskDurationSelectionMode _previousSelectionMode =
      TaskDurationSelectionMode.startAt;
  TaskDurationSelectionMode _selectionMode = TaskDurationSelectionMode.startAt;
  TaskDurationSelectionMode get selectionMode => _selectionMode;
  set selectionMode(TaskDurationSelectionMode value) {
    if (value == _selectionMode) return;
    _previousSelectionMode = _selectionMode;
    setState(() {
      _selectionMode = value;
    });
  }

  @override
  void initState() {
    final now = Jiffy.now().startOf(Unit.minute);
    _startAt = widget.entity.startAt ?? now;
    _endAt = widget.entity.endAt ?? now.add(hours: 1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size.square(kToolbarHeight),
          onPressed: () {
            isAllDay = !isAllDay;
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.allDay,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              CupertinoSwitch(
                value: isAllDay,
                onChanged: (value) {
                  isAllDay = value;
                },
              ),
            ],
          ),
        ),
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: kToolbarHeight,
            ),
            Text(
              context.l10n.startTime,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            AppDatePicker(
              maximumDateTime: endAt.subtract(minutes: 1),
              mode: isAllDay
                  ? AppDatePickerMode.date
                  : AppDatePickerMode.dateTime,
              date: startAt,
              onDateChanged: (date) {
                startAt = date;
              },
            ),
            const SizedBox(
              width: 16,
              height: kToolbarHeight,
            ),
          ],
        ),
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: kToolbarHeight,
            ),
            Text(
              context.l10n.endTime,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            AppDatePicker(
              mode: isAllDay
                  ? AppDatePickerMode.date
                  : AppDatePickerMode.dateTime,
              minimumDateTime: startAt.add(minutes: 1),
              date: endAt,
              onDateChanged: (date) {
                endAt = date;
              },
            ),
            const SizedBox(
              width: 16,
              height: kToolbarHeight,
            ),
          ],
        ),
        SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  SizedBox buildDatePicker() {
    return SizedBox(
      key: ValueKey(selectionMode),
      height: 216,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        changeReportingBehavior: ChangeReportingBehavior.onScrollEnd,
        initialDateTime: selectionMode == TaskDurationSelectionMode.startAt
            ? startAt.toLocal().dateTime
            : endAt.toLocal().dateTime,
        minimumDate: selectionMode == TaskDurationSelectionMode.startAt
            ? null
            : startAt.toLocal().dateTime,
        maximumDate: selectionMode == TaskDurationSelectionMode.startAt
            ? endAt.toLocal().dateTime
            : null,
        onDateTimeChanged: (date) {
          final newDate = Jiffy.parseFromList([
            startAt.year,
            startAt.month,
            startAt.date,
            date.hour,
            date.minute,
          ]);
          if (selectionMode == TaskDurationSelectionMode.startAt) {
            startAt = newDate;
          } else if (selectionMode == TaskDurationSelectionMode.endAt) {
            endAt = newDate;
          }
        },
      ),
    );
  }

  SizedBox buildTimerPicker() {
    return SizedBox(
      height: 216,
      child: CupertinoTimerPicker(
        changeReportingBehavior: ChangeReportingBehavior.onScrollEnd,
        mode: CupertinoTimerPickerMode.hm,
        initialTimerDuration: endAt.dateTime.difference(
          startAt.dateTime,
        ),
        onTimerDurationChanged: (duration) {
          if (_previousSelectionMode == TaskDurationSelectionMode.startAt) {
            endAt = startAt.add(minutes: duration.inMinutes);
          } else if (_previousSelectionMode ==
              TaskDurationSelectionMode.endAt) {
            startAt = endAt.subtract(minutes: duration.inMinutes);
          }
        },
      ),
    );
  }
}
