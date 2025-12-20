part of 'note_focus_cubit.dart';

final class NoteFocusState extends Equatable {
  const NoteFocusState({
    this.status = PageStatus.initial,
    this.initialNote,
    this.title = '',
  });

  factory NoteFocusState.fromData({Note? note}) {
    return NoteFocusState(
      initialNote: note,
      title: note?.title ?? '',
    );
  }

  final PageStatus status;
  final Note? initialNote;

  final String title;

  @override
  List<Object?> get props => [status, initialNote, title];

  NoteFocusState copyWith({
    PageStatus? status,
    Note? initialNote,
    String? title,
  }) {
    return NoteFocusState(
      status: status ?? this.status,
      initialNote: initialNote ?? this.initialNote,
      title: title ?? this.title,
    );
  }
}
