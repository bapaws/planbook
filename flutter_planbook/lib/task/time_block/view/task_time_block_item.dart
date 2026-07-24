import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/service/task_action_service.dart';
import 'package:flutter_planbook/task/time_block/bloc/task_time_block_bloc.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_layout_item.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_metrics.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/task_entity.dart';

/// 时间轴上的单个任务块（长按移动 / 边缘调时长）
///
/// 拖拽过程中的临时几何仅存于本 State，松手后交给 BLoC 写库。
class TaskTimeBlockItem extends StatefulWidget {
  const TaskTimeBlockItem({
    required this.item,
    required this.dayStart,
    required this.parentWidth,
    super.key,
  });

  final TaskTimeBlockLayoutItem item;
  final Jiffy dayStart;
  final double parentWidth;

  @override
  State<TaskTimeBlockItem> createState() => _TaskTimeBlockItemState();
}

class _TaskTimeBlockItemState extends State<TaskTimeBlockItem> {
  /// 调整时长时的临时 top / height；null 表示未在调整
  double? _resizeTop;
  double? _resizeHeight;

  /// 手势开始时的原始几何，用于按累计位移计算
  double? _originTop;
  double? _originHeight;
  double _accumDy = 0;

  late bool _isCompleted;

  TaskTimeBlockLayoutItem get item => widget.item;

  double get _displayTop => _resizeTop ?? item.top;

  double get _displayHeight => _resizeHeight ?? item.height;

  /// 完成按钮尺寸（适配矮块）
  static const double _completeIconSize = 15;
  static const double _completeHitSize = 26;

  @override
  void initState() {
    super.initState();
    _isCompleted = item.task.isCompleted;
  }

  @override
  void didUpdateWidget(TaskTimeBlockItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.task.isCompleted != item.task.isCompleted) {
      _isCompleted = item.task.isCompleted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = item.task.priority.getColorScheme(context);
    final theme = Theme.of(context);

    final availableWidth = widget.parentWidth * item.widthFactor;
    final left = widget.parentWidth * (item.columnIndex / item.columnCount);

    return Positioned(
      top: _displayTop,
      left: left,
      width: availableWidth,
      height: _displayHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: LongPressDraggable<TaskEntity>(
              data: item.task,
              feedback: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: availableWidth,
                  height: _displayHeight,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.task.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildBlockContent(colorScheme),
              ),
              child: GestureDetector(
                onTap: () => _openTaskDetail(context),
                child: _buildBlockContent(colorScheme),
              ),
            ),
          ),
          // 右上角完成按钮（与列表任务同款图标）
          Positioned(
            top: 0,
            right: 0,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(_completeHitSize, _completeHitSize),
              onPressed: _toggleCompleted,
              child: Icon(
                _isCompleted
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: _completeIconSize,
                color: _isCompleted ? colorScheme.outline : colorScheme.primary,
              ),
            ),
          ),
          // 上边缘：调整开始时间（结束不变）
          Positioned(
            top: 0,
            left: 0,
            right: _completeHitSize,
            height: TaskTimeBlockMetrics.resizeHandleHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => _beginResize(),
              onVerticalDragUpdate: _onTopResizeUpdate,
              onVerticalDragEnd: (_) => _commitResize(),
              onVerticalDragCancel: _cancelResize,
              child: const SizedBox(height: 12),
            ),
          ),
          // 下边缘：调整结束时间（开始不变）
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: TaskTimeBlockMetrics.resizeHandleHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => _beginResize(),
              onVerticalDragUpdate: _onBottomResizeUpdate,
              onVerticalDragEnd: (_) => _commitResize(),
              onVerticalDragCancel: _cancelResize,
              child: const SizedBox(height: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockContent(ColorScheme colorScheme) {
    final timeLabel = _resizeTop != null
        ? '${_displayStartAt().toLocal().jm} - ${_displayEndAt().toLocal().jm}'
        : item.timeRangeLabel;

    return Container(
      // 右侧给完成按钮留空，避免标题与按钮重叠
      padding: const EdgeInsets.fromLTRB(5, 5, _completeHitSize, 5),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.task.title,
              style: TextStyle(
                fontSize: 11,
                color: _isCompleted ? colorScheme.outline : colorScheme.primary,
                decoration: _isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            Text(
              timeLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: _isCompleted ? colorScheme.outline : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleCompleted() {
    setState(() => _isCompleted = !_isCompleted);
    context.read<TaskListBloc>().add(TaskListCompleted(task: item.task));
    context.read<TaskActionService>().playCompletedFeedback();
  }

  Jiffy _displayStartAt() {
    final minutes = (_displayTop / TaskTimeBlockMetrics.hourHeight * 60)
        .round();
    return widget.dayStart.add(minutes: minutes);
  }

  Jiffy _displayEndAt() {
    final minutes =
        ((_displayTop + _displayHeight) / TaskTimeBlockMetrics.hourHeight * 60)
            .round();
    return widget.dayStart.add(minutes: minutes);
  }

  void _beginResize() {
    _originTop = item.top;
    _originHeight = item.height;
    _accumDy = 0;
  }

  void _onTopResizeUpdate(DragUpdateDetails details) {
    final originTop = _originTop ?? item.top;
    final originHeight = _originHeight ?? item.height;
    final bottom = originTop + originHeight;
    _accumDy += details.delta.dy;

    var newTop = TaskTimeBlockMetrics.snapPixels(originTop + _accumDy);
    newTop = newTop.clamp(
      0.0,
      bottom - TaskTimeBlockMetrics.minSnapHeight,
    );
    final newHeight = bottom - newTop;

    setState(() {
      _resizeTop = newTop;
      _resizeHeight = newHeight;
    });
    context.read<TaskTimeBlockBloc>().add(
      TaskTimeBlockHoverUpdated(
        (newTop / TaskTimeBlockMetrics.hourHeight * 60).round(),
      ),
    );
  }

  void _onBottomResizeUpdate(DragUpdateDetails details) {
    final originTop = _originTop ?? item.top;
    final originHeight = _originHeight ?? item.height;
    _accumDy += details.delta.dy;

    var newHeight = TaskTimeBlockMetrics.snapPixels(originHeight + _accumDy);
    final maxHeight = TaskTimeBlockMetrics.gridHeight - originTop;
    newHeight = newHeight.clamp(
      TaskTimeBlockMetrics.minSnapHeight,
      maxHeight,
    );

    setState(() {
      _resizeTop = originTop;
      _resizeHeight = newHeight;
    });
    context.read<TaskTimeBlockBloc>().add(
      TaskTimeBlockHoverUpdated(
        ((originTop + newHeight) / TaskTimeBlockMetrics.hourHeight * 60)
            .round(),
      ),
    );
  }

  void _commitResize() {
    if (_resizeTop == null || _resizeHeight == null) {
      _resetResizeState();
      return;
    }

    final startAt = _displayStartAt();
    final endAt = _displayEndAt();
    final task = item.task;

    final originalStart = task.startAt!;
    final originalEnd = task.endAt ?? originalStart.add(hours: 1);
    final changed =
        !startAt.isSame(originalStart, unit: Unit.minute) ||
        !endAt.isSame(originalEnd, unit: Unit.minute);

    _resetResizeState();
    context.read<TaskTimeBlockBloc>().add(const TaskTimeBlockHoverCleared());
    if (!changed) return;

    context.read<TaskListBloc>().add(
      TaskListTaskTimeBlocked(
        task: task,
        startAt: startAt,
        endAt: endAt,
      ),
    );
  }

  void _cancelResize() {
    _resetResizeState();
    context.read<TaskTimeBlockBloc>().add(const TaskTimeBlockHoverCleared());
  }

  void _resetResizeState() {
    setState(() {
      _resizeTop = null;
      _resizeHeight = null;
      _originTop = null;
      _originHeight = null;
      _accumDy = 0;
    });
  }

  void _openTaskDetail(BuildContext context) {
    context.router.push(
      TaskDetailRoute(
        taskId: item.task.parentId ?? item.task.id,
        occurrenceAt: item.task.occurrence?.occurrenceAt,
      ),
    );
  }
}
