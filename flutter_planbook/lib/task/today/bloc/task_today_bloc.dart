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
