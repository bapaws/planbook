import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/core/model/task_priority.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:pull_down_button/pull_down_button.dart';

class TaskPriorityListTile extends StatefulWidget {
  const TaskPriorityListTile({
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
  State<TaskPriorityListTile> createState() => _TaskPriorityListTileState();
}

class _TaskPriorityListTileState extends State<TaskPriorityListTile> {
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
        // minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
        onLongPress: showMenu,
        onPressed: widget.onPressed,
        child: Row(
          children: [
            IntrinsicHeight(
              child: CupertinoButton(
                padding: const EdgeInsets.all(8),
                minimumSize: const Size.square(36),
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
                  size: 16,
                  color: _isCompleted
                      ? colorScheme.outline
                      : colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: Durations.short2,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: _isCompleted
                      ? colorScheme.outline
                      : colorScheme.onSurface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      _task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // if (_task.tags.isNotEmpty) ...[
                    //   const SizedBox(height: 4),
                    //   Wrap(
                    //     spacing: 4,
                    //     runSpacing: 4,
                    //     children: _task.tags
                    //         .map((tag) => AppTagView(tag: tag))
                    //         .toList(),
                    //   ),
                    // ],
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
