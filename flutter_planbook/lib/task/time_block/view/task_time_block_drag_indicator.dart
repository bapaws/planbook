import 'package:flutter/material.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_metrics.dart';

/// 拖拽落点时间指示器：左侧高亮时间 + 横贯网格的指示线
class TaskTimeBlockDragIndicator extends StatelessWidget {
  const TaskTimeBlockDragIndicator({
    required this.minutes,
    required this.label,
    super.key,
  });

  final int minutes;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final top = TaskTimeBlockMetrics.topFromMinutes(minutes);

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
                        color: theme.colorScheme.onPrimary,
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
              child: Container(
                height: 2,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
