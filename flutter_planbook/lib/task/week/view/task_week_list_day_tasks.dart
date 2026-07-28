import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_to_day.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

/// 列表视图每天的任务网格。
class TaskWeekListDayTasksSliver extends StatelessWidget {
  const TaskWeekListDayTasksSliver({
    required this.colorScheme,
    required this.crossAxisCount,
    this.isDemo = false,
    this.demoTasks = const [],
    super.key,
  });

  final ColorScheme colorScheme;
  final int crossAxisCount;

  /// 是否为演示模式（非会员）
  final bool isDemo;

  /// 演示模式下使用的任务列表
  final List<TaskEntity> demoTasks;

  @override
  Widget build(BuildContext context) {
    if (isDemo) {
      return _buildTasksGrid(context, demoTasks);
    }

    return BlocSelector<TaskListBloc, TaskListState, List<TaskEntity>>(
      selector: (state) => state.tasks,
      builder: _buildTasksGrid,
    );
  }

  Widget _buildTasksGrid(BuildContext context, List<TaskEntity> tasks) {
    if (tasks.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox(height: 64));
    }
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisExtent: 36,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildTaskTile(
          context,
          tasks[index],
          index < tasks.length - 1 ? tasks[index + 1] : null,
        ),
        childCount: tasks.length,
      ),
    );
  }

  Widget _buildTaskTile(
    BuildContext context,
    TaskEntity task,
    TaskEntity? nextTask,
  ) {
    // 演示模式：拦截交互，引导付费
    if (isDemo) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.router.push(const AppPurchasesRoute()),
        child: AbsorbPointer(
          child: TaskListTile.week(
            key: ValueKey(task),
            task: task,
            isExpanded: nextTask?.parentId == task.id,
          ),
        ),
      );
    }

    final tile = TaskListTile.week(
      key: ValueKey(task),
      task: task,
      isExpanded: nextTask?.parentId == task.id,
      onPressed: (t) => context.router.push(
        TaskDetailRoute(
          taskId: t.id,
          occurrenceAt: t.occurrence?.occurrenceAt,
        ),
      ),
      onCompleted: (t) => context.read<TaskListBloc>().add(
        TaskListCompleted(task: t),
      ),
      onDeleted: (t) => context.read<TaskListBloc>().add(
        TaskListDeleteRequested(task: t),
      ),
      onEdited: (t) => context.router.push(
        TaskDetailRoute(
          taskId: t.id,
          occurrenceAt: t.occurrence?.occurrenceAt,
        ),
      ),
      onExpanded: (t) => context.read<TaskListBloc>().add(
        TaskListTaskExpanded(task: t),
      ),
    );
    return TaskDraggable(
      task: task,
      feedbackBuilder: _buildDragFeedback,
      onDragCompleted: (task) => context.read<TaskListBloc>().add(
        TaskListTaskDragCompleted(task: task),
      ),
      child: tile,
    );
  }

  Widget _buildDragFeedback(BuildContext context, TaskEntity task) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: colorScheme.surfaceContainerLowest,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            height: 28,
            child: TaskListTile.week(task: task),
          ),
          const Positioned(
            top: -8,
            right: -8,
            child: Icon(
              FontAwesomeIcons.circlePlus,
              size: 18,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

/// 根据任务区可用宽度计算周列表网格列数。
int taskWeekListCrossAxisCount(double crossAxisExtent) {
  if (crossAxisExtent < 300) return 1;
  if (crossAxisExtent < 520) return 2;
  if (crossAxisExtent < 800) return 3;
  if (crossAxisExtent < 1100) return 4;
  return 5;
}
