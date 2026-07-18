import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'journal_monthly_event.dart';
part 'journal_monthly_state.dart';

class _JournalMonthlyData {
  const _JournalMonthlyData({
    required this.focusNote,
    required this.summaryNote,
    required this.notes,
    required this.images,
    required this.completedTasksCount,
    required this.plannedTasksCount,
    required this.completedByPriority,
    required this.dailyFocusNotes,
    required this.weeklyFocusNotes,
  });

  final Note? focusNote;
  final Note? summaryNote;
  final List<NoteEntity> notes;
  final List<NoteImageEntity> images;
  final int completedTasksCount;
  final int plannedTasksCount;
  final List<int> completedByPriority;
  final List<Note?> dailyFocusNotes;
  final List<Note?> weeklyFocusNotes;
}

class JournalMonthlyBloc
    extends Bloc<JournalMonthlyEvent, JournalMonthlyState> {
  JournalMonthlyBloc({
    required Jiffy month,
    required NotesRepository notesRepository,
    required TasksRepository tasksRepository,
  }) : _notesRepository = notesRepository,
       _tasksRepository = tasksRepository,
       super(JournalMonthlyState(month: month)) {
    on<JournalMonthlyRequested>(_onRequested, transformer: restartable());
    add(JournalMonthlyRequested(month: month));
  }

  final NotesRepository _notesRepository;
  final TasksRepository _tasksRepository;

  Future<void> _onRequested(
    JournalMonthlyRequested event,
    Emitter<JournalMonthlyState> emit,
  ) async {
    final month = event.month.startOf(Unit.month);
    emit(state.copyWith(status: PageStatus.loading, month: month));

    final priorityStreams = [
      for (final priority in TaskPriority.values)
        _tasksRepository.getCompletedTaskCountForMonth(
          month,
          priority: priority,
        ),
    ];

    final daysInMonth = month.daysInMonth;
    final dailyFocusStreams = [
      for (var i = 0; i < daysInMonth; i++)
        _notesRepository.getNoteByFocusAt(month.add(days: i)),
    ];

    final firstWeekday = month.dateTime.weekday;
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells + 6) ~/ 7;
    final firstMonday = month.subtract(
      days: month.dateTime.weekday - 1,
    );
    final weeklyFocusStreams = [
      for (var i = 0; i < rowCount; i++)
        _notesRepository.getNoteByFocusAt(
          firstMonday.add(weeks: i),
          type: NoteType.weeklyFocus,
        ),
    ];

    await emit.forEach(
      Rx.combineLatest3<
        _JournalMonthlyData,
        List<Note?>,
        List<Note?>,
        _JournalMonthlyData
      >(
        CombineLatestStream.combine7(
          _notesRepository.getNoteByFocusAt(
            month,
            type: NoteType.monthlyFocus,
          ),
          _notesRepository.getNoteByFocusAt(
            month,
            type: NoteType.monthlySummary,
          ),
          _notesRepository.getNoteEntitiesForMonth(month),
          _notesRepository.getNoteImageEntitiesForMonth(month),
          _tasksRepository.getCompletedTaskCountForMonth(month),
          _tasksRepository.getPlannedTaskCountForMonth(month),
          CombineLatestStream.list<int>(priorityStreams),
          (
            focusNote,
            summaryNote,
            notes,
            images,
            completedTasksCount,
            plannedTasksCount,
            completedByPriority,
          ) => _JournalMonthlyData(
            focusNote: focusNote,
            summaryNote: summaryNote,
            notes: notes,
            images: images,
            completedTasksCount: completedTasksCount,
            plannedTasksCount: plannedTasksCount,
            completedByPriority: completedByPriority,
            dailyFocusNotes: const [],
            weeklyFocusNotes: const [],
          ),
        ),
        CombineLatestStream.list<Note?>(dailyFocusStreams),
        CombineLatestStream.list<Note?>(weeklyFocusStreams),
        (baseData, dailyFocus, weeklyFocus) => _JournalMonthlyData(
          focusNote: baseData.focusNote,
          summaryNote: baseData.summaryNote,
          notes: baseData.notes,
          images: baseData.images,
          completedTasksCount: baseData.completedTasksCount,
          plannedTasksCount: baseData.plannedTasksCount,
          completedByPriority: baseData.completedByPriority,
          dailyFocusNotes: dailyFocus,
          weeklyFocusNotes: weeklyFocus,
        ),
      ),
      onData: (data) {
        final priorityMap = <TaskPriority, int>{};
        for (var i = 0; i < TaskPriority.values.length; i++) {
          priorityMap[TaskPriority.values[i]] = data.completedByPriority[i];
        }

        var wordCount = 0;
        for (final note in data.notes) {
          final content = note.content ?? '';
          wordCount += content.length;
        }

        return state.copyWith(
          status: PageStatus.success,
          focusNote: () => data.focusNote,
          summaryNote: () => data.summaryNote,
          notes: data.notes,
          images: data.images,
          completedTasksCount: data.completedTasksCount,
          plannedTasksCount: data.plannedTasksCount,
          completedByPriority: priorityMap,
          noteCount: data.notes.length,
          wordCount: wordCount,
          dailyFocusNotes: data.dailyFocusNotes,
          weeklyFocusNotes: data.weeklyFocusNotes,
        );
      },
    );
  }
}
