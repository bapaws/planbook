import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/journal/priority/view/journal_priority_list_view.dart';
import 'package:planbook_api/database/task_priority.dart';

@RoutePage()
class JournalPriorityPage extends StatelessWidget {
  const JournalPriorityPage({super.key});

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
      ],
    );
  }

  Widget _buildTaskPriorityPage(BuildContext context, TaskPriority priority) {
    return Expanded(
      child: JournalPriorityListView(
        priority: priority,
      ),
    );
  }
}
