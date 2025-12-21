import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/core/model/task_priority.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:pull_down_button/pull_down_button.dart';

/// 统一的任务列表项组件
///
/// 提供三种预设样式：
/// - [TaskListTile] - 默认样式，用于标准列表视图
/// - [TaskListTile.priority] - 优先级视图样式，更紧凑
/// - [TaskListTile.week] - 周视图样式，最紧凑
class TaskListTile extends StatefulWidget {
  /// 默认样式构造函数（标准列表视图）
  const TaskListTile({
    required this.task,
    required this.onPressed,
    required this.onCompleted,
    required this.onDeleted,
    required this.onEdited,
    this.onDelayed,
    this.titleTextStyle,
    super.key,
  }) : checkboxPadding = const EdgeInsets.all(16),
       checkboxMinimumSize = kMinInteractiveDimension,
       checkboxSize = 18;

  /// 优先级视图样式构造函数
  const TaskListTile.priority({
    required this.task,
    required this.onPressed,
    required this.onCompleted,
    required this.onDeleted,
    required this.onEdited,
    this.onDelayed,
    this.titleTextStyle,
    super.key,
  }) : checkboxPadding = const EdgeInsets.all(8),
       checkboxMinimumSize = 36,
       checkboxSize = 16;

  /// 周视图样式构造函数
  const TaskListTile.week({
    required this.task,
    required this.onPressed,
    required this.onCompleted,
    required this.onDeleted,
    required this.onEdited,
    this.titleTextStyle,
    super.key,
  }) : onDelayed = null,
       checkboxPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       checkboxMinimumSize = 25,
       checkboxSize = 14;

  final TaskEntity task;
  final VoidCallback onPressed;
  final VoidCallback onCompleted;
  final VoidCallback onDeleted;
  final VoidCallback onEdited;
  final VoidCallback? onDelayed;

  /// 复选框的内边距
  final EdgeInsetsGeometry checkboxPadding;

  /// 复选框的最小尺寸
  final double checkboxMinimumSize;

  /// 复选框图标大小
  final double checkboxSize;

  /// 标题文本样式（如果为 null，则使用默认样式）
  final TextStyle? titleTextStyle;

  @override
  State<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends State<TaskListTile> {
  late TaskEntity _task;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _isCompleted = _task.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = _task.priority.getColorScheme(context);

    return PullDownButton(
      itemBuilder: (context) => _buildMenuItems(l10n),
      buttonBuilder: (context, showMenu) => CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.square(widget.checkboxMinimumSize),
        onLongPress: showMenu,
        onPressed: widget.onPressed,
        child: Row(
          children: [
            IntrinsicHeight(
              child: CupertinoButton(
                padding: widget.checkboxPadding,
                minimumSize: Size.square(widget.checkboxMinimumSize),
                onPressed: _toggleCompleted,
                child: Icon(
                  _isCompleted
                      ? FontAwesomeIcons.solidSquareCheck
                      : FontAwesomeIcons.square,
                  size: widget.checkboxSize,
                  color: _isCompleted
                      ? colorScheme.outline
                      : colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: Durations.short2,
                style:
                    widget.titleTextStyle?.copyWith(
                      color: _isCompleted
                          ? colorScheme.outline
                          : colorScheme.onSurface,
                    ) ??
                    TextStyle(
                      color: _isCompleted
                          ? colorScheme.outline
                          : colorScheme.onSurface,
                    ),
                child: Text(
                  _task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PullDownMenuEntry> _buildMenuItems(AppLocalizations l10n) {
    return [
      if (widget.onDelayed != null)
        PullDownMenuItem(
          icon: FontAwesomeIcons.clock,
          title: l10n.delayToToday,
          onTap: widget.onDelayed,
        ),
      PullDownMenuItem(
        icon: FontAwesomeIcons.penToSquare,
        title: l10n.edit,
        onTap: widget.onEdited,
      ),
      const PullDownMenuDivider.large(),
      PullDownMenuItem(
        icon: FontAwesomeIcons.trash,
        title: l10n.delete,
        isDestructive: true,
        onTap: widget.onDeleted,
      ),
    ];
  }

  void _toggleCompleted() {
    setState(() {
      _isCompleted = !_isCompleted;
    });
    widget.onCompleted();
  }
}
