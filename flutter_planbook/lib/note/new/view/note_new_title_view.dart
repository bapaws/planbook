import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/new/cubit/note_new_cubit.dart';
import 'package:jiffy/jiffy.dart';

class NoteNewTitleView extends StatelessWidget {
  const NoteNewTitleView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return BlocSelector<NoteNewCubit, NoteNewState, Jiffy?>(
      selector: (state) => state.createdAt ?? Jiffy.now(),
      builder: (context, createdAt) => Row(
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
                  context.read<NoteNewCubit>().state.createdAt ?? Jiffy.now();
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
                  context.read<NoteNewCubit>().onCreatedAtChanged(
                    Jiffy.parseFromDateTime(dateTime),
                  );
                },
              );
            },
            child: Text(
              createdAt?.toLocal().yMMMd ?? '',
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
                  context.read<NoteNewCubit>().state.createdAt ?? Jiffy.now();
              showCupertinoTimePicker(
                context,
                widgetRenderBox: renderBox,
                initialTime: TimeOfDay.fromDateTime(now.dateTime),
                onTimeChanged: (time) {
                  final createdAt = context
                      .read<NoteNewCubit>()
                      .state
                      .createdAt;
                  context.read<NoteNewCubit>().onCreatedAtChanged(
                    Jiffy.parseFromList([
                      createdAt?.year ?? now.year,
                      createdAt?.month ?? now.month,
                      createdAt?.date ?? now.date,
                      time.hour,
                      time.minute,
                    ]),
                  );
                },
              );
            },
            child: Text(
              createdAt?.toLocal().jm ?? '',
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
