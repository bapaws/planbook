part of 'discover_journal_bloc.dart';

sealed class DiscoverJournalEvent extends Equatable {
  const DiscoverJournalEvent();

  @override
  List<Object> get props => [];
}

final class JournalHomeRequested extends DiscoverJournalEvent {
  const JournalHomeRequested();

  @override
  List<Object> get props => [];
}

final class DiscoverJournalDateChanged extends DiscoverJournalEvent {
  const DiscoverJournalDateChanged({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class JournalHomeCalendarToggled extends DiscoverJournalEvent {
  const JournalHomeCalendarToggled();

  @override
  List<Object> get props => [];
}

final class JournalHomeLeftEnlargedToggled extends DiscoverJournalEvent {
  const JournalHomeLeftEnlargedToggled({this.isEnlarged});

  final bool? isEnlarged;

  @override
  List<Object> get props => [isEnlarged ?? false];
}

final class JournalHomeRightEnlargedToggled extends DiscoverJournalEvent {
  const JournalHomeRightEnlargedToggled({this.isEnlarged});

  final bool? isEnlarged;

  @override
  List<Object> get props => [isEnlarged ?? false];
}
