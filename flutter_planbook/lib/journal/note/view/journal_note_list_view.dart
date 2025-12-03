import 'package:flutter/material.dart';
import 'package:flutter_planbook/journal/note/view/journal_note_list_tile.dart';
import 'package:planbook_api/entity/note_entity.dart';

class JournalNoteListView extends StatelessWidget {
  const JournalNoteListView({
    required this.notes,
    super.key,
  });

  final List<NoteEntity> notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final note in notes) JournalNoteListTile(note: note),
      ],
    );
  }
}
