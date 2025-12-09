part of 'note_tag_bloc.dart';

sealed class NoteTagEvent extends Equatable {
  const NoteTagEvent();

  @override
  List<Object> get props => [];
}

final class NoteTagRequested extends NoteTagEvent {
  const NoteTagRequested({required this.tagId});

  final String tagId;

  @override
  List<Object> get props => [tagId];
}

final class NoteTagDeleted extends NoteTagEvent {
  const NoteTagDeleted({required this.note});

  final NoteEntity note;

  @override
  List<Object> get props => [note];
}
