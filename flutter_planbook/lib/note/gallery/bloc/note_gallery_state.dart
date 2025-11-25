part of 'note_gallery_bloc.dart';

final class NoteGalleryState extends Equatable {
  const NoteGalleryState({
    required this.date,
    this.status = PageStatus.initial,
    this.noteImages = const {},
  });

  final PageStatus status;
  final Jiffy date;

  final Map<Jiffy, List<NoteImageEntity>> noteImages;

  @override
  List<Object?> get props => [status, date, noteImages];

  NoteGalleryState copyWith({
    PageStatus? status,
    Jiffy? date,
    Map<Jiffy, List<NoteImageEntity>>? noteImages,
  }) {
    return NoteGalleryState(
      status: status ?? this.status,
      date: date ?? this.date,
      noteImages: noteImages ?? this.noteImages,
    );
  }
}
