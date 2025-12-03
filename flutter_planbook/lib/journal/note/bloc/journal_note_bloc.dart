import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'journal_note_event.dart';
part 'journal_note_state.dart';

class JournalNoteBloc extends Bloc<JournalNoteEvent, JournalNoteState> {
  JournalNoteBloc({
    required NotesRepository notesRepository,
  }) : _notesRepository = notesRepository,
       super(const JournalNoteState()) {
    on<JournalNoteRequested>(_onJournalNoteRequested);
  }

  final NotesRepository _notesRepository;

  Future<void> _onJournalNoteRequested(
    JournalNoteRequested event,
    Emitter<JournalNoteState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await emit.forEach(
      _notesRepository.getWrittenNoteEntities(
        event.date,
        tagIds: event.tagIds,
      ),
      onData: (notes) {
        final noteCount = notes.length;
        final wordCount = notes.fold(
          0,
          (sum, note) => sum + note.title.length + (note.content?.length ?? 0),
        );
        return state.copyWith(
          status: PageStatus.success,
          notes: notes,
          noteCount: noteCount,
          wordCount: wordCount,
          coverImage:
              notes
                  .firstWhereOrNull((note) => note.coverImage != null)
                  ?.coverImage ??
              notes
                  .firstWhereOrNull((note) => note.images.isNotEmpty)
                  ?.images
                  .firstOrNull,
        );
      },
    );
  }
}
