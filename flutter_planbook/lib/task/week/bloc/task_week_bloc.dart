import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'task_week_event.dart';
part 'task_week_state.dart';

class TaskWeekBloc extends Bloc<TaskWeekEvent, TaskWeekState> {
  TaskWeekBloc({
    required NotesRepository notesRepository,
  }) : _notesRepository = notesRepository,
       super(TaskWeekState(date: Jiffy.now())) {
    on<TaskWeekDateSelected>(_onDateSelected);
    on<TaskWeekFocusNoteRequested>(
      _onFocusNoteRequested,
      transformer: restartable(),
    );
    on<TaskWeekSummaryNoteRequested>(
      _onSummaryNoteRequested,
      transformer: restartable(),
    );
    on<TaskWeekCalendarToggled>(_onCalendarToggled);
  }

  final NotesRepository _notesRepository;

  Future<void> _onDateSelected(
    TaskWeekDateSelected event,
    Emitter<TaskWeekState> emit,
  ) async {
    emit(state.copyWith(date: event.date));
    add(TaskWeekFocusNoteRequested(date: event.date));
    add(TaskWeekSummaryNoteRequested(date: event.date));
  }

  Future<void> _onFocusNoteRequested(
    TaskWeekFocusNoteRequested event,
    Emitter<TaskWeekState> emit,
  ) async {
    await emit.forEach(
      _notesRepository.getNoteByFocusAt(
        event.date,
        type: NoteType.weeklyFocus,
      ),
      onData: (note) => state.copyWith(
        focusNote: () => note,
        status: PageStatus.success,
      ),
    );
  }

  Future<void> _onSummaryNoteRequested(
    TaskWeekSummaryNoteRequested event,
    Emitter<TaskWeekState> emit,
  ) async {
    await emit.forEach(
      _notesRepository.getNoteByFocusAt(
        event.date,
        type: NoteType.weeklySummary,
      ),
      onData: (note) => state.copyWith(summaryNote: () => note),
    );
  }

  Future<void> _onCalendarToggled(
    TaskWeekCalendarToggled event,
    Emitter<TaskWeekState> emit,
  ) async {
    emit(state.copyWith(isCalendarExpanded: !state.isCalendarExpanded));
  }
}
