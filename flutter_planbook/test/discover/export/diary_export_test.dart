import 'package:flutter_planbook/discover/export/view/diary_export_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planbook_repository/planbook_repository.dart';

void main() {
  test('只保留指定年份写下的日记', () {
    final notes = [
      _note('this-year', '2026-10-23'),
      _note('last-year', '2025-12-31'),
      _note('next-year', '2027-01-01'),
    ];

    final selected = diaryNotesForYear(notes, 2026);

    expect(selected.map((note) => note.id), ['this-year']);
  });
}

NoteEntity _note(String id, String day) => NoteEntity(
  note: Note(
    id: id,
    title: 'A quiet afternoon',
    content: 'A little story to remember.',
    images: const [],
    createdAt: Jiffy.parse(day),
  ),
);
