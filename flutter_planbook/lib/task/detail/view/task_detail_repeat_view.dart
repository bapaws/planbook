import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/view/app_icon.dart';
import 'package:flutter_planbook/core/model/recurrence_frequency_x.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/detail/bloc/task_detail_bloc.dart';
import 'package:flutter_planbook/task/detail/view/task_detail_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/database/recurrence_rule.dart';

class TaskDetailRepeatView extends StatelessWidget {
  const TaskDetailRepeatView({
    required this.recurrenceRule,
    super.key,
  });

  final RecurrenceRule? recurrenceRule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return TaskDetailSliverTile(
      onPressed: () async {
        final bloc = context.read<TaskDetailBloc>();
        final recurrenceRule = await context.router.push(
          TaskRecurrenceRoute(),
        );
        if (recurrenceRule is! RecurrenceRule || !context.mounted) return;
        bloc.add(
          TaskDetailRecurrenceRuleChanged(
            recurrenceRule: recurrenceRule,
          ),
        );
      },
      leading: AppIcon(
        FontAwesomeIcons.arrowsRotate,
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.tertiary,
      ),
      title: context.l10n.repeat,
      trailing: recurrenceRule == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  spacing: 2,
                  children: [
                    Text(context.l10n.every),
                    Text(recurrenceRule!.interval.toString()),
                    Text(
                      recurrenceRule!.frequency.getEveryUnitName(context.l10n),
                    ),
                  ],
                ),
                if (recurrenceRule?.recurrenceEnd?.endAt != null)
                  Text(
                    context.l10n.endsOn(
                      recurrenceRule!.recurrenceEnd!.endAt!.yMMMd,
                    ),
                  )
                else if (recurrenceRule?.recurrenceEnd?.occurrenceCount != null)
                  Text(
                    context.l10n.endsIn(
                      recurrenceRule!.recurrenceEnd!.occurrenceCount ?? 2,
                    ),
                  ),
              ],
            ),
    );
  }
}
