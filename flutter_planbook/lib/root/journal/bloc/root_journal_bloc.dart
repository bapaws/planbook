import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'root_journal_event.dart';
part 'root_journal_state.dart';

class RootJournalBloc extends Bloc<RootJournalEvent, RootJournalState> {
  RootJournalBloc({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    required Jiffy now,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       super(
         RootJournalState(
           startYear: now.year,
           endYear: now.year,
           year: now.year,
           days: Jiffy.parseFromList([
             now.year + 1,
           ]).diff(Jiffy.parseFromList([now.year]), unit: Unit.day).toInt(),
         ),
       ) {
    on<RootJournalRequested>(_onRequested);
    on<RootJournalYearChanged>(_onYearChanged);
  }

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;

  Future<void> _onRequested(
    RootJournalRequested event,
    Emitter<RootJournalState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    final tasksStartDate = await _tasksRepository.getStartDate();
    final notesStartDate = await _notesRepository.getStartDate();
    final now = Jiffy.now();
    var startYear = now.year;
    if (tasksStartDate != null && notesStartDate != null) {
      if (tasksStartDate.isBefore(notesStartDate)) {
        startYear = tasksStartDate.year;
      } else {
        startYear = notesStartDate.year;
      }
    } else if (tasksStartDate != null) {
      startYear = tasksStartDate.year;
    } else if (notesStartDate != null) {
      startYear = notesStartDate.year;
    }
    final year = now.year;
    final days = Jiffy.parseFromList([
      year + 1,
    ]).diff(Jiffy.parseFromList([year]), unit: Unit.day).toInt();
    emit(
      state.copyWith(
        status: PageStatus.success,
        startYear: startYear,
        year: year,
        endYear: year,
        days: days,
      ),
    );
  }

  Future<void> _onYearChanged(
    RootJournalYearChanged event,
    Emitter<RootJournalState> emit,
  ) async {
    final startOfYear = Jiffy.parseFromList([event.year]);
    final endOfYear = startOfYear.endOf(Unit.year);
    final days = endOfYear.diff(startOfYear, unit: Unit.day).toInt();
    emit(
      state.copyWith(
        days: days,
        year: event.year,
      ),
    );
  }
}
