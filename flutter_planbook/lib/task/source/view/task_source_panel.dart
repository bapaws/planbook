import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:flutter_planbook/task/list/view/task_drag_to_day.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:flutter_planbook/task/source/bloc/task_source_bloc.dart';
import 'package:flutter_planbook/task/source/model/task_source_panel_type.dart';
import 'package:flutter_planbook/task/source/picker/model/task_source_panel_picker_result.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

/// 右侧任务列
///
/// 显示收集箱 / 指定标签 / 指定日期（全部/全天/非全天），支持与主视图双向拖拽。
///
/// 需在上层提供 [TaskSourcePanelBloc]。
class TaskSourcePanel extends StatelessWidget {
  const TaskSourcePanel({super.key});

  /// 投放到当前数据源是否会产生实际变更。
  ///
  /// 无变更时返回 false，供 willAccept 拒绝，避免原地松手触发乐观移除。
  static bool wouldAcceptDrop(
    TaskSourcePanelType sourceType,
    TaskEntity task,
  ) {
    switch (sourceType) {
      case TaskSourcePanelInbox():
        return task.startAt != null || task.endAt != null || task.dueAt != null;
      case TaskSourcePanelTag(tags: final tags):
        final existingIds = task.tags.map((t) => t.id).toSet();
        return tags.any((tag) => !existingIds.contains(tag.id));
      case TaskSourcePanelDate(date: final date, filter: final filter):
        if (filter == TaskSourcePanelDateFilter.allDay) {
          final targetDate = date.startOf(Unit.day);
          final taskDay = (task.occurrenceAt ?? task.startAt ?? task.dueAt)
              ?.startOf(Unit.day);
          if (task.isAllDay &&
              taskDay != null &&
              taskDay.isSame(targetDate, unit: Unit.day)) {
            return false;
          }
          return true;
        }
        return TaskDropArea.wouldMoveToDay(task, date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const _TaskSourcePanelView();
  }
}

class _TaskSourcePanelView extends StatelessWidget {
  const _TaskSourcePanelView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<RootTaskBloc, RootTaskState>(
          listenWhen: (previous, current) =>
              previous.showCompleted != current.showCompleted ||
              previous.selectedTagIds != current.selectedTagIds,
          listener: (context, state) {
            context.read<TaskSourcePanelBloc>().add(
              TaskSourcePanelFilterChanged(
                isCompleted: state.isCompleted,
                selectedTagIds: state.selectedTagIds,
              ),
            );
          },
        ),
        BlocListener<TaskSourcePanelBloc, TaskSourcePanelState>(
          listenWhen: (previous, current) =>
              previous.currentTaskNote != current.currentTaskNote &&
              current.currentTaskNote != null,
          listener: (context, state) {
            context.router.push(
              NoteNewRoute(initialNote: state.currentTaskNote),
            );
          },
        ),
      ],
      child: TaskDragTarget(
        onWillAcceptWithDetails: (details) {
          final state = context.read<TaskSourcePanelBloc>().state;
          return TaskSourcePanel.wouldAcceptDrop(
            state.sourceType,
            details.data,
          );
        },
        onAccept: (task) {
          context.read<TaskSourcePanelBloc>().add(
            TaskSourcePanelTaskDropped(task),
          );
        },
        builder: (context, child, candidateData) {
          final isHovering = candidateData.isNotEmpty;
          return Container(
            margin: EdgeInsets.only(
              right: 8,
              bottom:
                  kRootBottomBarItemHeight +
                  MediaQuery.of(context).padding.bottom,
            ),
            width: (MediaQuery.of(context).size.width * 0.32).ceilToDouble(),
            constraints: const BoxConstraints(
              minWidth: 136,
              maxWidth: 260,
            ),
            decoration: BoxDecoration(
              color: context.blueColorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovering
                    ? theme.colorScheme.primary
                    : context.blueColorScheme.surfaceContainerHighest,
              ),
            ),
            child: child,
          );
        },
        child: Column(
          children: [
            const _SourcePanelTitle(),
            Expanded(
              child: BlocBuilder<TaskSourcePanelBloc, TaskSourcePanelState>(
                builder: (context, state) {
                  return ListView.separated(
                    itemCount: state.tasks.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 4);
                    },
                    itemBuilder: (context, index) {
                      final task = state.tasks[index];
                      return TaskDraggable(
                        key: ValueKey(task),
                        task: task,
                        feedbackBuilder: _buildDragFeedback,
                        onDragCompleted: (task) {
                          context.read<TaskSourcePanelBloc>().add(
                            TaskSourcePanelTaskDragCompleted(task),
                          );
                        },
                        child: TaskListTile.week(
                          key: ValueKey(task),
                          task: task,
                          onPressed: (task) => _openTaskDetail(context, task),
                          onEdited: (task) => _openTaskEdit(context, task),
                          onCompleted: (task) {
                            context.read<TaskSourcePanelBloc>().add(
                              TaskSourcePanelTaskCompleted(task),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragFeedback(BuildContext context, TaskEntity task) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            height: 36,
            child: TaskListTile.week(task: task),
          ),
          const Positioned(
            top: -8,
            right: -8,
            child: Icon(
              FontAwesomeIcons.circlePlus,
              size: 24,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _openTaskDetail(BuildContext context, TaskEntity task) {
    context.router.push(
      TaskDetailRoute(
        taskId: task.parentId ?? task.id,
        occurrenceAt: task.occurrence?.occurrenceAt,
      ),
    );
  }

  void _openTaskEdit(BuildContext context, TaskEntity task) {
    context.router.push(TaskNewRoute(initialTask: task));
  }
}

class _SourcePanelTitle extends StatelessWidget {
  const _SourcePanelTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BlocBuilder<TaskSourcePanelBloc, TaskSourcePanelState>(
      builder: (context, state) {
        return CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          minimumSize: const Size(kMinInteractiveDimension, 36),
          onPressed: () => _openPicker(context, state),
          child: Row(
            children: [
              _buildSourceIcon(state.sourceType, colorScheme),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _buildTitle(context, state),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_down,
                size: 12,
                color: colorScheme.outline,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceIcon(
    TaskSourcePanelType sourceType,
    ColorScheme colorScheme,
  ) {
    final icon = switch (sourceType) {
      TaskSourcePanelInbox() => CupertinoIcons.tray,
      TaskSourcePanelTag() => CupertinoIcons.tag,
      TaskSourcePanelDate(filter: TaskSourcePanelDateFilter.allDay) =>
        CupertinoIcons.sun_max,
      TaskSourcePanelDate(filter: TaskSourcePanelDateFilter.notAllDay) =>
        CupertinoIcons.clock,
      TaskSourcePanelDate() => CupertinoIcons.calendar,
    };
    return Icon(icon, size: 14, color: colorScheme.primary);
  }

  String _buildTitle(BuildContext context, TaskSourcePanelState state) {
    final l10n = context.l10n;
    return switch (state.sourceType) {
      TaskSourcePanelInbox() => l10n.inbox,
      TaskSourcePanelTag(tags: final tags) =>
        tags.map((t) => t.name).join(', '),
      TaskSourcePanelDate(
        date: final date,
        filter: TaskSourcePanelDateFilter.all,
      ) =>
        date.Md,
      TaskSourcePanelDate(
        date: final date,
        filter: TaskSourcePanelDateFilter.allDay,
      ) =>
        '${date.Md}(${l10n.allDay})',
      TaskSourcePanelDate(
        date: final date,
        filter: TaskSourcePanelDateFilter.notAllDay,
      ) =>
        '${date.Md}(${l10n.notAllDay})',
    };
  }

  Future<void> _openPicker(
    BuildContext context,
    TaskSourcePanelState state,
  ) async {
    final tags = context.read<RootHomeBloc>().state.topLevelTags;
    final result = await context.router.push<TaskSourcePanelPickerResult?>(
      TaskSourcePanelPickerRoute(
        initialSourceType: state.sourceType,
        tags: tags,
      ),
    );
    if (result == null || !context.mounted) return;
    if (result.closePanel) {
      context.read<RootTaskBloc>().add(
        const RootTaskSourcePanelVisibilityChanged(showSourcePanel: false),
      );
      return;
    }
    context.read<TaskSourcePanelBloc>().add(
      TaskSourcePanelSourceChanged(result.sourceType!),
    );
  }
}
