import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_operation.dart';
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
    this.isDemo = false,
    super.key,
  });

  final TaskTimeBlockLayoutItem item;
  final Jiffy dayStart;
  final double parentWidth;

  /// 是否为演示模式；演示模式下只读，点击跳转付费墙
  final bool isDemo;

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

    // 当 BLoC 下发新的任务时间后，再清除临时调整几何，避免弹回旧尺寸。
    if (_resizeTop != null || _resizeHeight != null) {
      final oldStart = oldWidget.item.task.startAt;
      final oldEnd = oldWidget.item.task.endAt;
      final newStart = item.task.startAt;
      final newEnd = item.task.endAt;
      final taskChanged = oldWidget.item.task.id != item.task.id;
      final startChanged =
          oldStart == null ||
          newStart == null ||
          !oldStart.isSame(newStart, unit: Unit.minute);
      final endChanged =
          oldEnd == null ||
          newEnd == null ||
          !oldEnd.isSame(newEnd, unit: Unit.minute);
      if (taskChanged || startChanged || endChanged) {
        _clearResizeState();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = item.task.priority.getColorScheme(context);
    final theme = Theme.of(context);

    final availableWidth = widget.parentWidth * item.widthFactor;
    final left = widget.parentWidth * (item.columnIndex / item.columnCount);
    // 正在调时长时必须保留热区，否则缩到阈值以下会把 GestureDetector
    // 从树上拆掉，触发 cancel，之后再也无法拖边缘。
    final isResizing = _resizeTop != null;
    final isShort =
        !isResizing &&
        _displayHeight < TaskTimeBlockMetrics.minHeightForResizeHandles;
    // 高块 / 拖拽中：上下都能调；矮块闲置：只留底边以便拉长，其余留给长按拖动
    final showTopHandle = !isShort;
    const showBottomHandle = true;
    final handleHeight = isShort
        ? 10.0
        : TaskTimeBlockMetrics.resizeHandleHeight;

    final content = Stack(
      clipBehavior: Clip.none,
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
            // 与 TaskDraggable 一致：move 被外部目标接受后乐观移除，
            // 避免拖到侧栏后残影闪回原位。
            onDragCompleted: () {
              final operation = TaskDragOperationNotifier.instance.take();
              if (operation != TaskDragOperation.move) return;
              if (!context.mounted) return;
              context.read<TaskListBloc>().add(
                TaskListTaskDragCompleted(task: item.task),
              );
            },
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
        if (showTopHandle)
          Positioned(
            top: 0,
            left: 0,
            right: _completeHitSize,
            height: handleHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => _beginResize(),
              onVerticalDragUpdate: _onTopResizeUpdate,
              onVerticalDragEnd: (_) => _commitResize(),
              onVerticalDragCancel: _cancelResize,
              child: SizedBox(height: handleHeight),
            ),
          ),
        if (showBottomHandle)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: handleHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => _beginResize(),
              onVerticalDragUpdate: _onBottomResizeUpdate,
              onVerticalDragEnd: (_) => _commitResize(),
              onVerticalDragCancel: _cancelResize,
              child: SizedBox(height: handleHeight),
            ),
          ),
      ],
    );

    return Positioned(
      top: _displayTop,
      left: left,
      width: availableWidth,
      height: _displayHeight,
      child: widget.isDemo
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.router.push(const AppPurchasesRoute()),
              child: AbsorbPointer(
                child: content,
              ),
            )
          : content,
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
      bottom - TaskTimeBlockMetrics.minResizeHeight,
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
      TaskTimeBlockMetrics.minResizeHeight,
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

    context.read<TaskTimeBlockBloc>().add(const TaskTimeBlockHoverCleared());
    if (!changed) {
      _resetResizeState();
      return;
    }

    context.read<TaskListBloc>().add(
      TaskListTaskTimeBlocked(
        task: task,
        startAt: startAt,
        endAt: endAt,
      ),
    );
    // 不立即清除 _resizeTop/_resizeHeight，保持新几何直到 BLoC 下发新 item。
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

  /// 不触发 setState 的清除；在 didUpdateWidget 中 BLoC 已驱动重建时使用。
  void _clearResizeState() {
    _resizeTop = null;
    _resizeHeight = null;
    _originTop = null;
    _originHeight = null;
    _accumDy = 0;
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
