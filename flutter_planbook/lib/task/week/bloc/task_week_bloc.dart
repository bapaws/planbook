import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'task_week_event.dart';
part 'task_week_state.dart';

class TaskWeekBloc extends Bloc<TaskWeekEvent, TaskWeekState> {
  TaskWeekBloc({
    required NotesRepository notesRepository,
    required AppLocalizations l10n,
  }) : _notesRepository = notesRepository,
       _l10n = l10n,
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
    on<TaskWeekNoteTaskAppended>(_onNoteTaskAppended);
  }

  final NotesRepository _notesRepository;
  final AppLocalizations _l10n;

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

  Future<void> _onNoteTaskAppended(
    TaskWeekNoteTaskAppended event,
    Emitter<TaskWeekState> emit,
  ) async {
    final currentNote = event.noteType.isFocus
        ? state.focusNote
        : state.summaryNote;
    final title = event.noteType.noteTitle(state.date, _l10n);
    final focusAt = event.noteType.normalizedFocusAt(state.date);
    await _notesRepository.appendTaskLineToNote(
      title: title,
      focusAt: focusAt,
      noteType: event.noteType,
      task: event.task,
      currentNote: currentNote,
    );
  }
}
