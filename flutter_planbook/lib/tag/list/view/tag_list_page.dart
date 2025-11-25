import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/tag/list/bloc/tag_list_bloc.dart';
import 'package:flutter_planbook/tag/list/view/tag_list_view.dart';
import 'package:planbook_repository/planbook_repository.dart';

@RoutePage()
class TagListPage extends StatelessWidget {
  const TagListPage({
    required this.mode,
    required this.selectedTags,
    super.key,
  });
  final TagListMode mode;
  final List<TagEntity> selectedTags;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TagListBloc(
              tagsRepository: context.read(),
              mode: mode,
            )
            ..add(const TagListRequested())
            ..add(TagListMultiSelected(tags: selectedTags)),
      child: const TagListView(),
    );
  }
}
