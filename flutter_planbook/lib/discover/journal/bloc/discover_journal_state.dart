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
    this.coverBackgroundImage,
    this.coverColorScheme,
  });

  final PageStatus status;

  final JournalDate date;

  final Jiffy? autoPlayFrom;
  final Jiffy? autoPlayTo;

  final String? coverBackgroundImage;
  final material.ColorScheme? coverColorScheme;

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
    coverBackgroundImage,
    coverColorScheme,
  ];

  DiscoverJournalState copyWith({
    PageStatus? status,
    bool? isCalendarExpanded,
    JournalDate? date,
    Jiffy? autoPlayFrom,
    Jiffy? autoPlayTo,
    bool? isLeftEnlarged,
    bool? isRightEnlarged,
    String? coverBackgroundImage,
    material.ColorScheme? coverColorScheme,
  }) {
    return DiscoverJournalState(
      status: status ?? this.status,
      isCalendarExpanded: isCalendarExpanded ?? this.isCalendarExpanded,
      date: date ?? this.date,
      autoPlayFrom: autoPlayFrom ?? this.autoPlayFrom,
      autoPlayTo: autoPlayTo ?? this.autoPlayTo,
      isLeftEnlarged: isLeftEnlarged ?? this.isLeftEnlarged,
      isRightEnlarged: isRightEnlarged ?? this.isRightEnlarged,
      coverBackgroundImage: coverBackgroundImage ?? this.coverBackgroundImage,
      coverColorScheme: coverColorScheme ?? this.coverColorScheme,
    );
  }
}
