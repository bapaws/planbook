part of 'root_journal_bloc.dart';

final class RootJournalState extends Equatable {
  const RootJournalState({
    this.status = PageStatus.initial,
    this.year = 0,
    this.startYear = 0,
    this.endYear = 0,
    this.days = 365,
  });

  final PageStatus status;
  final int startYear;
  final int endYear;

  final int year;
  final int days;

  @override
  List<Object> get props => [status, year, startYear, endYear, days];

  RootJournalState copyWith({
    PageStatus? status,
    int? year,
    int? startYear,
    int? endYear,
    int? days,
  }) {
    return RootJournalState(
      status: status ?? this.status,
      year: year ?? this.year,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      days: days ?? this.days,
    );
  }
}
