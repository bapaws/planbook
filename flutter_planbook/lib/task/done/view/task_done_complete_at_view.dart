import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/done/cubit/task_done_cubit.dart';
import 'package:jiffy/jiffy.dart';

class TaskDoneCompleteAtView extends StatelessWidget {
  const TaskDoneCompleteAtView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return BlocSelector<TaskDoneCubit, TaskDoneState, Jiffy?>(
      selector: (state) => state.completedAt ?? Jiffy.now(),
      builder: (context, completedAt) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            minimumSize: Size.zero,
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
            onPressed: () {
              final renderBox = context.findRenderObject() as RenderBox?;
              final now =
                  context.read<TaskDoneCubit>().state.completedAt ??
                  Jiffy.now();
              showCupertinoCalendarPicker(
                context,
                widgetRenderBox: renderBox,
                minimumDateTime: DateTime(1970),
                initialDateTime: now.dateTime,
                maximumDateTime: DateTime(2500, 12, 31),
                mainColor: colorScheme.primary,
                firstDayOfWeekIndex: switch (now.startOfWeek) {
                  StartOfWeek.monday => DateTime.monday,
                  StartOfWeek.saturday => DateTime.saturday,
                  StartOfWeek.sunday => DateTime.sunday,
                },
                timeLabel: context.l10n.time,
                onDateTimeChanged: (dateTime) {
                  context.read<TaskDoneCubit>().onCompletedAtChanged(
                    Jiffy.parseFromDateTime(dateTime),
                  );
                },
              );
            },
            child: Text(
              completedAt?.toLocal().yMMMd ?? '',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            minimumSize: Size.zero,
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
            onPressed: () {
              final renderBox = context.findRenderObject() as RenderBox?;
              final now =
                  context.read<TaskDoneCubit>().state.completedAt ??
                  Jiffy.now();
              showCupertinoTimePicker(
                context,
                widgetRenderBox: renderBox,
                initialTime: TimeOfDay.fromDateTime(now.dateTime),
                onTimeChanged: (time) {
                  final completedAt = context
                      .read<TaskDoneCubit>()
                      .state
                      .completedAt;
                  context.read<TaskDoneCubit>().onCompletedAtChanged(
                    Jiffy.parseFromList([
                      completedAt?.year ?? now.year,
                      completedAt?.month ?? now.month,
                      completedAt?.date ?? now.date,
                      time.hour,
                      time.minute,
                    ]),
                  );
                },
              );
            },
            child: Text(
              completedAt?.toLocal().jm ?? '',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
