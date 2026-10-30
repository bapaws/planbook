// 保留公开命名参数及私有依赖字段，兼容项目最低 SDK。
// ignore_for_file: prefer_initializing_formals

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
    on<TaskWeekNoteTaskAppended>(
      _onNoteTaskAppended,
      transformer: sequential(),
    );
  }

  final NotesRepository _notesRepository;
  final AppLocalizations _l10n;
  int _noteGeneration = 0;

  Future<void> _onDateSelected(
    TaskWeekDateSelected event,
    Emitter<TaskWeekState> emit,
  ) async {
    final changedPeriod =
        PeriodNoteTarget(date: state.date, type: NoteType.weeklyFocus) !=
        PeriodNoteTarget(date: event.date, type: NoteType.weeklyFocus);
    final generation = ++_noteGeneration;
    emit(
      state.copyWith(
        date: event.date,
        focusNote: changedPeriod ? () => null : null,
        summaryNote: changedPeriod ? () => null : null,
        isFocusNoteReady: changedPeriod ? false : null,
        isSummaryNoteReady: changedPeriod ? false : null,
      ),
    );
    add(TaskWeekFocusNoteRequested(date: event.date, generation: generation));
    add(TaskWeekSummaryNoteRequested(date: event.date, generation: generation));
  }

  Future<void> _onFocusNoteRequested(
    TaskWeekFocusNoteRequested event,
    Emitter<TaskWeekState> emit,
  ) async {
    final generation = event.generation ?? _noteGeneration;
    final target = PeriodNoteTarget(
      date: event.date,
      type: NoteType.weeklyFocus,
    );
    final account = _notesRepository.userId;
    bool isCurrent() =>
        generation == _noteGeneration &&
        target == PeriodNoteTarget(date: state.date, type: target.type) &&
        account == _notesRepository.userId;
    if (!isCurrent()) return;
    await emit.forEach(
      _notesRepository.getNoteByFocusAt(event.date, type: target.type),
      onData: (note) {
        if (!isCurrent()) return state;
        final valid =
            note == null || (target.accepts(note) && note.userId == account);
        return state.copyWith(
          focusNote: () => valid ? note : null,
          isFocusNoteReady: valid,
          status: valid ? PageStatus.success : PageStatus.failure,
        );
      },
      onError: (_, _) => !isCurrent()
          ? state
          : state.copyWith(
              focusNote: () => null,
              isFocusNoteReady: false,
            ),
    );
  }

  Future<void> _onSummaryNoteRequested(
    TaskWeekSummaryNoteRequested event,
    Emitter<TaskWeekState> emit,
  ) async {
    final generation = event.generation ?? _noteGeneration;
    final target = PeriodNoteTarget(
      date: event.date,
      type: NoteType.weeklySummary,
    );
    final account = _notesRepository.userId;
    bool isCurrent() =>
        generation == _noteGeneration &&
        target == PeriodNoteTarget(date: state.date, type: target.type) &&
        account == _notesRepository.userId;
    if (!isCurrent()) return;
    await emit.forEach(
      _notesRepository.getNoteByFocusAt(event.date, type: target.type),
      onData: (note) {
        if (!isCurrent()) return state;
        final valid =
            note == null || (target.accepts(note) && note.userId == account);
        return state.copyWith(
          summaryNote: () => valid ? note : null,
          isSummaryNoteReady: valid,
          status: valid ? PageStatus.success : PageStatus.failure,
        );
      },
      onError: (_, _) => !isCurrent()
          ? state
          : state.copyWith(
              summaryNote: () => null,
              isSummaryNoteReady: false,
            ),
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
    if (event.noteType != NoteType.weeklyFocus &&
        event.noteType != NoteType.weeklySummary) {
      return;
    }
    final snapshot = state.noteSnapshot(event.noteType);
    if (!snapshot.canWrite ||
        (event.target != null && event.target != snapshot.target) ||
        (snapshot.note != null &&
            snapshot.note!.userId != _notesRepository.userId)) {
      return;
    }
    final title = event.noteType.noteTitle(snapshot.target.focusAt, _l10n);
    await _notesRepository.appendTaskLineToNote(
      title: title,
      focusAt: snapshot.target.focusAt,
      noteType: event.noteType,
      task: event.task,
      currentNote: snapshot.note,
    );
  }
}
