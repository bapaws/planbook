import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:flutter_planbook/task/list/view/task_list_delete_dialog_listener.dart';
import 'package:flutter_planbook/task/time_block/bloc/task_time_block_bloc.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_layout_item.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_metrics.dart';
import 'package:flutter_planbook/task/time_block/view/task_time_block_current_time_line.dart';
import 'package:flutter_planbook/task/time_block/view/task_time_block_demo_banner.dart';
import 'package:flutter_planbook/task/time_block/view/task_time_block_drag_indicator.dart';
import 'package:flutter_planbook/task/time_block/view/task_time_block_grid.dart';
import 'package:flutter_planbook/task/time_block/view/task_time_block_item.dart';
import 'package:flutter_planbook/task/time_block/view/task_time_block_labels.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/task_entity.dart';

/// 时间块视图
///
/// 布局与时钟数据由 [TaskTimeBlockBloc] 预计算，本组件只负责渲染与手势坐标转换。
class TaskTimeBlockView extends StatefulWidget {
  const TaskTimeBlockView({
    this.isDemo = false,
    super.key,
  });

  /// 是否为演示模式（非会员）
  final bool isDemo;

  @override
  State<TaskTimeBlockView> createState() => _TaskTimeBlockViewState();
}

class _TaskTimeBlockViewState extends State<TaskTimeBlockView> {
  late final ScrollController _scrollController;
  final GlobalKey _gridKey = GlobalKey();

  /// 拖拽自动滚动
  Timer? _autoScrollTimer;
  double _autoScrollVelocity = 0;

  /// DragTarget 反馈位置（用于落点预览）
  Offset? _lastDragFeedbackOffset;

  /// 手指全局坐标（仅用于触发上下自动滚动）
  Offset? _pointerGlobal;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handlePointerEvent,
    );
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePointerEvent(PointerEvent event) {
    if (event is PointerDownEvent ||
        event is PointerMoveEvent ||
        event is PointerHoverEvent) {
      _pointerGlobal = event.position;
    }
  }

  /// 打开时滚动到当前时刻附近（约在视口 1/3 处）
  void _scrollToCurrentTime() {
    if (!_scrollController.hasClients) return;

    final top = context.read<TaskTimeBlockBloc>().state.currentTimeTop;
    if (top == null) return;

    final viewport = _scrollController.position.viewportDimension;
    final target = (top - viewport / 3).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final bottomBarHeight =
        kRootBottomBarHeight + MediaQuery.of(context).padding.bottom;
    final child = SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        height:
            (widget.isDemo ? TaskTimeBlockMetrics.hourHeight : 0) +
            TaskTimeBlockMetrics.gridTopExtraHeight +
            TaskTimeBlockMetrics.gridHeight +
            bottomBarHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                const TaskTimeBlockLabels(),
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: TaskTimeBlockMetrics.gridTopExtraHeight,
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return _TaskTimeBlockGridArea(
                            gridKey: _gridKey,
                            gridWidth: constraints.maxWidth,
                            isDemo: widget.isDemo,
                            onDragMove: _onDragMove,
                            onClearHover: _clearHover,
                            onTaskDropped: _onTaskDropped,
                          );
                        },
                      ),
                      SizedBox(
                        height:
                            (widget.isDemo
                                ? TaskTimeBlockMetrics.hourHeight
                                : 0) +
                            bottomBarHeight,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const _TaskTimeBlockCurrentTimeOverlay(),
            const _TaskTimeBlockHoverOverlay(),
          ],
        ),
      ),
    );

    if (widget.isDemo) {
      return Stack(
        children: [
          child,
          Positioned(
            bottom: bottomBarHeight,
            left: 0,
            right: 8,
            child: const AppDemoBanner(),
          ),
        ],
      );
    }

    return TaskListDeleteDialogListener(child: child);
  }

  void _onDragMove(DragTargetDetails<TaskEntity> details) {
    _lastDragFeedbackOffset = details.offset;
    final minutes = _snapMinutesFromGlobalOffset(details.offset);
    if (minutes != null) {
      context.read<TaskTimeBlockBloc>().add(TaskTimeBlockHoverUpdated(minutes));
    }
    // 自动滚动只看手指位置，不看反馈块顶部
    _updateAutoScroll(_pointerGlobal ?? details.offset);
  }

  void _clearHover() {
    _stopAutoScroll();
    _lastDragFeedbackOffset = null;
    context.read<TaskTimeBlockBloc>().add(const TaskTimeBlockHoverCleared());
  }

  void _onTaskDropped(TaskEntity task, Offset offset) {
    _stopAutoScroll();
    _lastDragFeedbackOffset = null;
    final minutes = _snapMinutesFromGlobalOffset(offset);
    if (minutes == null) return;

    final timeBlockBloc = context.read<TaskTimeBlockBloc>()
      ..add(const TaskTimeBlockHoverCleared());

    // 演示模式下任何投放操作都进入付费墙
    if (widget.isDemo) {
      context.router.push(const AppPurchasesRoute());
      return;
    }

    final startAt = timeBlockBloc.state.dayStart.add(minutes: minutes);
    final endAt = startAt.add(minutes: resolveTaskDurationMinutes(task));
    context.read<TaskListBloc>().add(
      TaskListTaskTimeBlocked(
        task: task,
        startAt: startAt,
        endAt: endAt,
      ),
    );
  }

  /// 将全局坐标转为对齐后的分钟数（仅做坐标转换，不处理业务数据）
  int? _snapMinutesFromGlobalOffset(Offset globalOffset) {
    final renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final localOffset = renderBox.globalToLocal(globalOffset);
    return TaskTimeBlockMetrics.snapMinutesFromLocalDy(localOffset.dy);
  }

  /// 根据手指相对视口位置，决定向上 / 向下自动滚动
  void _updateAutoScroll(Offset pointerGlobal) {
    if (!_scrollController.hasClients) return;

    final scrollContext =
        _scrollController.position.context.notificationContext;
    final box = scrollContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final localY = box.globalToLocal(pointerGlobal).dy;
    final height = box.size.height;
    const topEdge = TaskTimeBlockMetrics.autoScrollEdgeExtent;
    // 底部热区 = 基础边缘 + 导航栏 + 安全区 + 额外余量
    final bottomEdge =
        TaskTimeBlockMetrics.autoScrollEdgeExtent +
        TaskTimeBlockMetrics.autoScrollBottomExtraExtent +
        kRootBottomBarHeight +
        MediaQuery.of(context).padding.bottom;
    const maxStep = TaskTimeBlockMetrics.autoScrollMaxStep;

    var velocity = 0.0;
    if (localY < topEdge) {
      // 越靠近顶部滚得越快（负值 = 向上）
      velocity = -maxStep * (1 - (localY / topEdge).clamp(0.0, 1.0));
    } else if (localY > height - bottomEdge) {
      final t = ((localY - (height - bottomEdge)) / bottomEdge).clamp(0.0, 1.0);
      velocity = maxStep * t;
    }

    if (velocity == 0) {
      _stopAutoScroll();
      return;
    }
    _autoScrollVelocity = velocity;
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (_autoScrollTimer != null) return;
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || !_scrollController.hasClients) {
        _stopAutoScroll();
        return;
      }
      final position = _scrollController.position;
      final next = (position.pixels + _autoScrollVelocity).clamp(
        0.0,
        position.maxScrollExtent,
      );
      if (next == position.pixels) {
        _stopAutoScroll();
        return;
      }
      _scrollController.jumpTo(next);

      // 内容移动后，仍按反馈块位置刷新落点预览
      final feedback = _lastDragFeedbackOffset;
      if (feedback != null) {
        final minutes = _snapMinutesFromGlobalOffset(feedback);
        if (minutes != null) {
          context.read<TaskTimeBlockBloc>().add(
            TaskTimeBlockHoverUpdated(minutes),
          );
        }
      }

      // 手指可能仍停在边缘，按最新触点维持/调整滚动速度
      final pointer = _pointerGlobal;
      if (pointer != null) {
        _updateAutoScroll(pointer);
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollVelocity = 0;
  }
}

/// 任务网格区：仅在 items / dayStart 变化时重建
class _TaskTimeBlockGridArea extends StatelessWidget {
  const _TaskTimeBlockGridArea({
    required this.gridKey,
    required this.gridWidth,
    required this.isDemo,
    required this.onDragMove,
    required this.onClearHover,
    required this.onTaskDropped,
  });

  final GlobalKey gridKey;
  final double gridWidth;
  final bool isDemo;
  final void Function(DragTargetDetails<TaskEntity> details) onDragMove;
  final VoidCallback onClearHover;
  final void Function(TaskEntity task, Offset offset) onTaskDropped;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      TaskTimeBlockBloc,
      TaskTimeBlockState,
      ({List<TaskTimeBlockLayoutItem> items, Jiffy dayStart})
    >(
      selector: (state) => (items: state.items, dayStart: state.dayStart),
      builder: (context, data) {
        return TaskDragTarget(
          key: gridKey,
          onMove: onDragMove,
          onLeave: (_) => onClearHover(),
          onAcceptWithDetails: (details) {
            onTaskDropped(details.data, details.offset);
          },
          child: Stack(
            children: [
              const TaskTimeBlockGrid(),
              for (final item in data.items)
                TaskTimeBlockItem(
                  item: item,
                  dayStart: data.dayStart,
                  parentWidth: gridWidth,
                  isDemo: isDemo,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskTimeBlockCurrentTimeOverlay extends StatelessWidget {
  const _TaskTimeBlockCurrentTimeOverlay();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      TaskTimeBlockBloc,
      TaskTimeBlockState,
      ({double? top, String? label})
    >(
      selector: (state) => (
        top: state.currentTimeTop,
        label: state.currentTimeLabel,
      ),
      builder: (context, data) {
        if (data.top == null || data.label == null) {
          return const SizedBox.shrink();
        }
        return TaskTimeBlockCurrentTimeLine(
          top: data.top!,
          label: data.label!,
        );
      },
    );
  }
}

class _TaskTimeBlockHoverOverlay extends StatelessWidget {
  const _TaskTimeBlockHoverOverlay();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      TaskTimeBlockBloc,
      TaskTimeBlockState,
      ({int? minutes, String? label})
    >(
      selector: (state) => (
        minutes: state.hoverMinutes,
        label: state.hoverLabel,
      ),
      builder: (context, data) {
        if (data.minutes == null || data.label == null) {
          return const SizedBox.shrink();
        }
        return TaskTimeBlockDragIndicator(
          minutes: data.minutes!,
          label: data.label!,
        );
      },
    );
  }
}
