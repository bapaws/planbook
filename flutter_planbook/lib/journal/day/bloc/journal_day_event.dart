part of 'journal_day_bloc.dart';

sealed class JournalDayEvent extends Equatable {
  const JournalDayEvent();

  @override
  List<Object> get props => [];
}

final class JournalDayRequested extends JournalDayEvent {
  const JournalDayRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class JournalTodayTasksRequested extends JournalDayEvent {
  const JournalTodayTasksRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class JournalTodayNotesRequested extends JournalDayEvent {
  const JournalTodayNotesRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class JournalDayTasksRequested extends JournalDayEvent {
  const JournalDayTasksRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class JournalDayNotesRequested extends JournalDayEvent {
  const JournalDayNotesRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class JournalDayFocusNoteRequested extends JournalDayEvent {
  const JournalDayFocusNoteRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}

final class JournalDaySummaryNoteRequested extends JournalDayEvent {
  const JournalDaySummaryNoteRequested({required this.date});

  final Jiffy date;

  @override
  List<Object> get props => [date];
}
