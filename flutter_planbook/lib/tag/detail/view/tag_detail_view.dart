import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_empty_note_view.dart';
import 'package:flutter_planbook/core/view/app_empty_task_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/list/view/note_list_view.dart';
import 'package:flutter_planbook/tag/detail/bloc/tag_detail_bloc.dart';
import 'package:flutter_planbook/task/list/bloc/task_list_bloc.dart';
import 'package:flutter_planbook/task/list/view/task_list_view.dart';
import 'package:planbook_api/entity/note_entity.dart';
import 'package:planbook_api/entity/task_entity.dart';
import 'package:planbook_core/data/page_status.dart';

class TagDetailView extends StatelessWidget {
  const TagDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final tagId = context.read<TagDetailBloc>().state.tag.id;
    return TabBarView(
      children: [
        _TagDetailTasksTab(tagId: tagId),
        const _TagDetailNotesTab(),
      ],
    );
  }
}

class _TagDetailTasksTab extends StatelessWidget {
  const _TagDetailTasksTab({required this.tagId});

  final String tagId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskListBloc(
        tasksRepository: context.read(),
        taskActionService: context.read(),
        mode: TaskListMode.tag,
      )..add(TaskListRequested(tagId: tagId)),
      child: MultiBlocListener(
        listeners: [
          BlocListener<TaskListBloc, TaskListState>(
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
        child: BlocBuilder<TaskListBloc, TaskListState>(
          builder: (context, state) {
            if (state.status == PageStatus.loading && state.tasks.isEmpty) {
              return const SizedBox.shrink();
            }
            if (state.tasks.isEmpty) {
              return AppEmptyTaskView(title: context.l10n.noData);
            }
            return CustomScrollView(
              slivers: [
                TaskListView(tasks: state.tasks),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TagDetailNotesTab extends StatelessWidget {
  const _TagDetailNotesTab();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      TagDetailBloc,
      TagDetailState,
      (PageStatus, List<NoteEntity>)
    >(
      selector: (state) => (state.status, state.notes),
      builder: (context, data) {
        final (status, notes) = data;
        if (status == PageStatus.loading && notes.isEmpty) {
          return const SizedBox.shrink();
        }
        if (notes.isEmpty) {
          return const AppEmptyNoteView();
        }
        return NoteListView(
          notes: notes,
          showDate: true,
          onDeleted: (note) {
            context.read<TagDetailBloc>().add(TagDetailNoteDeleted(note: note));
          },
        );
      },
    );
  }
}
