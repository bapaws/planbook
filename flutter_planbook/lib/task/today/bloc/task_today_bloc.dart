// 保留公开命名参数及私有依赖字段，兼容项目最低 SDK。
// ignore_for_file: prefer_initializing_formals

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:table_calendar/table_calendar.dart';

part 'task_today_event.dart';
part 'task_today_state.dart';

class TaskTodayBloc extends Bloc<TaskTodayEvent, TaskTodayState> {
  TaskTodayBloc({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    required AppLocalizations l10n,
  }) : _tasksRepository = tasksRepository,

       _notesRepository = notesRepository,
       _l10n = l10n,
       super(TaskTodayState(date: Jiffy.now().startOf(Unit.day))) {
    on<TaskTodayDateSelected>(_onDateSelected, transformer: restartable());
    on<TaskTodayCalendarFormatChanged>(_onCalendarFormatChanged);
    on<TaskTodayFocusNoteRequested>(
      _onFocusNoteRequested,
      transformer: restartable(),
    );
    on<TaskTodaySummaryNoteRequested>(
      _onSummaryNoteRequested,
      transformer: restartable(),
    );
    on<TaskTodayNoteTaskAppended>(
      _onNoteTaskAppended,
      transformer: sequential(),
    );
  }

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;

  final AppLocalizations _l10n;
  int _noteGeneration = 0;

  Future<void> _onDateSelected(
    TaskTodayDateSelected event,
    Emitter<TaskTodayState> emit,
  ) async {
    final changedPeriod =
        PeriodNoteTarget(date: state.date, type: NoteType.dailyFocus) !=
        PeriodNoteTarget(date: event.date, type: NoteType.dailyFocus);
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

    add(TaskTodayFocusNoteRequested(date: event.date, generation: generation));
    add(
      TaskTodaySummaryNoteRequested(date: event.date, generation: generation),
    );

    await emit.forEach(
      _tasksRepository.getTaskCount(
        date: event.date,
        mode: TaskListMode.today,
        isCompleted: event.isCompleted,
      ),
      onData: (count) {
        return state.copyWith(
          taskCounts: {...state.taskCounts, event.date.dateKey: count},
        );
      },
    );
  }

  Future<void> _onCalendarFormatChanged(
    TaskTodayCalendarFormatChanged event,
    Emitter<TaskTodayState> emit,
  ) async {
    emit(state.copyWith(calendarFormat: event.calendarFormat));
  }

  Future<void> _onFocusNoteRequested(
    TaskTodayFocusNoteRequested event,
    Emitter<TaskTodayState> emit,
  ) async {
    final generation = event.generation ?? _noteGeneration;
    final target = PeriodNoteTarget(
      date: event.date,
      type: NoteType.dailyFocus,
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
    TaskTodaySummaryNoteRequested event,
    Emitter<TaskTodayState> emit,
  ) async {
    final generation = event.generation ?? _noteGeneration;
    final target = PeriodNoteTarget(
      date: event.date,
      type: NoteType.dailySummary,
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

  Future<void> _onNoteTaskAppended(
    TaskTodayNoteTaskAppended event,
    Emitter<TaskTodayState> emit,
  ) async {
    if (event.noteType != NoteType.dailyFocus &&
        event.noteType != NoteType.dailySummary) {
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
