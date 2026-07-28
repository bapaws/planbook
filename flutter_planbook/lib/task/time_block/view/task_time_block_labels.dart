import 'package:flutter/material.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_metrics.dart';

/// 左侧整点时间刻度（数据来自 [TaskTimeBlockMetrics.hourLabels]）
class TaskTimeBlockLabels extends StatelessWidget {
  const TaskTimeBlockLabels({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: TaskTimeBlockMetrics.timeLabelWidth,
      child: Column(
        children: [
          for (final label in TaskTimeBlockMetrics.hourLabels)
            SizedBox(
              height: TaskTimeBlockMetrics.hourHeight,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
