import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_icon.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/detail/bloc/task_detail_bloc.dart';
import 'package:flutter_planbook/task/detail/view/task_detail_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/task_entity.dart';

class TaskDetailDurationView extends StatelessWidget {
  const TaskDetailDurationView({
    required this.task,
    required this.colorScheme,
    super.key,
  });

  final TaskEntity task;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return TaskDetailSliverTile(
      onPressed: () {
        context.router.push(
          TaskDurationRoute(
            startAt: task.startAt,
            endAt: task.endAt,
            isAllDay: task.isAllDay,
            onIsAllDayChanged: (bool value) {
              context.read<TaskDetailBloc>().add(
                TaskDetailIsAllDayChanged(isAllDay: value),
              );
            },
            onStartAtChanged: (Jiffy? value) {
              context.read<TaskDetailBloc>().add(
                TaskDetailStartAtChanged(startAt: value),
              );
            },
            onEndAtChanged: (Jiffy? value) {
              context.read<TaskDetailBloc>().add(
                TaskDetailEndAtChanged(endAt: value),
              );
            },
          ),
        );
      },
      leading: AppIcon(
        FontAwesomeIcons.solidClock,
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.tertiary,
      ),
      title: context.l10n.duration,
      trailing: task.startAt != null && task.endAt != null
          ? Row(
              children: [
                Text(task.startAt!.toLocal().jm),
                const Text('-'),
                Text(task.endAt!.toLocal().jm),
              ],
            )
          : Text(context.l10n.allDay),
    );
  }
}
