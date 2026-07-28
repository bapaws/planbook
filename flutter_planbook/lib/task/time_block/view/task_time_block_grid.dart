import 'package:flutter/material.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_metrics.dart';

/// 时间网格背景线
class TaskTimeBlockGrid extends StatelessWidget {
  const TaskTimeBlockGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < TaskTimeBlockMetrics.hourLabels.length; i++)
          Container(
            height: TaskTimeBlockMetrics.hourHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.surfaceContainerHighest,
                  width: i == 0 ? 1 : 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
