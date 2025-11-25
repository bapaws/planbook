part of 'root_note_bloc.dart';

sealed class RootNoteEvent extends Equatable {
  const RootNoteEvent();

  @override
  List<Object?> get props => [];
}

final class RootNoteRequested extends RootNoteEvent {
  const RootNoteRequested();
}

final class RootNoteTabSelected extends RootNoteEvent {
  const RootNoteTabSelected({required this.tab});

  final RootNoteTab tab;

  @override
  List<Object?> get props => [tab];
}

final class RootNoteTagSelected extends RootNoteEvent {
  const RootNoteTagSelected({required this.tag});

  final TagEntity tag;

  @override
  List<Object?> get props => [tag];
}

final class RootNoteDateSelected extends RootNoteEvent {
  const RootNoteDateSelected({required this.date, required this.tab});

  final Jiffy date;
  final RootNoteTab tab;

  @override
  List<Object?> get props => [date, tab];
}
