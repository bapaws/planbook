import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/core/view/app_empty_task_view.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/list/view/note_list_tile.dart';
import 'package:flutter_planbook/search/bloc/search_bloc.dart';
import 'package:flutter_planbook/tag/list/view/tag_list_tile.dart';
import 'package:flutter_planbook/task/list/view/task_list_tile.dart';
import 'package:planbook_core/data/page_status.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state.query.isEmpty) {
          return const SizedBox.shrink();
        }

        if (state.status == PageStatus.loading) {
          return const SizedBox.shrink();
        }

        if (!state.hasResults) {
          return AppEmptyTaskView(
            title: context.l10n.noSearchResults,
          );
        }

        return CustomScrollView(
          slivers: [
            if (state.tags.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(title: context.l10n.searchTags),
              ),
              SliverList.builder(
                itemCount: state.tags.length,
                itemBuilder: (context, index) {
                  final tag = state.tags[index];
                  return TagListTile(
                    tag: tag,
                    onSelected: () {
                      context.router.push(TagDetailRoute(tag: tag));
                    },
                    onDetail: () {
                      context.router.push(TagDetailRoute(tag: tag));
                    },
                    onEdited: () {
                      context.router.push(TagNewRoute(initialTag: tag));
                    },
                  );
                },
              ),
            ],
            if (state.tasks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(title: context.l10n.searchTasks),
              ),
              SliverList.builder(
                itemCount: state.tasks.length,
                itemBuilder: (context, index) {
                  final task = state.tasks[index];
                  return TaskListTile(
                    task: task,
                    onPressed: (t) {
                      context.router.push(
                        TaskDetailRoute(
                          taskId: t.parentId ?? t.id,
                          occurrenceAt: t.occurrence?.occurrenceAt,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
            if (state.notes.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(title: context.l10n.searchNotes),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: state.notes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final note = state.notes[index];
                    return NoteListTile(
                      note: note,
                      showDate: true,
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
