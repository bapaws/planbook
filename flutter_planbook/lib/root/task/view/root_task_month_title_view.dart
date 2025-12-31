import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/task/month/bloc/task_month_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

class RootTaskMonthTitleView extends StatelessWidget {
  const RootTaskMonthTitleView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<TaskMonthBloc, TaskMonthState>(
      buildWhen: (previous, current) =>
          previous.date != current.date ||
          previous.isCalendarExpanded != current.isCalendarExpanded,
      builder: (context, state) {
        return Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () {
                context.read<TaskMonthBloc>().add(
                  TaskMonthDateSelected(date: Jiffy.now()),
                );
              },
              child: Text(
                _buildMonthTitle(state.date),
                style: theme.appBarTheme.titleTextStyle,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size.square(
                kMinInteractiveDimensionCupertino,
              ),
              onPressed: () {
                context.read<TaskMonthBloc>().add(
                  const TaskMonthCalendarToggled(),
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
                  turns: state.isCalendarExpanded ? 0.25 : 0,
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
      },
    );
  }

  String _buildMonthTitle(Jiffy date) {
    final now = Jiffy.now();
    if (date.isSame(now, unit: Unit.month)) {
      return '${date.year}/${date.month}';
    }
    return '${date.year}/${date.month}';
  }
}

