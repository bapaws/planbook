import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/tag/list/bloc/tag_list_bloc.dart';
import 'package:flutter_planbook/tag/list/view/tag_list_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_api/entity/tag_entity.dart';
import 'package:planbook_core/app/app_scaffold.dart';

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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: AppScaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: Text(context.l10n.selectTags),
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
        body: const TagListView(showAddButton: true),
      ),
    );
  }
}
