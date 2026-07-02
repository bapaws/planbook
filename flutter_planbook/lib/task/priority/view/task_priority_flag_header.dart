import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/core/model/quadrant_config_x.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_header_long_press.dart';
import 'package:planbook_api/planbook_api.dart';

class TaskPriorityFlagHeader extends StatelessWidget {
  const TaskPriorityFlagHeader({
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
      child: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${priority.value}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              configs.nameOf(priority, context.l10n),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
