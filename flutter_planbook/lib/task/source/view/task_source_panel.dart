import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/root/home/bloc/root_home_bloc.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:flutter_planbook/root/task/bloc/root_task_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_delete_dialog.dart';
import 'package:flutter_planbook/task/list/view/task_drag_target.dart';
import 'package:flutter_planbook/task/list/view/task_drag_to_day.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:flutter_planbook/task/source/bloc/task_source_bloc.dart';
import 'package:flutter_planbook/task/source/model/task_source_panel_type.dart';
import 'package:flutter_planbook/task/source/picker/model/task_source_panel_picker_result.dart';
import 'package:flutter_planbook/task/week/model/task_week_view_mode.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

/// 侧栏外观：独立右侧栏，或嵌入八宫格第一格。
enum TaskSourcePanelVariant { sidebar, embedded }

/// 右侧任务列
///
/// 显示收集箱 / 指定标签 / 指定日期（全部/全天/非全天），支持与主视图双向拖拽。
///
/// 需在上层提供 [TaskSourcePanelBloc]。
class TaskSourcePanel extends StatelessWidget {
  const TaskSourcePanel({
    this.variant = TaskSourcePanelVariant.sidebar,
    this.showTitle = true,
    super.key,
  });

  /// 嵌入八宫格第一格：无固定宽度、底栏边距和圆角卡片。
  const TaskSourcePanel.embedded({super.key})
    : variant = TaskSourcePanelVariant.embedded,
      showTitle = false;

  final TaskSourcePanelVariant variant;
  final bool showTitle;

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

  static String titleOf(BuildContext context, TaskSourcePanelType sourceType) {
    final l10n = context.l10n;
    return switch (sourceType) {
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

  static IconData iconOf(TaskSourcePanelType sourceType) {
    return switch (sourceType) {
      TaskSourcePanelInbox() => CupertinoIcons.tray,
      TaskSourcePanelTag() => CupertinoIcons.tag,
      TaskSourcePanelDate(filter: TaskSourcePanelDateFilter.allDay) =>
        CupertinoIcons.sun_max,
      TaskSourcePanelDate(filter: TaskSourcePanelDateFilter.notAllDay) =>
        CupertinoIcons.clock,
      TaskSourcePanelDate() => CupertinoIcons.calendar,
    };
  }

  /// 打开数据源选择器，并按 [variant] 处理「隐藏」结果。
  static Future<void> openPicker(
    BuildContext context, {
    required TaskSourcePanelType initialSourceType,
    TaskSourcePanelVariant variant = TaskSourcePanelVariant.sidebar,
    bool showSourceTypeSelector = true,
  }) async {
    final tags = context.read<RootHomeBloc>().state.topLevelTags;
    final result = await context.router.push<TaskSourcePanelPickerResult?>(
      TaskSourcePanelPickerRoute(
        initialSourceType: initialSourceType,
        tags: tags,
        showSourceTypeSelector: showSourceTypeSelector,
      ),
    );
    if (result == null || !context.mounted) return;
    applyPickerResult(context, result, variant: variant);
  }

  static void applyPickerResult(
    BuildContext context,
    TaskSourcePanelPickerResult result, {
    TaskSourcePanelVariant variant = TaskSourcePanelVariant.sidebar,
  }) {
    if (result.closePanel) {
      if (variant == TaskSourcePanelVariant.embedded) {
        context.read<RootTaskBloc>().add(
          const RootTaskWeekGridCellKindChanged(
            kind: TaskWeekGridCellKind.note,
          ),
        );
      } else {
        context.read<RootTaskBloc>().add(
          const RootTaskSourcePanelVisibilityChanged(showSourcePanel: false),
        );
      }
      return;
    }
    final sourceType = result.sourceType;
    if (sourceType == null) return;
    context.read<TaskSourcePanelBloc>().add(
      TaskSourcePanelSourceChanged(sourceType),
    );
    if (variant == TaskSourcePanelVariant.embedded) {
      context.read<RootTaskBloc>().add(
        const RootTaskWeekGridCellKindChanged(
          kind: TaskWeekGridCellKind.source,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TaskSourcePanelView(
      variant: variant,
      showTitle: showTitle,
    );
  }
}

class _TaskSourcePanelView extends StatelessWidget {
  const _TaskSourcePanelView({
    required this.variant,
    required this.showTitle,
  });

  final TaskSourcePanelVariant variant;
  final bool showTitle;

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
          if (variant == TaskSourcePanelVariant.embedded) {
            return SizedBox.expand(
              child: ColoredBox(
                color: isHovering
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                child: child,
              ),
            );
          }
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
            clipBehavior: Clip.hardEdge,
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
            if (showTitle) _SourcePanelTitle(variant: variant),
            Expanded(
              child: BlocBuilder<TaskSourcePanelBloc, TaskSourcePanelState>(
                builder: (context, state) {
                  final titleTextStyle =
                      variant == TaskSourcePanelVariant.embedded
                      ? Theme.of(context).textTheme.bodySmall
                      : null;
                  if (variant == TaskSourcePanelVariant.embedded) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: state.tasks.length,
                      itemBuilder: (context, index) {
                        return _buildTaskTile(
                          context,
                          state.tasks[index],
                          titleTextStyle: titleTextStyle,
                        );
                      },
                    );
                  }
                  return ListView.separated(
                    itemCount: state.tasks.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 4);
                    },
                    itemBuilder: (context, index) {
                      return _buildTaskTile(context, state.tasks[index]);
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

  Widget _buildTaskTile(
    BuildContext context,
    TaskEntity task, {
    TextStyle? titleTextStyle,
  }) {
    return TaskListTile.week(
      key: ValueKey(task),
      task: task,
      titleTextStyle: titleTextStyle,
      contentWrapper: (child) => TaskDraggable(
        task: task,
        feedbackBuilder: _buildDragFeedback,
        onDragCompleted: (task) {
          context.read<TaskSourcePanelBloc>().add(
            TaskSourcePanelTaskDragCompleted(task),
          );
        },
        child: child,
      ),
      onPressed: (task) => _openTaskDetail(context, task),
      onEdited: (task) => _openTaskEdit(context, task),
      onDeleted: (task) => unawaited(
        _deleteTask(context, task),
      ),
      onCompleted: (task) {
        context.read<TaskSourcePanelBloc>().add(
          TaskSourcePanelTaskCompleted(task),
        );
      },
    );
  }

  Widget _buildDragFeedback(BuildContext context, TaskEntity task) {
    final isEmbedded = variant == TaskSourcePanelVariant.embedded;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            height: isEmbedded ? 28 : 36,
            child: TaskListTile.week(
              task: task,
              titleTextStyle: isEmbedded
                  ? Theme.of(context).textTheme.bodySmall
                  : null,
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: FaIcon(
              FontAwesomeIcons.circlePlus,
              size: isEmbedded ? 18 : 24,
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

  Future<void> _deleteTask(BuildContext context, TaskEntity task) async {
    final RecurringTaskDeleteMode? mode;
    if (task.recurrenceRule == null) {
      final confirmed = await showDeleteConfirmationDialog(context);
      mode = confirmed ? RecurringTaskDeleteMode.allEvents : null;
    } else {
      mode = await showDeleteModeSelectionDialog(
        context,
        hasOccurrence: task.occurrence?.occurrenceAt != null,
      );
    }
    if (mode == null || !context.mounted) return;
    context.read<TaskSourcePanelBloc>().add(
      TaskSourcePanelTaskDeleted(task: task, mode: mode),
    );
  }
}

class _SourcePanelTitle extends StatelessWidget {
  const _SourcePanelTitle({required this.variant});

  final TaskSourcePanelVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BlocBuilder<TaskSourcePanelBloc, TaskSourcePanelState>(
      builder: (context, state) {
        return CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          minimumSize: const Size(kMinInteractiveDimension, 36),
          onPressed: () => TaskSourcePanel.openPicker(
            context,
            initialSourceType: state.sourceType,
            variant: variant,
          ),
          child: Row(
            children: [
              Icon(
                TaskSourcePanel.iconOf(state.sourceType),
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  TaskSourcePanel.titleOf(context, state.sourceType),
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
}
