part of 'note_gallery_bloc.dart';

final class NoteGalleryState extends Equatable {
  const NoteGalleryState({
    required this.date,
    this.status = PageStatus.initial,
    this.noteImages = const {},
    this.isCalendarExpanded = false,
  });

  final PageStatus status;
  final Jiffy date;
  final bool isCalendarExpanded;
  final Map<Jiffy, List<NoteImageEntity>> noteImages;

  @override
  List<Object?> get props => [status, date, noteImages, isCalendarExpanded];

  NoteGalleryState copyWith({
    PageStatus? status,
    Jiffy? date,
    Map<Jiffy, List<NoteImageEntity>>? noteImages,
    bool? isCalendarExpanded,
  }) {
    return NoteGalleryState(
      status: status ?? this.status,
      date: date ?? this.date,
      noteImages: noteImages ?? this.noteImages,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
    );
  }
}
