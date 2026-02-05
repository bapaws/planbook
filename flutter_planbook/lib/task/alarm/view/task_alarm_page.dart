import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/alarm/view/task_alarm_wrap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class TaskAlarmPage extends StatefulWidget {
  const TaskAlarmPage({
    required this.taskStartAt,
    this.initialAlarms,
    this.isAllDay = false,
    super.key,
  });

  final Jiffy taskStartAt;
  final List<EventAlarm>? initialAlarms;
  final bool isAllDay;

  @override
  State<TaskAlarmPage> createState() => _TaskAlarmPageState();
}

class _TaskAlarmPageState extends State<TaskAlarmPage> {
  Unit _unit = Unit.day;
  int _offset = 0;
  DateTime? _time;

  late List<EventAlarm> _alarms;

  @override
  void initState() {
    super.initState();

    _time = DateTime.now();
    _alarms = List<EventAlarm>.from(widget.initialAlarms ?? <EventAlarm>[]);
  }

  bool get isValid {
    final alarm = EventAlarm.scheduled(
      dayOffset: _unit == Unit.day ? _offset : null,
      weekOffset: _unit == Unit.week ? _offset : null,
      hour: _time?.hour ?? 9,
      minute: _time?.minute ?? 0,
    );
    final triggerTime = alarm.resolveTriggerTime(
      widget.taskStartAt,
      isAllDay: widget.isAllDay,
    );
    return triggerTime != null && triggerTime.isAfter(Jiffy.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPageScaffold(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.vertical,
      ),
      child: SingleChildScrollView(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              AppBar(
                centerTitle: false,
                leadingWidth: 120,
                leading: CupertinoButton(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size.square(kMinInteractiveDimension),
                  onPressed: () {
                    context.router.pop(const <EventAlarm>[]);
                  },
                  child: Text(context.l10n.noAlarm),
                ),
                actions: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size.square(kMinInteractiveDimension),
                    onPressed: _alarms.isEmpty
                        ? null
                        : () {
                            context.router.maybePop(_alarms);
                          },
                    child: const Icon(FontAwesomeIcons.check),
                  ),
                ],
              ),
              TaskAlarmWrap(
                alarms: _alarms,
                onAlarmsChanged: (alarms) {
                  setState(() {
                    _alarms
                      ..clear()
                      ..addAll(alarms);
                  });
                },
              ),
              SizedBox(
                height: 216,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    // const Icon(
                    //   FontAwesomeIcons.caretRight,
                    //   size: 16,
                    // ),
                    Expanded(
                      child: CupertinoPicker.builder(
                        itemExtent: 32,
                        changeReportingBehavior:
                            ChangeReportingBehavior.onScrollEnd,
                        selectionOverlay:
                            const CupertinoPickerDefaultSelectionOverlay(
                              capEndEdge: false,
                            ),
                        squeeze: 1.25,
                        magnification: 2.35 / 2.1,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _unit = index == 0 ? Unit.day : Unit.week;
                          });
                        },
                        childCount: 2,
                        itemBuilder: (context, index) {
                          return Row(
                            children: [
                              const Spacer(flex: 3),
                              Text(
                                index == 0
                                    ? context.l10n.day
                                    : context.l10n.week,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                            ],
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: CupertinoPicker.builder(
                        itemExtent: 32,
                        changeReportingBehavior:
                            ChangeReportingBehavior.onScrollEnd,
                        selectionOverlay:
                            const CupertinoPickerDefaultSelectionOverlay(
                              capEndEdge: false,
                              capStartEdge: false,
                            ),
                        squeeze: 1.25,
                        magnification: 2.35 / 2.1,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _offset = -index;
                          });
                        },
                        childCount: switch (_unit) {
                          Unit.day => 61,
                          Unit.week => 13,
                          _ => 0,
                        },
                        itemBuilder: (context, index) {
                          final text = index == 0
                              ? context.l10n.onTheDay
                              : switch (_unit) {
                                  Unit.day => context.l10n.dayEarly(index),
                                  Unit.week => context.l10n.weekEarly(
                                    index,
                                  ),
                                  _ => '',
                                };
                          return Center(
                            child: Text(
                              text,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: CupertinoDatePicker(
                        initialDateTime: _time,
                        changeReportingBehavior:
                            ChangeReportingBehavior.onScrollEnd,
                        selectionOverlayBuilder:
                            (
                              BuildContext context, {
                              required int columnCount,
                              required int selectedIndex,
                            }) {
                              return CupertinoPickerDefaultSelectionOverlay(
                                capStartEdge: false,
                                capEndEdge: columnCount == selectedIndex + 1,
                              );
                            },
                        onDateTimeChanged: (date) {
                          print('date: $date');
                          setState(() {
                            _time = date;
                          });
                        },
                        mode: CupertinoDatePickerMode.time,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: Durations.medium1,
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                ),
                child: isValid
                    ? const SizedBox.shrink()
                    : Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.l10n.invalidTime,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: CupertinoButton.tinted(
                  onPressed: () {
                    _alarms.add(
                      EventAlarm.scheduled(
                        dayOffset: _unit == Unit.day ? _offset : null,
                        weekOffset: _unit == Unit.week ? _offset : null,
                        hour: _time?.hour ?? 9,
                        minute: _time?.minute ?? 0,
                      ),
                    );
                    setState(() {});
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  minimumSize: const Size.square(kMinInteractiveDimension),
                  borderRadius: BorderRadius.circular(kMinInteractiveDimension),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FontAwesomeIcons.plus, size: 16),
                      const SizedBox(width: 8),
                      Text(context.l10n.add),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8 + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}
