part of 'discover_journal_bloc.dart';

sealed class DiscoverJournalEvent extends Equatable {
  const DiscoverJournalEvent();

  @override
  List<Object?> get props => [];
}

final class DiscoverJournalRequested extends DiscoverJournalEvent {
  const DiscoverJournalRequested({required this.year});

  final int year;

  @override
  List<Object> get props => [year];
}

final class DiscoverJournalYearChanged extends DiscoverJournalEvent {
  const DiscoverJournalYearChanged({required this.year});

  final int year;

  @override
  List<Object> get props => [year];
}

final class DiscoverJournalDateChanged extends DiscoverJournalEvent {
  const DiscoverJournalDateChanged({required this.date});

  final JournalDate date;

  @override
  List<Object> get props => [date];
}

final class DiscoverJournalCalendarToggled extends DiscoverJournalEvent {
  const DiscoverJournalCalendarToggled({this.isExpanded});

  final bool? isExpanded;

  @override
  List<Object?> get props => [isExpanded];
}

final class DiscoverJournalLeftEnlargedToggled extends DiscoverJournalEvent {
  const DiscoverJournalLeftEnlargedToggled({this.isEnlarged});

  final bool? isEnlarged;

  @override
  List<Object> get props => [isEnlarged ?? false];
}

final class DiscoverJournalRightEnlargedToggled extends DiscoverJournalEvent {
  const DiscoverJournalRightEnlargedToggled({this.isEnlarged});

  final bool? isEnlarged;

  @override
  List<Object> get props => [isEnlarged ?? false];
}
