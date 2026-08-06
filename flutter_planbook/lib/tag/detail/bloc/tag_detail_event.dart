part of 'tag_detail_bloc.dart';

sealed class TagDetailEvent extends Equatable {
  const TagDetailEvent();

  @override
  List<Object?> get props => [];
}

final class TagDetailRequested extends TagDetailEvent {
  const TagDetailRequested();
}

final class TagDetailNoteDeleted extends TagDetailEvent {
  const TagDetailNoteDeleted({required this.note});

  final NoteEntity note;

  @override
  List<Object?> get props => [note];
}

final class TagDetailDeleted extends TagDetailEvent {
  const TagDetailDeleted();
}
