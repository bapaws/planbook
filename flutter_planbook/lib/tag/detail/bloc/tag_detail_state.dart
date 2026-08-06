part of 'tag_detail_bloc.dart';

final class TagDetailState extends Equatable {
  const TagDetailState({
    required this.tag,
    this.status = PageStatus.initial,
    this.notes = const [],
  });

  final TagEntity tag;
  final PageStatus status;
  final List<NoteEntity> notes;

  @override
  List<Object?> get props => [tag, status, notes];

  TagDetailState copyWith({
    TagEntity? tag,
    PageStatus? status,
    List<NoteEntity>? notes,
  }) {
    return TagDetailState(
      tag: tag ?? this.tag,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
