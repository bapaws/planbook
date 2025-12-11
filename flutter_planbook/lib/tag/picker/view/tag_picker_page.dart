import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/tag/list/bloc/tag_list_bloc.dart';
import 'package:flutter_planbook/tag/list/view/tag_list_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/tag_entity.dart';
import 'package:planbook_core/app/app_scaffold.dart';
import 'package:planbook_core/view/navigation_bar_back_button.dart';

@RoutePage()
class TagPickerPage extends StatelessWidget {
  const TagPickerPage({
    required this.selectedTags,
    required this.onSelected,
    super.key,
  });

  final List<TagEntity> selectedTags;
  final ValueChanged<List<TagEntity>> onSelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TagListBloc(
              tagsRepository: context.read(),
              mode: TagListMode.multiSelect,
            )
            ..add(const TagListRequested())
            ..add(TagListMultiSelected(tags: selectedTags)),
      child: _TagPickerPage(onSelected: onSelected),
    );
  }
}

class _TagPickerPage extends StatelessWidget {
  const _TagPickerPage({required this.onSelected});
  final ValueChanged<List<TagEntity>> onSelected;
  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      borderRadius: BorderRadius.circular(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      clipBehavior: Clip.hardEdge,

      child: Column(
        children: [
          AppBar(
            forceMaterialTransparency: true,
            leading: const NavigationBarCloseButton(),
            actions: [
              CupertinoButton(
                onPressed: () {
                  final bloc = context.read<TagListBloc>();
                  final selectedTagIds = bloc.state.selectedTagIds;
                  final selectedTags = bloc.state.tags
                      .where((tag) => selectedTagIds.contains(tag.id))
                      .toList();
                  onSelected(selectedTags);
                  context.router.maybePop();
                },
                child: const Icon(FontAwesomeIcons.check),
              ),
            ],
          ),
          Expanded(
            child: TagListView(
              showAddButton: true,
              scrollController: PrimaryScrollController.of(context),
            ),
          ),
        ],
      ),
    );
  }
}
