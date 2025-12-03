part of 'journal_timeline_bloc.dart';

sealed class JournalTimelineEvent extends Equatable {
  const JournalTimelineEvent();

  @override
  List<Object> get props => [];
}

final class JournalTimelineRequested extends JournalTimelineEvent {
  const JournalTimelineRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class JournalTimelineTaskCountRequested extends JournalTimelineEvent {
  const JournalTimelineTaskCountRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}
