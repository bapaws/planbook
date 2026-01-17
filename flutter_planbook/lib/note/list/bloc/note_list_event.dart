part of 'note_list_bloc.dart';

sealed class NoteListEvent extends Equatable {
  const NoteListEvent();

  @override
  List<Object?> get props => [];
}

class NoteListRequested extends NoteListEvent {
  const NoteListRequested({
    required this.date,
    this.tagIds,
    this.modes = NoteListMode.values,
  });

  final Jiffy date;
  final List<String>? tagIds;
  final List<NoteListMode> modes;

  @override
  List<Object?> get props => [date, tagIds, modes];
}

final class NoteListDeleted extends NoteListEvent {
  const NoteListDeleted({required this.note});

  final NoteEntity note;

  @override
  List<Object?> get props => [note];
}
