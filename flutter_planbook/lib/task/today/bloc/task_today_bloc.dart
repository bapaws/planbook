import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:table_calendar/table_calendar.dart';

part 'task_today_event.dart';
part 'task_today_state.dart';

class TaskTodayBloc extends Bloc<TaskTodayEvent, TaskTodayState> {
  TaskTodayBloc({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
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
  }

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;

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
}
