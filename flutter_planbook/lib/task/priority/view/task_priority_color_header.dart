import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/core/model/quadrant_config_x.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_header_long_press.dart';
import 'package:planbook_api/planbook_api.dart';

class TaskPriorityColorHeader extends StatelessWidget {
  const TaskPriorityColorHeader({
    required this.priority,
    required this.colorScheme,
    super.key,
  });

  final TaskPriority priority;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configs = context.select((AppBloc b) => b.state.quadrantConfigs);
    return TaskPriorityHeaderLongPress(
      child: Container(
        margin: EdgeInsets.only(
          left: priority.isUrgent ? 8 : 6,
          right: priority.isUrgent ? 6 : 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${priority.value}. ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  configs.nameOf(priority, context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    // fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
