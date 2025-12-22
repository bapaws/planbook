part of 'note_focus_cubit.dart';

final class NoteFocusState extends Equatable {
  const NoteFocusState({
    this.status = PageStatus.initial,
    this.initialNote,
    this.title = '',
    this.content = '',
  });

  factory NoteFocusState.fromData({Note? note}) {
    return NoteFocusState(
      initialNote: note,
      title: note?.title ?? '',
      content: note?.content ?? '',
    );
  }

  final PageStatus status;
  final Note? initialNote;

  final String title;
  final String content;
  @override
  List<Object?> get props => [status, initialNote, title, content];

  NoteFocusState copyWith({
    PageStatus? status,
    Note? initialNote,
    String? title,
    String? content,
  }) {
    return NoteFocusState(
      status: status ?? this.status,
      initialNote: initialNote ?? this.initialNote,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}
