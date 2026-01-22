part of 'discover_focus_bloc.dart';

sealed class DiscoverFocusEvent extends Equatable {
  const DiscoverFocusEvent();

  @override
  List<Object?> get props => [];
}

final class DiscoverFocusRequested extends DiscoverFocusEvent {
  const DiscoverFocusRequested({this.date, this.noteType});

  final Jiffy? date;
  final NoteType? noteType;

  @override
  List<Object?> get props => [date, noteType];
}

final class DiscoverFocusNodeSelected extends DiscoverFocusEvent {
  const DiscoverFocusNodeSelected({required this.node});

  final NoteMindMapEntity node;

  @override
  List<Object> get props => [node];
}

final class DiscoverFocusAllNodesExpanded extends DiscoverFocusEvent {
  const DiscoverFocusAllNodesExpanded();

  @override
  List<Object> get props => [];
}

final class DiscoverFocusCalendarExpanded extends DiscoverFocusEvent {
  const DiscoverFocusCalendarExpanded();

  @override
  List<Object> get props => [];
}

final class DiscoverFocusCalendarDateSelected extends DiscoverFocusEvent {
  const DiscoverFocusCalendarDateSelected({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}
