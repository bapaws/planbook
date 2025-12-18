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
    this.tab = RootNoteTab.timeline,
    this.tag,
  });

  final PageStatus status;

  final RootNoteTab tab;

  final Jiffy galleryDate;
  final Jiffy tagDate;
  final TagEntity? tag;

  @override
  List<Object?> get props => [
    status,
    tab,
    galleryDate,
    tagDate,
    tag,
  ];

  RootNoteState copyWith({
    PageStatus? status,
    RootNoteTab? tab,
    Jiffy? galleryDate,
    Jiffy? tagDate,
    TagEntity? tag,
  }) {
    return RootNoteState(
      status: status ?? this.status,
      tab: tab ?? this.tab,
      tag: tag ?? this.tag,
      galleryDate: galleryDate ?? this.galleryDate,
      tagDate: tagDate ?? this.tagDate,
    );
  }
}
