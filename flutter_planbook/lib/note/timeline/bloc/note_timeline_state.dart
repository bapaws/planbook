part of 'note_timeline_bloc.dart';

final class NoteTimelineState extends Equatable {
  const NoteTimelineState({
    required this.date,
    this.status = PageStatus.initial,
    this.notes = const [],
    this.calendarFormat = CalendarFormat.week,
  });

  final PageStatus status;
  final List<NoteEntity> notes;
  final Jiffy date;

  final CalendarFormat calendarFormat;

  @override
  List<Object?> get props => [status, notes, calendarFormat, date];

  NoteTimelineState copyWith({
    PageStatus? status,
    List<NoteEntity>? notes,
    Jiffy? date,
    CalendarFormat? calendarFormat,
  }) {
    return NoteTimelineState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      date: date ?? this.date,
    );
  }
}
