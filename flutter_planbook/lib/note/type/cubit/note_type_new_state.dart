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
