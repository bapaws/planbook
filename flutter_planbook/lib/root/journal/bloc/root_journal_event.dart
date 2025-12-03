part of 'root_journal_bloc.dart';

sealed class RootJournalEvent extends Equatable {
  const RootJournalEvent();

  @override
  List<Object> get props => [];
}

final class RootJournalRequested extends RootJournalEvent {
  const RootJournalRequested();

  @override
  List<Object> get props => [];
}

final class RootJournalYearChanged extends RootJournalEvent {
  const RootJournalYearChanged({required this.year});

  final int year;

  @override
  List<Object> get props => [year];
}
