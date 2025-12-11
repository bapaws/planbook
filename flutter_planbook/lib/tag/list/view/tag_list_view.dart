import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/tag/list/bloc/tag_list_bloc.dart';
import 'package:flutter_planbook/tag/list/view/tag_list_tile.dart';
import 'package:flutter_planbook/tag/new/view/tag_new_button.dart';

class TagListView extends StatelessWidget {
  const TagListView({
    this.showAddButton = false,
    this.scrollController,
    super.key,
  });

  final bool showAddButton;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final mode = context.read<TagListBloc>().mode;
    return BlocBuilder<TagListBloc, TagListState>(
      builder: (context, state) {
        return ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.only(
            top: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          itemCount: state.tags.length + (showAddButton ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.tags.length) {
              return const Center(child: TagNewButton());
            }
            final tag = state.tags[index];
            final isSelected = mode.isSelectable
                ? state.selectedTagIds.contains(tag.id)
                : null;
            return TagListTile(
              tag: tag,
              isSelected: isSelected,
              onSelected: () {
                if (mode.isSelectable) {
                  context.read<TagListBloc>().add(TagListSelected(tag: tag));
                }
              },
              onDeleted: () {
                context.read<TagListBloc>().add(TagListDeleted(tag: tag));
              },
              onEdited: () {
                context.router.push(TagNewRoute(initialTag: tag));
              },
            );
          },
        );
      },
    );
  }
}
