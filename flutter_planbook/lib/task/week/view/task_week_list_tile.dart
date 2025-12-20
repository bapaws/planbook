import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/core/model/task_priority.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:pull_down_button/pull_down_button.dart';

class TaskWeekListTile extends StatefulWidget {
  const TaskWeekListTile({
    required this.task,
    required this.onPressed,
    required this.onCompleted,
    required this.onDeleted,
    required this.onEdited,
    super.key,
  });

  final TaskEntity task;
  final VoidCallback onPressed;
  final VoidCallback onCompleted;
  final VoidCallback onDeleted;
  final VoidCallback onEdited;

  @override
  State<TaskWeekListTile> createState() => _TaskWeekListTileState();
}

class _TaskWeekListTileState extends State<TaskWeekListTile> {
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
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final colorScheme = _task.priority.getColorScheme(context);
    return PullDownButton(
      itemBuilder: (context) => [
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
      ],
      buttonBuilder: (context, showMenu) => CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onLongPress: showMenu,
        onPressed: widget.onPressed,
        child: Row(
          children: [
            IntrinsicHeight(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size.square(25),
                onPressed: () {
                  setState(() {
                    _isCompleted = !_isCompleted;
                  });
                  widget.onCompleted();
                },
                child: Icon(
                  _isCompleted
                      ? FontAwesomeIcons.solidSquareCheck
                      : FontAwesomeIcons.square,
                  size: 14,
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
}
