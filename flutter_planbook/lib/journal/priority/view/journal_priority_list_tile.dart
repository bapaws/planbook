import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/task_entity.dart';

class JournalPriorityListTile extends StatelessWidget {
  const JournalPriorityListTile({
    required this.task,
    super.key,
  });

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IntrinsicHeight(
          child: Icon(
            task.isCompleted
                ? FontAwesomeIcons.solidSquareCheck
                : FontAwesomeIcons.square,
            size: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: Durations.short2,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: task.isCompleted
                  ? Colors.grey
                  : theme.colorScheme.onSurface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  task.title,
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
    );
  }
}
