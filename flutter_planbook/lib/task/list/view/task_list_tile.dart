import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_repository/settings/settings_repository.dart';

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
    this.onDelayed,
    super.key,
  }) : checkboxPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

class _TaskListTileState extends State<TaskListTile>
    with TickerProviderStateMixin<TaskListTile> {
  late final SlidableController _slidableController = SlidableController(this);

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
    if (widget.onDeleted == null &&
        widget.onEdited == null &&
        widget.onDelayed == null) {
      return _buildButton(context);
    }
    final theme = Theme.of(context);
    return ClipRRect(
      key: ValueKey(task.id),
      child: Slidable(
        controller: _slidableController,
        key: ValueKey(task.id),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.3,
          children: [
            SlidableAction(
              onPressed: (context) {
                context.router.push(TaskDoneRoute(task: _task));
              },
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.primary,
              icon: FontAwesomeIcons.listCheck,
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: _isOverdue ? 0.6 : 0.5,
          children: [
            SlidableAction(
              onPressed: (context) {
                widget.onEdited?.call(_task);
              },
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.primary,
              icon: FontAwesomeIcons.pencil,
            ),
            SlidableAction(
              onPressed: (context) {
                _showDeleteConfirmationDialog();
              },
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.error,
              icon: FontAwesomeIcons.trash,
            ),
            if (_isOverdue && widget.onDelayed != null)
              SlidableAction(
                onPressed: (context) {
                  widget.onDelayed?.call(_task);
                },
                backgroundColor: theme.colorScheme.tertiaryContainer,
                foregroundColor: theme.colorScheme.tertiary,
                icon: FontAwesomeIcons.calendarDay,
              ),
          ],
        ),
        child: _buildButton(context),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    final colorScheme = _task.priority.getColorScheme(context);

    final isEmptyChildren = _task.children.isEmpty;
    return GestureDetector(
      onTap: widget.onPressed == null
          ? null
          : () {
              if (_slidableController.direction.value != 0) {
                _slidableController.close();
                return;
              }
              widget.onPressed!.call(_task);
            },
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

  void _toggleCompleted() {
    if (_slidableController.direction.value != 0) {
      _slidableController.close();
      return;
    }
    if (widget.onCompleted == null) return;

    setState(() {
      _isCompleted = !_isCompleted;
    });
    widget.onCompleted?.call(_task);

    /// 播放完成音效
    _playCompletedSound();
  }

  void _onExpanded() {
    if (_slidableController.direction.value != 0) {
      _slidableController.close();
      return;
    }
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

  void _showDeleteConfirmationDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(context.l10n.deleteTaskAlertTitle),
        content: Text(context.l10n.deleteTaskAlertContent),
        actions: [
          CupertinoDialogAction(
            child: Text(context.l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(context.l10n.delete),
            onPressed: () {
              widget.onDeleted?.call(_task);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
