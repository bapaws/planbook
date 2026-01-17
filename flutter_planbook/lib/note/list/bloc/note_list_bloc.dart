import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'note_list_event.dart';
part 'note_list_state.dart';

class NoteListBloc extends Bloc<NoteListEvent, NoteListState> {
  NoteListBloc({
    required NotesRepository notesRepository,
  }) : _notesRepository = notesRepository,
       super(const NoteListState()) {
    on<NoteListRequested>(_onRequested, transformer: restartable());
    on<NoteListDeleted>(_onDeleted);
  }

  final NotesRepository _notesRepository;

  Future<void> _onRequested(
    NoteListRequested event,
    Emitter<NoteListState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await emit.forEach(
      _notesRepository.getNoteEntitiesByDate(
        event.date,
        tagIds: event.tagIds,
        modes: event.modes,
      ),
      onData: (notes) => state.copyWith(
        status: PageStatus.success,
        notes: notes,
      ),
    );
  }

  Future<void> _onDeleted(
    NoteListDeleted event,
    Emitter<NoteListState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await _notesRepository.deleteNoteById(event.note.id);
    emit(state.copyWith(status: PageStatus.success));
  }
}
