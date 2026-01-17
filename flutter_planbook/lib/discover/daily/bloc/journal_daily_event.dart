part of 'journal_daily_bloc.dart';

sealed class JournalDailyEvent extends Equatable {
  const JournalDailyEvent();

  @override
  List<Object> get props => [];
}

final class JournalDailyRequested extends JournalDailyEvent {
  const JournalDailyRequested();
}

final class JournalDailyPlannedTasksRequested extends JournalDailyEvent {
  const JournalDailyPlannedTasksRequested();
}

final class JournalDailyTasksRequested extends JournalDailyEvent {
  const JournalDailyTasksRequested();
}

final class JournalDailyNotesRequested extends JournalDailyEvent {
  const JournalDailyNotesRequested();
}

final class JournalDailyNoteTypeRequested extends JournalDailyEvent {
  const JournalDailyNoteTypeRequested({required this.noteType});

  final NoteType noteType;

  @override
  List<Object> get props => [noteType];
}

final class JournalDailyTaskPriorityCountRequested extends JournalDailyEvent {
  const JournalDailyTaskPriorityCountRequested({required this.priority});

  final TaskPriority priority;

  @override
  List<Object> get props => [priority];
}
