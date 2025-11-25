part of 'note_list_bloc.dart';

final class NoteListState extends Equatable {
  const NoteListState({
    this.status = PageStatus.initial,
    this.notes = const [],
  });

  final PageStatus status;
  final List<NoteEntity> notes;

  @override
  List<Object?> get props => [status, notes];

  NoteListState copyWith({
    PageStatus? status,
    List<NoteEntity>? notes,
  }) {
    return NoteListState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
