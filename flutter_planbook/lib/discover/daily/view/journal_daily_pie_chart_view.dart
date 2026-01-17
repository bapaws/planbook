import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_api/database/task_priority.dart';

const kJournalDailyPieChartViewHeight = 120.0;

class JournalDailyPieChartView extends StatelessWidget {
  const JournalDailyPieChartView({required this.taskPriorityCounts, super.key});

  final Map<TaskPriority, int> taskPriorityCounts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kJournalDailyPieChartViewHeight,
      child: Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 0,
                  startDegreeOffset: -90,
                  sections: [
                    for (final taskPriorityCount in taskPriorityCounts.entries)
                      _buildPieChartSectionData(
                        context,
                        taskPriorityCount.key,
                        taskPriorityCount.value,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final priority in TaskPriority.values.reversed)
                _buildPriorityItem(context, priority),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieChartSectionData(
    BuildContext context,
    TaskPriority priority,
    int value,
  ) {
    final colorScheme = priority.getColorScheme(context);
    return PieChartSectionData(
      radius: (kJournalDailyPieChartViewHeight / 2) - 4,
      showTitle: false,
      value: value.toDouble(),
      color: colorScheme.primaryContainer,
      borderSide: BorderSide(
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildPriorityItem(BuildContext context, TaskPriority priority) {
    final colorScheme = priority.getColorScheme(context);
    final theme = Theme.of(context);
    return Row(
      children: [
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
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4, height: 28),
        Text(
          priority.getTitle(context.l10n),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${taskPriorityCounts[priority]}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
