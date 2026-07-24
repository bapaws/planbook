import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_page.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:flutter_planbook/task/list/view/task_list_delete_dialog_listener.dart';
import 'package:flutter_planbook/task/time_block/bloc/task_time_block_bloc.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_layout_item.dart';
import 'package:flutter_planbook/task/time_block/model/task_time_block_metrics.dart';
import 'package:flutter_planbook/task/time_block/view/task_time_block_current_time_line.dart';
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
  const TaskTimeBlockView({super.key});

  @override
  State<TaskTimeBlockView> createState() => _TaskTimeBlockViewState();
}

class _TaskTimeBlockViewState extends State<TaskTimeBlockView> {
  late final ScrollController _scrollController;
  final GlobalKey _gridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    return TaskListDeleteDialogListener(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            SizedBox(
              height: TaskTimeBlockMetrics.gridHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      const TaskTimeBlockLabels(),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return _TaskTimeBlockGridArea(
                              gridKey: _gridKey,
                              gridWidth: constraints.maxWidth,
                              onDragMove: _onDragMove,
                              onClearHover: _clearHover,
                              onTaskDropped: _onTaskDropped,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const _TaskTimeBlockCurrentTimeOverlay(),
                  const _TaskTimeBlockHoverOverlay(),
                ],
              ),
            ),
            SizedBox(
              height: kRootBottomBarHeight +
                  MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
      ),
    );
  }

  void _onDragMove(DragTargetDetails<TaskEntity> details) {
    final minutes = _snapMinutesFromGlobalOffset(details.offset);
    if (minutes == null) return;
    context.read<TaskTimeBlockBloc>().add(TaskTimeBlockHoverUpdated(minutes));
  }

  void _clearHover() {
    context.read<TaskTimeBlockBloc>().add(const TaskTimeBlockHoverCleared());
  }

  void _onTaskDropped(TaskEntity task, Offset offset) {
    final minutes = _snapMinutesFromGlobalOffset(offset);
    if (minutes == null) return;

    final timeBlockBloc = context.read<TaskTimeBlockBloc>()
      ..add(const TaskTimeBlockHoverCleared());

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
    final renderBox =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final localOffset = renderBox.globalToLocal(globalOffset);
    return TaskTimeBlockMetrics.snapMinutesFromLocalDy(localOffset.dy);
  }
}

/// 任务网格区：仅在 items / dayStart 变化时重建
class _TaskTimeBlockGridArea extends StatelessWidget {
  const _TaskTimeBlockGridArea({
    required this.gridKey,
    required this.gridWidth,
    required this.onDragMove,
    required this.onClearHover,
    required this.onTaskDropped,
  });

  final GlobalKey gridKey;
  final double gridWidth;
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
