part of 'note_timeline_bloc.dart';

sealed class NoteTimelineEvent extends Equatable {
  const NoteTimelineEvent();

  @override
  List<Object?> get props => [];
}

final class NoteTimelineDateSelected extends NoteTimelineEvent {
  const NoteTimelineDateSelected({required this.date});

  final Jiffy date;

  @override
  List<Object?> get props => [date];
}

final class NoteTimelineCalendarFormatChanged extends NoteTimelineEvent {
  const NoteTimelineCalendarFormatChanged({this.calendarFormat});

  final CalendarFormat? calendarFormat;

  @override
  List<Object?> get props => [calendarFormat];
}
