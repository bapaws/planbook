part of 'journal_note_bloc.dart';

sealed class JournalNoteEvent extends Equatable {
  const JournalNoteEvent();

  @override
  List<Object?> get props => [];
}

final class JournalNoteRequested extends JournalNoteEvent {
  const JournalNoteRequested({required this.date, this.tagIds});
  final Jiffy date;
  final List<String>? tagIds;
  @override
  List<Object?> get props => [date, tagIds];
}
