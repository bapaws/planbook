import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_repository/settings/settings_repository.dart';
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
    this.onPressed,
    this.onCompleted,
    this.onDeleted,
    this.onEdited,
    this.onDelayed,
    this.isExpanded = false,
    this.titleTextStyle,
    this.onExpanded,
    super.key,
  }) : checkboxPadding = const EdgeInsets.all(12),
       checkboxMinimumSize = kMinInteractiveDimension,
       checkboxSize = 21;

  /// 优先级视图样式构造函数
  const TaskListTile.priority({
    required this.task,
    this.onPressed,
    this.onCompleted,
    this.onDeleted,
    this.onEdited,
    this.onDelayed,
    this.isExpanded = false,
    this.titleTextStyle,
    this.onExpanded,
    super.key,
  }) : checkboxPadding = const EdgeInsets.all(8),
       checkboxMinimumSize = 36,
       checkboxSize = 18;

  /// 周视图样式构造函数
  const TaskListTile.week({
    required this.task,
    this.onPressed,
    this.onCompleted,
    this.onDeleted,
    this.onEdited,
    this.isExpanded = false,
    this.titleTextStyle,
    this.onExpanded,
    super.key,
  }) : onDelayed = null,
       checkboxPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       checkboxMinimumSize = 28,
       checkboxSize = 16;

  final TaskEntity task;
  final ValueChanged<TaskEntity>? onPressed;
  final ValueChanged<TaskEntity>? onCompleted;
  final ValueChanged<TaskEntity>? onDeleted;
  final ValueChanged<TaskEntity>? onEdited;
  final ValueChanged<TaskEntity>? onDelayed;
  final ValueChanged<TaskEntity>? onExpanded;

  final bool isExpanded;

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
  final GlobalKey _tileKey = GlobalKey();

  late TaskEntity _task;
  set task(TaskEntity value) {
    _task = value;

    if (_isCompleted != _task.isCompleted) {
      setState(() {
        _isCompleted = _task.isCompleted;
      });
    }

    if (!_task.isCompleted) {
      final now = Jiffy.now();
      final today = now.startOf(Unit.day);
      if (_task.occurrence != null) {
        final endAt = _task.occurrence!.endAt;
        if (endAt != null && endAt.isBefore(now)) {
          _isOverdue = true;
          _isOverdueNow = true;
        } else {
          final occurrenceAt =
              _task.occurrence!.dueAt ?? _task.occurrence!.occurrenceAt;
          _isOverdue = occurrenceAt.isBefore(today);
          _isOverdueNow = false;
        }
      } else {
        final endAt = _task.endAt;
        if (endAt != null && endAt.isBefore(now)) {
          _isOverdue = true;
          _isOverdueNow = true;
        } else {
          final occurrenceAt = _task.dueAt ?? _task.occurrenceAt;
          _isOverdue = occurrenceAt != null && occurrenceAt.isBefore(today);
          _isOverdueNow = false;
        }
      }
    } else {
      _isOverdue = false;
    }
  }

  TaskEntity get task => _task;

  bool _isCompleted = false;
  bool _isExpanded = false;

  bool _isOverdue = false;
  bool _isOverdueNow = false;

  Size get minimumSize => Size.square(
    _task.parentId == null
        ? widget.checkboxMinimumSize
        : (widget.checkboxMinimumSize / 4 * 3).floorToDouble(),
  );

  EdgeInsetsGeometry get buttonPadding => _task.parentId == null
      ? widget.checkboxPadding
      : widget.checkboxPadding * 3 ~/ 4;

  @override
  void initState() {
    super.initState();
    task = widget.task;

    _isExpanded = widget.isExpanded;
  }

  @override
  void didUpdateWidget(TaskListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 更新任务
    task = widget.task;
    if (widget.isExpanded != _isExpanded) {
      setState(() {
        _isExpanded = widget.isExpanded;
      });
    }
    if (widget.task.isCompleted != _isCompleted) {
      setState(() {
        _isCompleted = widget.task.isCompleted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.onDeleted == null &&
        widget.onEdited == null &&
        widget.onDelayed == null) {
      return _buildButton(context, null);
    }
    return PullDownButton(
      itemBuilder: (context) => _buildMenuItems(l10n),
      buttonBuilder: _buildButton,
    );
  }

  Widget _buildButton(BuildContext context, VoidCallback? showMenu) {
    final colorScheme = _task.priority.getColorScheme(context);

    final isEmptyChildren = _task.children.isEmpty;
    return CupertinoButton(
      key: _tileKey,
      padding: EdgeInsets.zero,
      minimumSize: minimumSize,
      onLongPress: showMenu,
      onPressed: widget.onPressed == null
          ? null
          : () => widget.onPressed!.call(_task),
      child: Row(
        children: [
          if (_task.parentId != null) ...[
            SizedBox(width: widget.checkboxMinimumSize / 2 - 1),
            SizedBox(
              height: minimumSize.height + 2,
              child: VerticalDivider(
                width: 1,
                color: colorScheme.surfaceContainerHighest,
                thickness: 1,
              ),
            ),
            const SizedBox(width: 8),
          ],
          CupertinoButton(
            padding: buttonPadding,
            minimumSize: minimumSize,
            onPressed: isEmptyChildren ? _toggleCompleted : _onExpanded,
            child: isEmptyChildren
                ? Icon(
                    _isCompleted
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    size: widget.checkboxSize,
                    color: _isCompleted
                        ? colorScheme.outline
                        : colorScheme.onSurface,
                  )
                : AnimatedRotation(
                    turns: _isExpanded ? 0 : -0.25,
                    duration: Durations.medium1,
                    child: Icon(
                      _isCompleted
                          ? CupertinoIcons.chevron_down_circle_fill
                          : CupertinoIcons.chevron_down_circle,
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
          SizedBox(width: buttonPadding.horizontal / 2),
        ],
      ),
    );
  }

  List<PullDownMenuEntry> _buildMenuItems(AppLocalizations l10n) {
    return [
      PullDownMenuItem(
        icon: FontAwesomeIcons.solidCircleCheck,
        title: _isCompleted ? l10n.uncompleteTask : l10n.completeTask,
        onTap: () => context.router.push(TaskDoneRoute(task: _task)),
      ),
      const PullDownMenuDivider.large(),
      if (_isOverdue)
        PullDownMenuItem(
          icon: FontAwesomeIcons.clock,
          title: _isOverdueNow ? l10n.delayToTomorrow : l10n.delayToToday,
          onTap: () => widget.onDelayed?.call(_task),
        ),
      PullDownMenuItem(
        icon: FontAwesomeIcons.penToSquare,
        title: l10n.edit,
        onTap: () => widget.onEdited?.call(_task),
      ),
      const PullDownMenuDivider.large(),
      PullDownMenuItem(
        icon: FontAwesomeIcons.trash,
        title: l10n.delete,
        isDestructive: true,
        onTap: () => widget.onDeleted?.call(_task),
      ),
    ];
  }

  void _toggleCompleted() {
    if (widget.onCompleted == null) return;

    setState(() {
      _isCompleted = !_isCompleted;
    });
    widget.onCompleted?.call(_task);

    /// 播放完成音效
    _playCompletedSound();
  }

  void _onExpanded() {
    widget.onExpanded?.call(_task);
  }

  Future<void> _playCompletedSound() async {
    unawaited(HapticFeedback.lightImpact());

    final sound = await context
        .read<SettingsRepository>()
        .getTaskCompletedSound();
    if (sound != null && sound.isNotEmpty) {
      final player = AudioPlayer();
      await player.play(AssetSource(sound));
    }
  }
}
