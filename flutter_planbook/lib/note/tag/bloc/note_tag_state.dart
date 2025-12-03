part of 'note_tag_bloc.dart';

final class NoteTagState extends Equatable {
  const NoteTagState({
    required this.tag,
    this.status = PageStatus.initial,
    this.notes = const [],
  });

  final TagEntity tag;
  final PageStatus status;
  final List<NoteEntity> notes;

  @override
  List<Object> get props => [tag, status, notes];

  NoteTagState copyWith({
    TagEntity? tag,
    PageStatus? status,
    List<NoteEntity>? notes,
  }) {
    return NoteTagState(
      tag: tag ?? this.tag,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
