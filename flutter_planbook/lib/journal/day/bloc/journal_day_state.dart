part of 'journal_day_bloc.dart';

final class JournalDayState extends Equatable {
  const JournalDayState({
    required this.date,
    this.tasks = const {},
    this.notes = const {},
    this.focusNote,
    this.summaryNote,
  });

  final Jiffy date;

  final Note? focusNote;
  final Note? summaryNote;

  final Map<int, List<TaskEntity>> tasks;
  final Map<int, List<NoteEntity>> notes;
  @override
  List<Object?> get props => [date, focusNote, summaryNote, tasks, notes];

  JournalDayState copyWith({
    Jiffy? date,
    Map<int, List<TaskEntity>>? tasks,
    Map<int, List<NoteEntity>>? notes,
    Note? focusNote,
    Note? summaryNote,
  }) {
    return JournalDayState(
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
      notes: notes ?? this.notes,
      focusNote: focusNote ?? this.focusNote,
      summaryNote: summaryNote ?? this.summaryNote,
    );
  }
}
