import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/week/bloc/task_week_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';

class RootTaskWeekTitleView extends StatelessWidget {
  const RootTaskWeekTitleView({
    this.date,
    this.isCalendarExpanded = false,
    super.key,
  });

  final Jiffy? date;
  final bool isCalendarExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () {
            context.read<TaskWeekBloc>().add(
              TaskWeekDateSelected(date: Jiffy.now()),
            );
          },
          child: BlocSelector<TaskWeekBloc, TaskWeekState, Jiffy>(
            selector: (state) => state.date,
            builder: (context, date) => Text(
              _buildTimelineTitle(context, date),
              style: theme.appBarTheme.titleTextStyle,
            ),
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size.square(
            kMinInteractiveDimensionCupertino,
          ),
          onPressed: () {
            context.read<TaskWeekBloc>().add(
              const TaskWeekCalendarToggled(),
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
            child: BlocSelector<TaskWeekBloc, TaskWeekState, bool>(
              selector: (state) => state.isCalendarExpanded,
              builder: (context, isCalendarExpanded) => AnimatedRotation(
                turns: isCalendarExpanded ? 0.25 : 0,
                duration: Durations.medium1,
                child: Icon(
                  FontAwesomeIcons.chevronRight,
                  size: 12,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _buildTimelineTitle(BuildContext context, Jiffy date) {
    final now = Jiffy.now();
    if (date.isSame(now, unit: Unit.week)) {
      return 'W${date.weekOfYear}, ${context.l10n.thisWeek}';
    }
    if (date.isSame(now.subtract(days: 1), unit: Unit.week)) {
      return 'W${date.weekOfYear}, ${context.l10n.lastWeek}';
    }
    return 'W${date.weekOfYear}';
  }
}
