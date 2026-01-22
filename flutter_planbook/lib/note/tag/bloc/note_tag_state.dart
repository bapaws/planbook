part of 'note_tag_bloc.dart';

final class NoteTagState extends Equatable {
  const NoteTagState({
    this.status = PageStatus.initial,
    this.notes = const [],
  });

  final PageStatus status;
  final List<NoteEntity> notes;

  @override
  List<Object> get props => [status, notes];

  NoteTagState copyWith({
    PageStatus? status,
    List<NoteEntity>? notes,
  }) {
    return NoteTagState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
