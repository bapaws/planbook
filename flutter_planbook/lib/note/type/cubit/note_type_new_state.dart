part of 'note_type_new_cubit.dart';

final class NoteTypeNewState extends Equatable {
  const NoteTypeNewState({
    required this.type,
    required this.focusAt,
    this.status = PageStatus.initial,
    this.initialNote,
    this.title = '',
    this.summaryContent = '',
    this.focusContent = '',
  });

  factory NoteTypeNewState.fromData({
    Note? note,
    NoteType? type,
    Jiffy? focusAt,
  }) {
    final noteType = note?.type ?? type ?? NoteType.dailyFocus;
    return NoteTypeNewState(
      focusAt: focusAt ?? note?.focusAt ?? Jiffy.now(),
      initialNote: note,
      type: type ?? note?.type ?? NoteType.dailyFocus,
      title: note?.title ?? '',
      summaryContent: noteType.isSummary ? note?.content ?? '' : '',
      focusContent: noteType.isFocus ? note?.content ?? '' : '',
    );
  }

  final PageStatus status;
  final Note? initialNote;

  final NoteType type;

  final String title;
  final Jiffy focusAt;

  final String summaryContent;
  final String focusContent;

  String get content => type.isSummary ? summaryContent : focusContent;

  Jiffy get normalizedFocusAt => switch (type) {
    NoteType.dailyFocus || NoteType.dailySummary => focusAt.startOf(Unit.day),
    NoteType.weeklyFocus || NoteType.weeklySummary =>
      focusAt.subtract(days: focusAt.dateTime.weekday - 1).startOf(Unit.day),
    NoteType.monthlyFocus ||
    NoteType.monthlySummary => focusAt.startOf(Unit.month),
    NoteType.yearlyFocus ||
    NoteType.yearlySummary => focusAt.startOf(Unit.year),
    NoteType.journal => throw UnimplementedError(),
  };

  String getTitle(AppLocalizations l10n) => switch (type) {
    NoteType.dailyFocus => l10n.dailyFocusTitle(focusAt.dateTime),
    NoteType.dailySummary => l10n.dailySummaryTitle(focusAt.dateTime),
    NoteType.weeklyFocus => l10n.weeklyFocusTitle(normalizedFocusAt.weekOfYear),
    NoteType.weeklySummary => l10n.weeklySummaryTitle(
      normalizedFocusAt.weekOfYear,
    ),
    NoteType.monthlyFocus => l10n.monthlyFocusTitle(normalizedFocusAt.yMMM),
    NoteType.monthlySummary => l10n.monthlySummaryTitle(normalizedFocusAt.yMMM),
    NoteType.yearlyFocus => l10n.yearlyFocusTitle(
      normalizedFocusAt.format(pattern: 'y'),
    ),
    NoteType.yearlySummary => l10n.yearlySummaryTitle(
      focusAt.format(pattern: 'y'),
    ),
    NoteType.journal => throw UnimplementedError(),
  };

  @override
  List<Object?> get props => [
    status,
    initialNote,
    title,
    summaryContent,
    focusContent,
    type,
    focusAt,
  ];

  NoteTypeNewState copyWith({
    PageStatus? status,
    Note? initialNote,
    String? title,
    String? summaryContent,
    String? focusContent,
    NoteType? type,
    Jiffy? focusAt,
  }) {
    return NoteTypeNewState(
      status: status ?? this.status,
      initialNote: initialNote ?? this.initialNote,
      title: title ?? this.title,
      summaryContent: summaryContent ?? this.summaryContent,
      focusContent: focusContent ?? this.focusContent,
      type: type ?? this.type,
      focusAt: focusAt ?? this.focusAt,
    );
  }
}
