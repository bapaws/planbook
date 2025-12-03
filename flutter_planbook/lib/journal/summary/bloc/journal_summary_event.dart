part of 'journal_summary_bloc.dart';

sealed class JournalSummaryEvent extends Equatable {
  const JournalSummaryEvent();

  @override
  List<Object> get props => [];
}

final class JournalSummaryRequested extends JournalSummaryEvent {
  const JournalSummaryRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}
