import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/journal/summary/bloc/journal_summary_bloc.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:jiffy/jiffy.dart';

@RoutePage()
class JournalSummaryPage extends StatelessWidget {
  const JournalSummaryPage({required this.date, super.key});

  final Jiffy date;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JournalSummaryBloc(
        tasksRepository: context.read(),
        notesRepository: context.read(),
      )..add(JournalSummaryRequested(date: date)),
      child: _JournalSummaryPage(date: date),
    );
  }
}

class _JournalSummaryPage extends StatelessWidget {
  const _JournalSummaryPage({required this.date});

  final Jiffy date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocBuilder<JournalSummaryBloc, JournalSummaryState>(
      builder: (context, state) {
        final completionRate = state.totalTasks > 0
            ? (state.completedTasks / state.totalTasks * 100).toStringAsFixed(0)
            : '0';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务统计
            _buildStatCard(
              context: context,
              title: context.l10n.task,
              icon: '📋',
              children: [
                _buildStatItem(
                  context: context,
                  label: 'Total',
                  value: '${state.totalTasks}',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                _buildStatItem(
                  context: context,
                  label: 'Completed',
                  value: '${state.completedTasks}',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                _buildStatItem(
                  context: context,
                  label: 'Completion Rate',
                  value: '$completionRate%',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 笔记统计
            _buildStatCard(
              context: context,
              title: context.l10n.notes,
              icon: '📝',
              children: [
                _buildStatItem(
                  context: context,
                  label: 'Total Notes',
                  value: '${state.totalNotes}',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                _buildStatItem(
                  context: context,
                  label: 'Total Words',
                  value: '${state.totalWords}',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Divider(
          color: colorScheme.outlineVariant,
          height: 16,
          thickness: 1,
        ),
        ...children,
      ],
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
