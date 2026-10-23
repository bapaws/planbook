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

part 'task_month_event.dart';
part 'task_month_state.dart';

class TaskMonthBloc extends Bloc<TaskMonthEvent, TaskMonthState> {
  TaskMonthBloc({
    required NotesRepository notesRepository,
    required AppLocalizations l10n,
  }) : _notesRepository = notesRepository,
       _l10n = l10n,
       super(TaskMonthState(date: Jiffy.now())) {
    on<TaskMonthDateSelected>(_onDateSelected);
    on<TaskMonthFocusNoteRequested>(
      _onFocusNoteRequested,
      transformer: restartable(),
    );
    on<TaskMonthSummaryNoteRequested>(
      _onSummaryNoteRequested,
      transformer: restartable(),
    );
    on<TaskMonthCalendarToggled>(_onCalendarToggled);
    on<TaskMonthNoteTaskAppended>(
      _onNoteTaskAppended,
      transformer: sequential(),
    );
  }

  final NotesRepository _notesRepository;
  final AppLocalizations _l10n;
  int _noteGeneration = 0;

  Future<void> _onDateSelected(
    TaskMonthDateSelected event,
    Emitter<TaskMonthState> emit,
  ) async {
    final startOfMonth = event.date.startOf(Unit.month);
    final daysInMonth = event.date.daysInMonth;

    final firstDay = startOfMonth;
    final startOfWeek = firstDay.startOf(Unit.week);

    // 计算第一天是周几（0-6）
    final firstDayOffset = firstDay.dateTime
        .difference(startOfWeek.dateTime)
        .inDays;

    final weeks = <List<Jiffy?>>[];
    var currentWeek = <Jiffy?>[];

    // 填充第一周前面的空白
    for (var i = 0; i < firstDayOffset; i++) {
      currentWeek.add(null);
    }

    // 填充月份的每一天
    for (var i = 0; i < daysInMonth; i++) {
      final day = startOfMonth.add(days: i);
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = <Jiffy?>[];
      }
    }

    // 填充最后一周后面的空白
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    final changedPeriod =
        PeriodNoteTarget(date: state.date, type: NoteType.monthlyFocus) !=
        PeriodNoteTarget(date: event.date, type: NoteType.monthlyFocus);
    final generation = ++_noteGeneration;
    emit(
      state.copyWith(
        date: event.date,
        weeks: weeks,
        focusNote: changedPeriod ? () => null : null,
        summaryNote: changedPeriod ? () => null : null,
        isFocusNoteReady: changedPeriod ? false : null,
        isSummaryNoteReady: changedPeriod ? false : null,
      ),
    );

    add(TaskMonthFocusNoteRequested(date: event.date, generation: generation));
    add(
      TaskMonthSummaryNoteRequested(date: event.date, generation: generation),
    );
  }

  Future<void> _onFocusNoteRequested(
    TaskMonthFocusNoteRequested event,
    Emitter<TaskMonthState> emit,
  ) async {
    final generation = event.generation ?? _noteGeneration;
    final target = PeriodNoteTarget(
      date: event.date,
      type: NoteType.monthlyFocus,
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
    TaskMonthSummaryNoteRequested event,
    Emitter<TaskMonthState> emit,
  ) async {
    final generation = event.generation ?? _noteGeneration;
    final target = PeriodNoteTarget(
      date: event.date,
      type: NoteType.monthlySummary,
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
    TaskMonthCalendarToggled event,
    Emitter<TaskMonthState> emit,
  ) async {
    emit(state.copyWith(isCalendarExpanded: !state.isCalendarExpanded));
  }

  Future<void> _onNoteTaskAppended(
    TaskMonthNoteTaskAppended event,
    Emitter<TaskMonthState> emit,
  ) async {
    if (event.noteType != NoteType.monthlyFocus &&
        event.noteType != NoteType.monthlySummary) {
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
