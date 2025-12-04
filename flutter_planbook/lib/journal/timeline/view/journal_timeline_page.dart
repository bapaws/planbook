import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/journal/timeline/bloc/journal_timeline_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_api/entity/task_entity.dart';

class JournalTimelinePage extends StatelessWidget {
  const JournalTimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<JournalTimelineBloc, JournalTimelineState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🌤️ ${context.l10n.morning}'),
            Divider(
              color: theme.colorScheme.outline,
              height: 2,
              thickness: 1,
            ),
            for (final task in state.morningTasks)
              _buildTaskListTile(context, task),
            const SizedBox(height: 8),
            Text('🌞 ${context.l10n.afternoon}'),
            Divider(
              color: theme.colorScheme.outline,
              height: 2,
              thickness: 1,
            ),
            for (final task in state.afternoonTasks)
              _buildTaskListTile(context, task),
            const SizedBox(height: 8),
            Text('🌙 ${context.l10n.evening}'),
            Divider(
              color: theme.colorScheme.outline,
              height: 2,
              thickness: 1,
            ),
            for (final task in state.eveningTasks)
              _buildTaskListTile(context, task),
          ],
        );
      },
    );
  }

  Widget _buildTaskListTile(BuildContext context, TaskEntity task) {
    final completedAt = task.activity?.completedAt;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: task.priority.color,
    );
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          if (completedAt != null)
            Text(
              completedAt.toLocal().jm,
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          SizedBox(
            height: 16,
            child: VerticalDivider(
              color: colorScheme.outlineVariant,
              width: 12,
            ),
          ),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
