import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/model/task_priority_x.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart'
    show TaskListTile;
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_repository/settings/settings_repository.dart';

/// 统一的任务列表项组件
///
/// 提供三种预设样式：
/// - [TaskListTile] - 默认样式，用于标准列表视图
/// - [TaskListTile.priority] - 优先级视图样式，更紧凑
/// - [TaskListTile.week] - 周视图样式，最紧凑
class TaskMonthListTile extends StatefulWidget {
  /// 默认样式构造函数（标准列表视图）
  const TaskMonthListTile({
    required this.task,
    required this.height,
    required this.fontSize,
    required this.colorScheme,
    this.isExpanded = false,
    super.key,
  });

  final TaskEntity task;
  final double height;
  final double fontSize;
  final ColorScheme colorScheme;

  final bool isExpanded;

  @override
  State<TaskMonthListTile> createState() => _TaskMonthListTileState();
}

class _TaskMonthListTileState extends State<TaskMonthListTile> {
  late TaskEntity _task;
  set task(TaskEntity value) {
    _task = value;

    if (_isCompleted != _task.isCompleted) {
      setState(() {
        _isCompleted = _task.isCompleted;
      });
    }
  }

  TaskEntity get task => _task;

  bool _isCompleted = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    task = widget.task;

    _isExpanded = widget.isExpanded;
  }

  @override
  void didUpdateWidget(TaskMonthListTile oldWidget) {
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
    final theme = Theme.of(context);
    final colorScheme = _task.priority.getColorScheme(context);

    final isEmptyChildren = _task.children.isEmpty;
    return GestureDetector(
      onTap: () {
        context.router.push(
          TaskDetailRoute(
            taskId: _task.parentId ?? _task.id,
            occurrenceAt: _task.occurrence?.occurrenceAt,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(
          left: _task.parentId != null
              ? (widget.height / 2).floorToDouble()
              : 0,
          bottom: 1,
        ),
        height: widget.height,
        decoration: BoxDecoration(
          color: _isCompleted
              ? widget.colorScheme.surfaceContainer
              : widget.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.symmetric(
                horizontal: (widget.height - widget.fontSize) / 2,
              ),
              minimumSize: Size.square(widget.height),
              onPressed: isEmptyChildren ? _toggleCompleted : _onExpanded,
              child: isEmptyChildren
                  ? Icon(
                      _isCompleted
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: widget.fontSize,
                      color: _isCompleted
                          ? colorScheme.outline
                          : colorScheme.primary,
                    )
                  : AnimatedRotation(
                      turns: _isExpanded ? 0 : -0.25,
                      duration: Durations.medium1,
                      child: Icon(
                        _isCompleted
                            ? CupertinoIcons.chevron_down_circle_fill
                            : CupertinoIcons.chevron_down_circle,
                        size: widget.fontSize,
                        color: _isCompleted
                            ? colorScheme.outline
                            : colorScheme.primary,
                      ),
                    ),
            ),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: Durations.short2,
                style: theme.textTheme.bodySmall!.copyWith(
                  fontSize: widget.fontSize,
                  color: _isCompleted
                      ? theme.colorScheme.outline
                      : theme.colorScheme.onSurface,
                ),
                child: Text(
                  _task.title,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ),
            SizedBox(width: (widget.height - widget.fontSize) / 2),
          ],
        ),
      ),
    );
  }

  void _toggleCompleted() {
    setState(() {
      _isCompleted = !_isCompleted;
    });
    context.read<TaskListBloc>().add(TaskListCompleted(task: _task));

    /// 播放完成音效
    _playCompletedSound();
  }

  void _onExpanded() {
    context.read<TaskListBloc>().add(TaskListTaskExpanded(task: _task));
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
