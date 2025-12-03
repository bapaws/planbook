part of 'journal_note_bloc.dart';

final class JournalNoteState extends Equatable {
  const JournalNoteState({
    this.status = PageStatus.initial,
    this.notes = const [],
    this.coverImage,
    this.noteCount = 0,
    this.wordCount = 0,
  });

  final PageStatus status;
  final List<NoteEntity> notes;

  final String? coverImage;

  final int noteCount;
  final int wordCount;

  @override
  List<Object?> get props => [status, notes, coverImage, noteCount, wordCount];

  JournalNoteState copyWith({
    PageStatus? status,
    List<NoteEntity>? notes,
    String? coverImage,
    int? noteCount,
    int? wordCount,
  }) {
    return JournalNoteState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      coverImage: coverImage ?? this.coverImage,
      noteCount: noteCount ?? this.noteCount,
      wordCount: wordCount ?? this.wordCount,
    );
  }
}
