import 'package:flutter/material.dart';
import 'package:flutter_planbook/task/priority/view/task_priority_list_view.dart';
import 'package:planbook_repository/planbook_repository.dart';

class TaskPriorityPage extends StatelessWidget {
  const TaskPriorityPage({
    required this.mode,
    super.key,
    this.date,
    this.tag,
  });

  final TaskListMode mode;
  final Jiffy? date;
  final TagEntity? tag;

  static const spacing = 12.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildTaskPriorityPage(
                context,
                TaskPriority.high,
              ),
              _buildTaskPriorityPage(
                context,
                TaskPriority.medium,
              ),
            ],
          ),
        ),
        const SizedBox(height: spacing),
        Expanded(
          child: Row(
            children: [
              _buildTaskPriorityPage(
                context,
                TaskPriority.low,
              ),
              _buildTaskPriorityPage(
                context,
                TaskPriority.none,
              ),
            ],
          ),
        ),
        const SizedBox(
          height: kToolbarHeight + 22 + 8,
        ),
      ],
    );
  }

  Widget _buildTaskPriorityPage(BuildContext context, TaskPriority priority) {
    return Expanded(
      child: TaskPriorityListView(
        priority: priority,
      ),
    );
  }
}
