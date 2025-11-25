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
