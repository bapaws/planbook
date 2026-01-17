part of 'discover_journal_bloc.dart';

final class DiscoverJournalState extends Equatable {
  const DiscoverJournalState({
    required this.date,
    this.status = PageStatus.initial,
    this.isCalendarExpanded = false,
  });

  final PageStatus status;

  final Jiffy date;

  int get year => date.year;
  int get days {
    final startOfYear = date.startOf(Unit.year);
    return startOfYear.add(years: 1).diff(startOfYear, unit: Unit.day).toInt();
  }

  final bool isCalendarExpanded;

  @override
  List<Object> get props => [
    status,
    isCalendarExpanded,
    date,
  ];

  DiscoverJournalState copyWith({
    PageStatus? status,
    bool? isCalendarExpanded,
    Jiffy? date,
  }) {
    return DiscoverJournalState(
      status: status ?? this.status,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
      date: date ?? this.date,
    );
  }
}
