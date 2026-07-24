import 'package:flutter/material.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_metrics.dart';

/// 当前时间：左侧时刻 + 圆点指示线（数据由 BLoC 预计算）
class TaskTimeBlockCurrentTimeLine extends StatelessWidget {
  const TaskTimeBlockCurrentTimeLine({
    required this.top,
    required this.label,
    super.key,
  });

  final double top;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;

    return Positioned(
      top: top - 8,
      left: 0,
      right: 0,
      height: 16,
      child: IgnorePointer(
        child: Row(
          children: [
            SizedBox(
              width: TaskTimeBlockMetrics.timeLabelWidth,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
