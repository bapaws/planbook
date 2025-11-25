import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'note_gallery_event.dart';
part 'note_gallery_state.dart';

class NoteGalleryBloc extends Bloc<NoteGalleryEvent, NoteGalleryState> {
  NoteGalleryBloc({
    required NotesRepository notesRepository,
  }) : _notesRepository = notesRepository,
       super(NoteGalleryState(date: Jiffy.now())) {
    on<NoteGalleryRequested>(_onRequested, transformer: restartable());
  }

  final NotesRepository _notesRepository;

  Future<void> _onRequested(
    NoteGalleryRequested event,
    Emitter<NoteGalleryState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading, date: event.date));
    await emit.forEach(
      _notesRepository.getNoteImageEntities(),
      onData: (noteImages) {
        final noteImagesByDate = <Jiffy, List<NoteImageEntity>>{
          ...state.noteImages,
        };
        for (final noteImage in noteImages) {
          noteImagesByDate
              .putIfAbsent(noteImage.createdAt.startOf(Unit.day), () => [])
              .add(noteImage);
        }
        return state.copyWith(
          status: PageStatus.success,
          noteImages: noteImagesByDate,
        );
      },
    );
  }
}
