import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_api/entity/note_entity.dart';
import 'package:planbook_api/entity/tag_entity.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/note/notes_repository.dart';

part 'note_tag_event.dart';
part 'note_tag_state.dart';

class NoteTagBloc extends Bloc<NoteTagEvent, NoteTagState> {
  NoteTagBloc({
    required NotesRepository notesRepository,
    required TagEntity tag,
  }) : _notesRepository = notesRepository,
       super(NoteTagState(tag: tag)) {
    on<NoteTagRequested>(_onRequested);
    on<NoteTagDeleted>(_onDeleted);
  }

  final NotesRepository _notesRepository;

  Future<void> _onRequested(
    NoteTagRequested event,
    Emitter<NoteTagState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await emit.forEach(
      _notesRepository.getNoteEntitiesByTagId(event.tagId),
      onData: (notes) =>
          state.copyWith(status: PageStatus.success, notes: notes),
    );
  }

  Future<void> _onDeleted(
    NoteTagDeleted event,
    Emitter<NoteTagState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await _notesRepository.deleteNoteById(event.note.id);
    emit(state.copyWith(status: PageStatus.success));
  }
}
