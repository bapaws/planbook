import 'package:flutter/material.dart';
import 'package:flutter_planbook/note/list/view/note_list_tile.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:planbook_api/entity/note_entity.dart';

class NoteListView extends StatelessWidget {
  const NoteListView({
    required this.notes,
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;
  final List<NoteEntity> notes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom + kRootBottomBarHeight + 16,
      ),
      itemCount: notes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return NoteListTile(note: notes[index]);
      },
    );
  }
}
