part of 'root_journal_bloc.dart';

sealed class RootJournalState extends Equatable {
  const RootJournalState();
  
  @override
  List<Object> get props => [];
}

final class RootJournalInitial extends RootJournalState {}
