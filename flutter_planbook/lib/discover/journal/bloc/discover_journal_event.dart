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

final class JournalHomeYearChanged extends DiscoverJournalEvent {
  const JournalHomeYearChanged({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class JournalHomeCalendarToggled extends DiscoverJournalEvent {
  const JournalHomeCalendarToggled();

  @override
  List<Object> get props => [];
}
