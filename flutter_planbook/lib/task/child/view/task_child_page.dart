import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/planbook_api.dart';

/// 在指定位置显示任务子任务的 overlay
///
/// [context] - 用于获取 overlay 的 BuildContext
/// [task] - 要显示子任务的父任务
/// [targetRect] - 触发按钮的位置矩形
/// [onCompleted] - 子任务完成回调
/// [onDeleted] - 子任务删除回调
/// [onEdited] - 子任务编辑回调
/// [onPressed] - 子任务点击回调
Future<void> showTaskChildOverlay(
  BuildContext context, {
  required TaskEntity task,
  required Rect targetRect,
  ValueChanged<TaskEntity>? onCompleted,
  ValueChanged<TaskEntity>? onDeleted,
  ValueChanged<TaskEntity>? onEdited,
  ValueChanged<TaskEntity>? onPressed,
}) {
  return Navigator.of(context).push(
    _TaskChildOverlayRoute(
      task: task,
      targetRect: targetRect,
      onCompleted: onCompleted,
      onDeleted: onDeleted,
      onEdited: onEdited,
      onPressed: onPressed,
    ),
  );
}

class _TaskChildOverlayRoute extends PopupRoute<void> {
  _TaskChildOverlayRoute({
    required this.task,
    required this.targetRect,
    this.onCompleted,
    this.onDeleted,
    this.onEdited,
    this.onPressed,
  });

  final TaskEntity task;
  final Rect targetRect;
  final ValueChanged<TaskEntity>? onCompleted;
  final ValueChanged<TaskEntity>? onDeleted;
  final ValueChanged<TaskEntity>? onEdited;
  final ValueChanged<TaskEntity>? onPressed;

  @override
  Color? get barrierColor => Colors.black26;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _TaskChildOverlay(
      task: task,
      targetRect: targetRect,
      animation: animation,
      onCompleted: onCompleted,
      onDeleted: onDeleted,
      onEdited: onEdited,
      onPressed: onPressed,
      onDismiss: () => Navigator.of(context).pop(),
    );
  }
}

class _TaskChildOverlay extends StatelessWidget {
  const _TaskChildOverlay({
    required this.task,
    required this.targetRect,
    required this.animation,
    this.onCompleted,
    this.onDeleted,
    this.onEdited,
    this.onPressed,
    this.onDismiss,
  });

  final TaskEntity task;
  final Rect targetRect;
  final Animation<double> animation;
  final ValueChanged<TaskEntity>? onCompleted;
  final ValueChanged<TaskEntity>? onDeleted;
  final ValueChanged<TaskEntity>? onEdited;
  final ValueChanged<TaskEntity>? onPressed;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = task.priority.getColorScheme(context);
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // 使用原任务项的位置和宽度
    final overlayLeft = targetRect.left;
    final overlayWidth = targetRect.width;

    // 计算子任务列表的最大高度
    final maxChildrenHeight =
        (screenSize.height - padding.top - padding.bottom) * 0.5;

    // 计算子任务列表的高度
    final childCount = task.children.length;
    // 每个子任务的预估高度
    const itemHeight = 48.0;
    // 计算子任务内容高度
    final childrenContentHeight = childCount * itemHeight + 16;
    final childrenHeight = childrenContentHeight.clamp(80.0, maxChildrenHeight);

    // 父任务显示在原位置
    final parentTop = targetRect.top;
    final parentHeight = targetRect.height;

    // 子任务列表显示在父任务下方
    final childrenTop = parentTop + parentHeight;

    // 检查子任务列表是否超出屏幕底部
    final availableSpace =
        screenSize.height - childrenTop - padding.bottom - 16;
    final actualChildrenHeight = childrenHeight.clamp(0.0, availableSpace);

    return Stack(
      children: [
        // 父任务（保持原位置）
        Positioned(
          left: overlayLeft,
          top: parentTop,
          width: overlayWidth,
          height: parentHeight,
          child: FadeTransition(
            opacity: animation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 展开图标
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        FontAwesomeIcons.listCheck,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    // 任务标题
                    Expanded(
                      child: Text(
                        task.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 关闭按钮
                    CupertinoButton(
                      padding: const EdgeInsets.all(12),
                      minimumSize: const Size(44, 44),
                      onPressed: onDismiss,
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 18,
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 子任务列表（在父任务下方展开）
        Positioned(
          left: overlayLeft,
          top: childrenTop,
          width: overlayWidth,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(
              opacity: animation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(maxHeight: actualChildrenHeight),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: task.children.length,
                    itemBuilder: (context, index) {
                      final child = task.children[index];
                      return TaskListTile.priority(
                        task: child,
                        titleTextStyle: theme.textTheme.bodyMedium,
                        onPressed: (task) {
                          onDismiss?.call();
                          onPressed?.call(child);
                        },
                        onCompleted: (task) => onCompleted?.call(child),
                        onDeleted: (task) {
                          onDismiss?.call();
                          onDeleted?.call(child);
                        },
                        onEdited: (task) {
                          onDismiss?.call();
                          onEdited?.call(child);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
