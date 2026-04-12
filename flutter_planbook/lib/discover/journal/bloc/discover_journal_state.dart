part of 'discover_journal_bloc.dart';

final class DiscoverJournalState extends Equatable {
  const DiscoverJournalState({
    required this.date,
    this.status = PageStatus.initial,
    this.isCalendarExpanded = false,
    this.autoPlayFrom,
    this.autoPlayTo,
    this.isLeftEnlarged = false,
    this.isRightEnlarged = false,
  });

  final PageStatus status;

  final Jiffy date;

  final Jiffy? autoPlayFrom;
  final Jiffy? autoPlayTo;

  int get year => date.year;
  int get days {
    final startOfYear = date.startOf(Unit.year);
    return startOfYear.add(years: 1).diff(startOfYear, unit: Unit.day).toInt();
  }

  final bool isCalendarExpanded;
  final bool isLeftEnlarged;
  final bool isRightEnlarged;

  @override
  List<Object?> get props => [
    status,
    isCalendarExpanded,
    date,
    autoPlayFrom,
    autoPlayTo,
    isLeftEnlarged,
    isRightEnlarged,
  ];

  DiscoverJournalState copyWith({
    PageStatus? status,
    bool? isCalendarExpanded,
    Jiffy? date,
    Jiffy? autoPlayFrom,
    Jiffy? autoPlayTo,
    bool? isLeftEnlarged,
    bool? isRightEnlarged,
  }) {
    return DiscoverJournalState(
      status: status ?? this.status,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
      date: date ?? this.date,
      autoPlayFrom: autoPlayFrom ?? this.autoPlayFrom,
      autoPlayTo: autoPlayTo ?? this.autoPlayTo,
      isLeftEnlarged: isLeftEnlarged ?? this.isLeftEnlarged,
      isRightEnlarged: isRightEnlarged ?? this.isRightEnlarged,
    );
  }
}
