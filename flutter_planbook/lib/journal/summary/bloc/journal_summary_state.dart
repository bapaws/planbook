part of 'journal_summary_bloc.dart';

final class JournalSummaryState extends Equatable {
  const JournalSummaryState({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.totalNotes = 0,
    this.totalWords = 0,
  });

  final int totalTasks;
  final int completedTasks;

  final int totalNotes;
  final int totalWords;

  @override
  List<Object> get props => [
    totalTasks,
    completedTasks,
    totalNotes,
    totalWords,
  ];

  JournalSummaryState copyWith({
    int? totalTasks,
    int? completedTasks,
    int? totalNotes,
    int? totalWords,
  }) {
    return JournalSummaryState(
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      totalNotes: totalNotes ?? this.totalNotes,
      totalWords: totalWords ?? this.totalWords,
    );
  }
}
