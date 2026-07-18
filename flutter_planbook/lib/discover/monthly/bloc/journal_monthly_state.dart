part of 'journal_monthly_bloc.dart';

final class JournalMonthlyState extends Equatable {
  const JournalMonthlyState({
    required this.month,
    this.status = PageStatus.initial,
    this.focusNote,
    this.summaryNote,
    this.notes = const [],
    this.images = const [],
    this.completedTasksCount = 0,
    this.plannedTasksCount = 0,
    this.completedByPriority = const {},
    this.noteCount = 0,
    this.wordCount = 0,
    this.dailyFocusNotes = const [],
    this.weeklyFocusNotes = const [],
  });

  final PageStatus status;
  final Jiffy month;
  final Note? focusNote;
  final Note? summaryNote;
  final List<NoteEntity> notes;
  final List<NoteImageEntity> images;
  final int completedTasksCount;
  final int plannedTasksCount;
  final Map<TaskPriority, int> completedByPriority;
  final int noteCount;
  final int wordCount;
  final List<Note?> dailyFocusNotes;
  final List<Note?> weeklyFocusNotes;

  @override
  List<Object?> get props => [
    status,
    month,
    focusNote,
    summaryNote,
    notes,
    images,
    completedTasksCount,
    plannedTasksCount,
    completedByPriority,
    noteCount,
    wordCount,
    dailyFocusNotes,
    weeklyFocusNotes,
  ];

  JournalMonthlyState copyWith({
    PageStatus? status,
    Jiffy? month,
    ValueGetter<Note?>? focusNote,
    ValueGetter<Note?>? summaryNote,
    List<NoteEntity>? notes,
    List<NoteImageEntity>? images,
    int? completedTasksCount,
    int? plannedTasksCount,
    Map<TaskPriority, int>? completedByPriority,
    int? noteCount,
    int? wordCount,
    List<Note?>? dailyFocusNotes,
    List<Note?>? weeklyFocusNotes,
  }) {
    return JournalMonthlyState(
      status: status ?? this.status,
      month: month ?? this.month,
      focusNote: focusNote == null ? this.focusNote : focusNote.call(),
      summaryNote: summaryNote == null ? this.summaryNote : summaryNote.call(),
      notes: notes ?? this.notes,
      images: images ?? this.images,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      plannedTasksCount: plannedTasksCount ?? this.plannedTasksCount,
      completedByPriority: completedByPriority ?? this.completedByPriority,
      noteCount: noteCount ?? this.noteCount,
      wordCount: wordCount ?? this.wordCount,
      dailyFocusNotes: dailyFocusNotes ?? this.dailyFocusNotes,
      weeklyFocusNotes: weeklyFocusNotes ?? this.weeklyFocusNotes,
    );
  }
}
