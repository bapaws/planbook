import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/plus/datetime.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'journal_day_event.dart';
part 'journal_day_state.dart';

class JournalDayBloc extends Bloc<JournalDayEvent, JournalDayState> {
  JournalDayBloc({
    required Jiffy date,
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       super(JournalDayState(date: date)) {
    on<JournalDayRequested>(_onJournalDayRequested);
    on<JournalTodayTasksRequested>(_onTodayTasksRequested);
    on<JournalTodayNotesRequested>(_onTodayNotesRequested);
    on<JournalDayTasksRequested>(_onTasksRequested);
    on<JournalDayNotesRequested>(_onNotesRequested);
  }

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;

  Future<void> _onJournalDayRequested(
    JournalDayRequested event,
    Emitter<JournalDayState> emit,
  ) async {
    emit(state.copyWith(date: event.date));

    final now = Jiffy.now();
    if (event.date.isSame(now, unit: Unit.day)) {
      add(JournalTodayTasksRequested(date: event.date));
      add(JournalTodayNotesRequested(date: event.date));
    } else {
      add(JournalDayTasksRequested(date: event.date));
      add(JournalDayNotesRequested(date: event.date));
    }
  }

  Future<void> _onTodayTasksRequested(
    JournalTodayTasksRequested event,
    Emitter<JournalDayState> emit,
  ) async {
    await emit.forEach(
      _tasksRepository.getCompletedTaskEntities(date: event.date),
      onData: (tasks) => state.copyWith(
        tasks: {...state.tasks, event.date.dateKey: tasks},
      ),
    );
  }

  Future<void> _onTodayNotesRequested(
    JournalTodayNotesRequested event,
    Emitter<JournalDayState> emit,
  ) async {
    await emit.forEach(
      _notesRepository.getWrittenNoteEntities(event.date),
      onData: (notes) => state.copyWith(
        notes: {...state.notes, event.date.dateKey: notes},
      ),
    );
  }

  Future<void> _onTasksRequested(
    JournalDayTasksRequested event,
    Emitter<JournalDayState> emit,
  ) async {
    await emit.forEach(
      _tasksRepository.getCompletedTaskEntities(date: event.date),
      onData: (tasks) => state.copyWith(
        tasks: {...state.tasks, event.date.dateKey: tasks},
      ),
    );
  }

  Future<void> _onNotesRequested(
    JournalDayNotesRequested event,
    Emitter<JournalDayState> emit,
  ) async {
    await emit.forEach(
      _notesRepository.getWrittenNoteEntities(event.date),
      onData: (notes) => state.copyWith(
        notes: {...state.notes, event.date.dateKey: notes},
      ),
    );
  }
}
