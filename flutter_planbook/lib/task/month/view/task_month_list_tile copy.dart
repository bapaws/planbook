import 'dart:async' show unawaited;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_repository/settings/settings_repository.dart';

class TaskMonthListTile extends StatefulWidget {
  const TaskMonthListTile({
    required this.task,
    required this.height,
    required this.fontSize,
    required this.colorScheme,
    super.key,
  });

  final TaskEntity task;
  final double height;
  final double fontSize;
  final ColorScheme colorScheme;

  @override
  State<TaskMonthListTile> createState() => _TaskMonthListTileState();
}

class _TaskMonthListTileState extends State<TaskMonthListTile> {
  TaskEntity get task => widget.task;
  ColorScheme get colorScheme => widget.colorScheme;

  bool _isCompleted = false;
  set isCompleted(bool value) {
    if (_isCompleted != value) {
      setState(() {
        _isCompleted = value;
      });
    }
  }

  bool get isCompleted => _isCompleted;

  @override
  void initState() {
    super.initState();
    isCompleted = widget.task.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        context.router.push(
          TaskDetailRoute(
            taskId: task.id,
            occurrenceAt: task.occurrence?.occurrenceAt,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        height: widget.height,
        decoration: BoxDecoration(
          color: isCompleted
              ? colorScheme.surfaceContainer
              : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            // const SizedBox(width: 4),
            // Container(
            //   width: 6,
            //   height: 6,
            //   decoration: BoxDecoration(
            //     shape: BoxShape.circle,
            //     color: isCompleted ? colorScheme.outline : colorScheme.primary,
            //   ),
            // ),
            // const SizedBox(width: 4),
            CupertinoButton(
              padding: EdgeInsets.symmetric(
                horizontal: (widget.height - widget.fontSize) / 2,
              ),
              minimumSize: Size.square(widget.height),
              onPressed: () {
                isCompleted = !isCompleted;
                context.read<TaskListBloc>().add(TaskListCompleted(task: task));
                _playCompletedSound();
              },
              child: Icon(
                isCompleted
                    ? FontAwesomeIcons.solidCircleCheck
                    : FontAwesomeIcons.circle,
                size: widget.fontSize,
                color: isCompleted ? colorScheme.outline : colorScheme.primary,
              ),
            ),
            Expanded(
              child: Text(
                task.task.title,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: widget.fontSize,
                  color: isCompleted
                      ? theme.colorScheme.outline
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
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
