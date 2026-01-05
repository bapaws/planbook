part of 'note_gallery_bloc.dart';

sealed class NoteGalleryEvent extends Equatable {
  const NoteGalleryEvent();

  @override
  List<Object?> get props => [];
}

final class NoteGalleryRequested extends NoteGalleryEvent {
  const NoteGalleryRequested({required this.date});

  final Jiffy date;

  @override
  List<Object?> get props => [date];
}

final class NoteGalleryDateSelected extends NoteGalleryEvent {
  const NoteGalleryDateSelected({required this.date});

  final Jiffy date;

  @override
  List<Object?> get props => [date];
}

final class NoteGalleryCalendarToggled extends NoteGalleryEvent {
  const NoteGalleryCalendarToggled();

  @override
  List<Object?> get props => [];
}
