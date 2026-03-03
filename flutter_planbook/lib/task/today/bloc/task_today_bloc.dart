import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:drift/drift.dart';
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
    on<TaskTodayNoteTaskAppended>(_onNoteTaskAppended);
  }

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;

  final AppLocalizations _l10n;

  Future<void> _onDateSelected(
    TaskTodayDateSelected event,
    Emitter<TaskTodayState> emit,
  ) async {
    emit(state.copyWith(date: event.date));

    add(TaskTodayFocusNoteRequested(date: event.date));
    add(TaskTodaySummaryNoteRequested(date: event.date));

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
    await emit.forEach(
      _notesRepository.getNoteByFocusAt(event.date),
      onData: (note) => state.copyWith(focusNote: () => note),
    );
  }

  Future<void> _onSummaryNoteRequested(
    TaskTodaySummaryNoteRequested event,
    Emitter<TaskTodayState> emit,
  ) async {
    await emit.forEach(
      _notesRepository.getNoteByFocusAt(
        event.date,
        type: NoteType.dailySummary,
      ),
      onData: (note) => state.copyWith(summaryNote: () => note),
    );
  }

  Future<void> _onNoteTaskAppended(
    TaskTodayNoteTaskAppended event,
    Emitter<TaskTodayState> emit,
  ) async {
    final currentNote = event.noteType.isFocus
        ? state.focusNote
        : state.summaryNote;
    final newLine = '${event.task.isCompleted ? '✅' : '❌'} ${event.task.title}';
    final base = (currentNote?.content ?? '').trim();

    final String newContent;
    if (base.isEmpty) {
      newContent = newLine;
    } else {
      final lines = base.split('\n').toList();
      final taskTitle = event.task.title;

      bool isSameTaskLine(String l) {
        if (l.length < 2) return false;
        final first = l[0];
        if (first != '✅' && first != '❌') return false;
        return l.substring(1).trimLeft() == taskTitle;
      }

      int? firstIdx;
      final result = <String>[];
      for (var i = 0; i < lines.length; i++) {
        if (isSameTaskLine(lines[i])) {
          firstIdx ??= result.length;
          if (firstIdx == result.length) {
            result.add(newLine);
          }
        } else {
          result.add(lines[i]);
        }
      }
      if (firstIdx != null) {
        newContent = result.join('\n');
      } else {
        newContent = '$base\n$newLine';
      }
    }

    if (currentNote == null) {
      final title = event.noteType.noteTitle(state.date, _l10n);
      final normalizedFocusAt = event.noteType.normalizedFocusAt(state.date);
      await _notesRepository.create(
        title: title,
        content: newContent,
        focusAt: normalizedFocusAt,
        type: event.noteType,
      );
    } else {
      await _notesRepository.update(
        note: currentNote.copyWith(content: Value(newContent)),
      );
    }
  }
}
