import 'package:flutter/material.dart';
import 'package:flutter_planbook/note/list/view/note_list_tile.dart';
import 'package:flutter_planbook/root/home/view/root_home_bottom_bar.dart';
import 'package:planbook_api/entity/note_entity.dart';

class NoteListView extends StatelessWidget {
  const NoteListView({
    required this.notes,
    this.showDate = false,
    this.onDeleted,
    super.key,
  });

  final List<NoteEntity> notes;
  final bool showDate;

  final ValueChanged<NoteEntity>? onDeleted;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: PrimaryScrollController.of(context),
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom + kRootBottomBarHeight + 16,
      ),
      itemCount: notes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteListTile(
          key: ValueKey(note.id),
          note: note,
          showDate: showDate,
          onDeleted: () => onDeleted?.call(note),
        );
      },
    );
  }
}
