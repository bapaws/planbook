import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'tag_detail_event.dart';
part 'tag_detail_state.dart';

class TagDetailBloc extends Bloc<TagDetailEvent, TagDetailState> {
  TagDetailBloc({
    required NotesRepository notesRepository,
    required TagsRepository tagsRepository,
    required TagEntity tag,
  }) : _notesRepository = notesRepository,
       _tagsRepository = tagsRepository,
       super(TagDetailState(tag: tag)) {
    on<TagDetailRequested>(_onRequested, transformer: restartable());
    on<TagDetailNoteDeleted>(_onNoteDeleted, transformer: sequential());
    on<TagDetailDeleted>(_onDeleted, transformer: droppable());
  }

  final NotesRepository _notesRepository;
  final TagsRepository _tagsRepository;

  Future<void> _onRequested(
    TagDetailRequested event,
    Emitter<TagDetailState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await emit.forEach(
      _notesRepository.getNoteEntitiesByTagId(state.tag.id),
      onData: (notes) => state.copyWith(
        status: PageStatus.success,
        notes: notes,
      ),
    );
  }

  Future<void> _onNoteDeleted(
    TagDetailNoteDeleted event,
    Emitter<TagDetailState> emit,
  ) async {
    await _notesRepository.deleteNoteById(event.note.id);
  }

  Future<void> _onDeleted(
    TagDetailDeleted event,
    Emitter<TagDetailState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await _tagsRepository.deleteById(state.tag.id);
    emit(state.copyWith(status: PageStatus.dispose));
  }
}
