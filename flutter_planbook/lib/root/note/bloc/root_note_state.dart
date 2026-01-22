part of 'root_note_bloc.dart';

enum RootNoteTab {
  timeline,
  written,
  task,
  gallery,
  tag,
}

final class RootNoteState extends Equatable {
  const RootNoteState({
    required this.galleryDate,
    required this.tagDate,
    this.status = PageStatus.initial,
    this.tag,
  });

  final PageStatus status;

  final Jiffy galleryDate;
  final Jiffy tagDate;
  final TagEntity? tag;

  @override
  List<Object?> get props => [
    status,
    galleryDate,
    tagDate,
    tag,
  ];

  RootNoteState copyWith({
    PageStatus? status,
    Jiffy? galleryDate,
    Jiffy? tagDate,
    TagEntity? tag,
  }) {
    return RootNoteState(
      status: status ?? this.status,
      tag: tag ?? this.tag,
      galleryDate: galleryDate ?? this.galleryDate,
      tagDate: tagDate ?? this.tagDate,
    );
  }
}
