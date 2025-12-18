import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/duration/model/task_duration_entity.dart';
import 'package:flutter_planbook/task/new/view/duration_text.dart';
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
    });
    widget.onValueChanged(widget.entity.copyWith(isAllDay: value));
  }

  late Jiffy _startAt;
  Jiffy get startAt => _startAt;
  set startAt(Jiffy value) {
    if (value == _startAt) return;
    setState(() {
      _startAt = value;
    });
    widget.onValueChanged(widget.entity.copyWith(startAt: value));
  }

  late Jiffy _endAt;
  Jiffy get endAt => _endAt;
  set endAt(Jiffy value) {
    if (value == _endAt) return;
    setState(() {
      _endAt = value;
    });
    widget.onValueChanged(widget.entity.copyWith(endAt: value));
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
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (context) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.square(kToolbarHeight),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: Durations.medium1,
                          transitionBuilder: (child, animation) =>
                              SizeTransition(
                                axis: Axis.horizontal,
                                sizeFactor: animation,
                                child: child,
                              ),
                          child:
                              selectionMode == TaskDurationSelectionMode.startAt
                              ? Container(
                                  width: 4,
                                  height: kMinInteractiveDimension,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.l10n.startTime,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              Text(
                                startAt.toLocal().jm,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      // _onStartTimeTapped(context);
                      selectionMode = TaskDurationSelectionMode.startAt;
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Divider(
                    color: selectionMode == TaskDurationSelectionMode.duration
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(width: 6),
                DurationText(
                  duration: endAt.dateTime.difference(
                    startAt.dateTime,
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selectionMode == TaskDurationSelectionMode.duration
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline,
                    fontWeight:
                        selectionMode == TaskDurationSelectionMode.duration
                        ? FontWeight.bold
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 16,
                  child: Divider(
                    color: selectionMode == TaskDurationSelectionMode.duration
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.square(kMinInteractiveDimension),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.l10n.endTime,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              Text(
                                endAt.toLocal().jm,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: Durations.medium1,
                          transitionBuilder: (child, animation) =>
                              SizeTransition(
                                axis: Axis.horizontal,
                                sizeFactor: animation,
                                child: child,
                              ),
                          child:
                              selectionMode == TaskDurationSelectionMode.endAt
                              ? Container(
                                  width: 4,
                                  height: kMinInteractiveDimension,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                    onPressed: () {
                      // _onEndTimeTapped(context);
                      selectionMode = TaskDurationSelectionMode.endAt;
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        AnimatedSwitcher(
          duration: Durations.medium1,
          child: buildDatePicker(),
        ),
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
