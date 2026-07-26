import 'package:flutter/material.dart';
import 'package:flutter_planbook/task/list/view/task_drag_operation.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// 拖入任务时的回调（只需 task 本体）。
typedef TaskDragAccept = void Function(TaskEntity task);

/// 拖入任务时的回调（需要 [DragTargetDetails]，如 drop offset）。
typedef TaskDragAcceptWithDetails =
    void Function(DragTargetDetails<TaskEntity> details);

/// 自定义投放区域 UI（悬停高亮等）。
///
/// [candidateData] 非空表示当前有任务悬停在该区域上。
typedef TaskDragTargetBuilder =
    Widget Function(
      BuildContext context,
      Widget child,
      List<TaskEntity?> candidateData,
    );

/// 通用任务投放目标。
///
/// 统一封装 `DragTarget<TaskEntity>` 样板代码，供任务显示区域复用：
/// - 日期格 / 列表日格（现 `TaskDropArea`）
/// - 四象限（现 `TaskPriorityDropArea`）
/// - 重点 / 总结卡片
/// - Source Panel
/// - 时间块（需要 `onAcceptWithDetails` 取 offset）
/// - 列表整区 overlay（见 `SliverTaskDragTarget`）
///
/// 用法：
/// ```dart
/// TaskDragTarget(
///   onAccept: (task) => bloc.add(...),
///   child: content,
/// )
///
/// // 需要悬停态
/// TaskDragTarget(
///   onAccept: (task) => ...,
///   builder: (context, child, candidateData) {
///     final hovering = candidateData.isNotEmpty;
///     return DecoratedBox(
///       decoration: BoxDecoration(
///         border: Border.all(
///           color: hovering ? Theme.of(context).colorScheme.primary : ...,
///         ),
///       ),
///       child: child,
///     );
///   },
///   child: content,
/// )
///
/// // 需要 drop 坐标（时间块）
/// TaskDragTarget(
///   onAcceptWithDetails: (details) {
///     final offset = details.offset;
///     final task = details.data;
///     ...
///   },
///   child: content,
/// )
/// ```
///
/// [onAccept] / [onAcceptWithDetails] 都为 null 时不作为投放目标，直接返回 [child]。
/// 两者都提供时只调用 [onAcceptWithDetails]。
///
/// 业务语义（改日期 / 改优先级 / 打标签等）由调用方在回调里处理；
/// 现有的 `TaskDropArea`、`TaskPriorityDropArea` 可在 review 后改为内部复用本组件。
class TaskDragTarget extends StatelessWidget {
  const TaskDragTarget({
    required this.child,
    this.onAccept,
    this.onAcceptWithDetails,
    this.onWillAcceptWithDetails,
    this.onMove,
    this.onLeave,
    this.builder,
    this.operation = TaskDragOperation.move,
    super.key,
  });

  final Widget child;

  /// 接收任务时的回调（只关心 task）。
  final TaskDragAccept? onAccept;

  /// 需要 [DragTargetDetails]（如 drop offset）时使用。
  ///
  /// 与 [onAccept] 同时提供时，只调用本回调。
  final TaskDragAcceptWithDetails? onAcceptWithDetails;

  /// 可选：决定是否接受该次投放。
  final DragTargetWillAcceptWithDetails<TaskEntity>? onWillAcceptWithDetails;

  /// 拖拽在目标区域内移动时回调（如时间块预览落点）。
  final DragTargetMove<TaskEntity>? onMove;

  /// 拖拽离开目标区域时回调。
  final DragTargetLeave<TaskEntity>? onLeave;

  /// 自定义 builder；默认直接展示 [child]。
  final TaskDragTargetBuilder? builder;

  /// 目标被接受后执行的业务操作，用于通知源组件是否应从列表中移除任务。
  final TaskDragOperation operation;

  @override
  Widget build(BuildContext context) {
    final accept = onAccept;
    final acceptWithDetails = onAcceptWithDetails;
    if (accept == null && acceptWithDetails == null) {
      return child;
    }

    return DragTarget<TaskEntity>(
      onWillAcceptWithDetails: onWillAcceptWithDetails,
      onMove: onMove,
      onLeave: onLeave,
      onAcceptWithDetails: (details) {
        TaskDragOperationNotifier.instance.operation = operation;
        if (acceptWithDetails != null) {
          acceptWithDetails(details);
        } else {
          accept!(details.data);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return builder?.call(context, child, candidateData) ?? child;
      },
    );
  }
}

/// Sliver 场景下的任务投放目标。
///
/// 用 [SliverStack] + [SliverPositioned.fill] 在 [sliver] 上方叠一层
/// [TaskDragTarget]，覆盖整个列表滚动范围以接收投放。
/// Overlay 默认 [SizedBox.expand]（铺满 sliver 范围以接收投放，不绘制内容）。
///
/// 用法（对齐 `TaskListView.onTaskDropped`）：
/// ```dart
/// SliverTaskDragTarget(
///   onAccept: onTaskDropped,
///   sliver: MultiSliver(children: [...]),
/// )
/// ```
///
/// [onAccept] / [onAcceptWithDetails] 都为 null 时直接返回 [sliver]。
class SliverTaskDragTarget extends StatelessWidget {
  const SliverTaskDragTarget({
    required this.sliver,
    this.onAccept,
    this.onAcceptWithDetails,
    this.onWillAcceptWithDetails,
    this.overlayBuilder,
    this.operation = TaskDragOperation.move,
    super.key,
  });

  /// 被覆盖的内容 sliver（列表、MultiSliver 等）。
  final Widget sliver;

  /// 接收任务时的回调（只关心 task）。
  final TaskDragAccept? onAccept;

  /// 需要 [DragTargetDetails]（如 drop offset）时使用。
  ///
  /// 与 [onAccept] 同时提供时，只调用本回调。
  final TaskDragAcceptWithDetails? onAcceptWithDetails;

  /// 可选：决定是否接受该次投放。
  final DragTargetWillAcceptWithDetails<TaskEntity>? onWillAcceptWithDetails;

  /// 自定义 overlay UI；默认 [SizedBox.expand]（铺满范围，只接 drop）。
  ///
  /// 需要悬停高亮时传入，注意不要挡住下方列表的点击（优先用半透明装饰）。
  final TaskDragTargetBuilder? overlayBuilder;

  /// 目标被接受后执行的业务操作。
  final TaskDragOperation operation;

  @override
  Widget build(BuildContext context) {
    if (onAccept == null && onAcceptWithDetails == null) {
      return sliver;
    }

    return SliverStack(
      children: [
        sliver,
        SliverPositioned.fill(
          child: TaskDragTarget(
            onAccept: onAccept,
            onAcceptWithDetails: onAcceptWithDetails,
            onWillAcceptWithDetails: onWillAcceptWithDetails,
            builder: overlayBuilder,
            operation: operation,
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}
