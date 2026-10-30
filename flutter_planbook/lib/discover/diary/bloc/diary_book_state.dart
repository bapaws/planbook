part of 'diary_book_bloc.dart';

final class DiaryBookState extends Equatable {
  const DiaryBookState({
    this.status = PageStatus.initial,
    this.notes = const [],
  });

  final PageStatus status;
  final List<NoteEntity> notes;

  DiaryBookState copyWith({PageStatus? status, List<NoteEntity>? notes}) {
    return DiaryBookState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [status, notes];
}
