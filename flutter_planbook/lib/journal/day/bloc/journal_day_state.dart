part of 'journal_day_bloc.dart';

final class JournalDayState extends Equatable {
  const JournalDayState({
    required this.date,
    this.tasks = const {},
    this.notes = const {},
  });

  final Jiffy date;

  final Map<int, List<TaskEntity>> tasks;
  final Map<int, List<NoteEntity>> notes;

  @override
  List<Object> get props => [date];

  JournalDayState copyWith({
    Jiffy? date,
    Map<int, List<TaskEntity>>? tasks,
    Map<int, List<NoteEntity>>? notes,
  }) {
    return JournalDayState(
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
      notes: notes ?? this.notes,
    );
  }
}
