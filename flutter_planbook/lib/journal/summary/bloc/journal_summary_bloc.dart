import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'journal_summary_event.dart';
part 'journal_summary_state.dart';

class JournalSummaryBloc
    extends Bloc<JournalSummaryEvent, JournalSummaryState> {
  JournalSummaryBloc({
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
  }) : _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       super(const JournalSummaryState()) {
    on<JournalSummaryRequested>(_onRequested);
  }

  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;

  Future<void> _onRequested(
    JournalSummaryRequested event,
    Emitter<JournalSummaryState> emit,
  ) async {
    emit(
      state.copyWith(
        totalTasks: 10,
        completedTasks: 5,
        totalNotes: 10,
        totalWords: 100,
      ),
    );
  }
}
