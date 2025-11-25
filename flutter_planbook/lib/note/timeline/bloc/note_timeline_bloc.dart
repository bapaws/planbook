import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:table_calendar/table_calendar.dart';

part 'note_timeline_event.dart';
part 'note_timeline_state.dart';

class NoteTimelineBloc extends Bloc<NoteTimelineEvent, NoteTimelineState> {
  NoteTimelineBloc() : super(NoteTimelineState(date: Jiffy.now())) {
    on<NoteTimelineCalendarFormatChanged>(_onCalendarFormatChanged);
    on<NoteTimelineDateSelected>(_onDateSelected);
  }

  Future<void> _onCalendarFormatChanged(
    NoteTimelineCalendarFormatChanged event,
    Emitter<NoteTimelineState> emit,
  ) async {
    final newCalendarFormat =
        event.calendarFormat ??
        (state.calendarFormat == CalendarFormat.week
            ? CalendarFormat.month
            : CalendarFormat.week);
    emit(
      state.copyWith(
        calendarFormat: newCalendarFormat,
      ),
    );
  }

  Future<void> _onDateSelected(
    NoteTimelineDateSelected event,
    Emitter<NoteTimelineState> emit,
  ) async {
    emit(state.copyWith(date: event.date.startOf(Unit.day)));
  }
}
