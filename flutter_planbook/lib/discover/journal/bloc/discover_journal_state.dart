part of 'discover_journal_bloc.dart';

enum DiscoverJournalViewType {
  flip,
  horizontal,
}

final class DiscoverJournalState extends Equatable {
  const DiscoverJournalState({
    required this.date,
    this.viewType = DiscoverJournalViewType.flip,
    this.status = PageStatus.initial,
    this.isCalendarExpanded = false,
    this.autoPlayFrom,
    this.autoPlayTo,
  });

  final PageStatus status;

  final Jiffy date;

  final DiscoverJournalViewType viewType;

  final Jiffy? autoPlayFrom;
  final Jiffy? autoPlayTo;

  int get year => date.year;
  int get days {
    final startOfYear = date.startOf(Unit.year);
    return startOfYear.add(years: 1).diff(startOfYear, unit: Unit.day).toInt();
  }

  final bool isCalendarExpanded;

  @override
  List<Object?> get props => [
    status,
    viewType,
    isCalendarExpanded,
    date,
    autoPlayFrom,
    autoPlayTo,
  ];

  DiscoverJournalState copyWith({
    PageStatus? status,
    DiscoverJournalViewType? viewType,
    bool? isCalendarExpanded,
    Jiffy? date,
    Jiffy? autoPlayFrom,
    Jiffy? autoPlayTo,
  }) {
    return DiscoverJournalState(
      status: status ?? this.status,
      viewType: viewType ?? this.viewType,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
      date: date ?? this.date,
      autoPlayFrom: autoPlayFrom ?? this.autoPlayFrom,
      autoPlayTo: autoPlayTo ?? this.autoPlayTo,
    );
  }
}
