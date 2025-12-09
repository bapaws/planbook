import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/tag/list/bloc/tag_list_bloc.dart';
import 'package:flutter_planbook/task/new/cubit/task_new_cubit.dart';
import 'package:flutter_planbook/task/new/view/task_new_bottom_bar.dart';
import 'package:flutter_planbook/task/new/view/task_new_date_picker.dart';
import 'package:flutter_planbook/task/new/view/task_new_date_view.dart';
import 'package:flutter_planbook/task/new/view/task_new_duration_bottom_view.dart';
import 'package:flutter_planbook/task/new/view/task_new_priority_bottom_view.dart';
import 'package:flutter_planbook/task/new/view/task_new_repeat_view.dart';
import 'package:flutter_planbook/task/new/view/task_new_tag_bottom_view.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class TaskNewPage extends StatelessWidget {
  const TaskNewPage({this.initialTask, this.dueAt, super.key});

  final TaskEntity? initialTask;
  final Jiffy? dueAt;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TaskNewCubit(
            tasksRepository: context.read(),
            initialTask: initialTask,
            dueAt: dueAt,
          ),
        ),
        BlocProvider(
          create: (context) => TagListBloc(
            tagsRepository: context.read(),
            mode: TagListMode.multiSelect,
          )..add(const TagListRequested()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<TagListBloc, TagListState>(
            listenWhen: (previous, current) =>
                previous.selectedTagIds != current.selectedTagIds,
            listener: (context, state) {
              final selectedTagIds = state.selectedTagIds;
              final selectedTags = state.tags
                  .where((tag) => selectedTagIds.contains(tag.id))
                  .toList();
              context.read<TaskNewCubit>().onTagsChanged(selectedTags);
            },
          ),
          BlocListener<TaskNewCubit, TaskNewState>(
            listenWhen: (previous, current) =>
                previous.status == PageStatus.loading &&
                current.status == PageStatus.success &&
                previous.tags != current.tags &&
                current.tags.isNotEmpty,
            listener: (context, state) {
              // 当草稿恢复后，同步 tags 到 TagListBloc
              final tagListBloc = context.read<TagListBloc>();
              final currentSelectedTags = tagListBloc.state.selectedTagIds;
              final selectedTags = tagListBloc.state.tags
                  .where((tag) => currentSelectedTags.contains(tag.id))
                  .toList();
              context.read<TaskNewCubit>().onTagsChanged(selectedTags);
            },
          ),
          BlocListener<TaskNewCubit, TaskNewState>(
            listenWhen: (previous, current) =>
                previous.status != current.status &&
                current.status == PageStatus.success,
            listener: (context, state) {
              context.pop();
            },
          ),
        ],
        child: const _TaskNewPage(),
      ),
    );
  }
}

class _TaskNewPage extends StatefulWidget {
  const _TaskNewPage();

  @override
  State<_TaskNewPage> createState() => _TaskNewPageState();
}

class _TaskNewPageState extends State<_TaskNewPage> {
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<TaskNewCubit>();
      final state = cubit.state;
      _titleController.text = state.initialTask?.title ?? state.title;
      _titleFocusNode.requestFocus();
      cubit.onFocusChanged(TaskNewFocus.title);

      if (state.tags.isNotEmpty) {
        context.read<TagListBloc>().add(TagListMultiSelected(tags: state.tags));
      }
    });

    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        context.read<TaskNewCubit>().onFocusChanged(TaskNewFocus.title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final query = MediaQuery.of(context);
    final maxHeight = query.size.height - query.padding.vertical;
    return BlocListener<TaskNewCubit, TaskNewState>(
      listenWhen: (previous, current) =>
          previous.initialTask != current.initialTask,
      listener: (context, state) {
        if (state.initialTask != null) {
          context.read<TaskNewCubit>().onTitleChanged(state.initialTask!.title);
        }
      },
      child: AppPageScaffold(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocSelector<TaskNewCubit, TaskNewState, Jiffy?>(
              selector: (state) => state.date,
              builder: (context, date) {
                return TaskNewDateView(
                  date: date,
                  onDateChanged: (date) {
                    _onDateChanged(context, date);
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              decoration: InputDecoration(
                hintText: l10n.taskTitleHint,
                hintStyle: textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                isDense: true,
              ),
              minLines: 3,
              maxLines: 20,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              onChanged: (value) {
                context.read<TaskNewCubit>().onTitleChanged(value);
              },
            ),
            const SizedBox(height: 12),
            TaskNewBottomBar(focusNode: _titleFocusNode),
            BlocSelector<TaskNewCubit, TaskNewState, TaskNewFocus>(
              selector: (state) => state.focus,
              builder: (context, focus) {
                return AnimatedSwitcher(
                  duration: Durations.medium1,
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  ),
                  child: _buildBottomView(focus),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomView(TaskNewFocus focus) {
    return switch (focus) {
      TaskNewFocus.none => SizedBox(
        height: MediaQuery.of(context).padding.bottom,
      ),
      TaskNewFocus.title => SizedBox(
        height: MediaQuery.of(context).viewInsets.bottom,
      ),
      TaskNewFocus.priority => TaskNewPriorityBottomView(
        selectedPriority: context.read<TaskNewCubit>().state.priority,
        onPriorityChanged: (priority) {
          context.read<TaskNewCubit>().onPriorityChanged(priority);
        },
      ),
      TaskNewFocus.date => TaskNewDatePicker(
        date: context.read<TaskNewCubit>().state.date,
        onDateChanged: (date) {
          _onDateChanged(context, date);
        },
      ),
      TaskNewFocus.time => const TaskNewDurationBottomView(),
      TaskNewFocus.tags => const TaskNewTagBottomView(),
      TaskNewFocus.recurrence => TaskNewRecurrenceRuleView(
        initialRecurrenceRule: context
            .read<TaskNewCubit>()
            .state
            .recurrenceRule,
      ),
    };
  }

  void _onDateChanged(BuildContext context, Jiffy? date) {
    context.read<TaskNewCubit>().onDueAtChanged(date);

    context.read<TaskNewCubit>().onFocusChanged(
      TaskNewFocus.title,
    );
    FocusScope.of(context).requestFocus();
  }
}
