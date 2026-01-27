import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'root_note_event.dart';
part 'root_note_state.dart';

class RootNoteBloc extends Bloc<RootNoteEvent, RootNoteState> {
  RootNoteBloc({
    required NotesRepository notesRepository,
  }) : _notesRepository = notesRepository,
       super(
         RootNoteState(
           galleryDate: Jiffy.now().startOf(Unit.day),

           tagDate: Jiffy.now().startOf(Unit.day),
         ),
       ) {
    on<RootNoteRequested>(_onRequested);
    on<RootNoteTagSelected>(_onTagSelected);
    on<RootNoteDateSelected>(_onDateSelected);

    on<RootNoteRefreshRequested>(_onRefreshRequested);
  }

  final NotesRepository _notesRepository;

  Future<void> _onRequested(
    RootNoteRequested event,
    Emitter<RootNoteState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
  }

  Future<void> _onTagSelected(
    RootNoteTagSelected event,
    Emitter<RootNoteState> emit,
  ) async {
    emit(state.copyWith(tag: event.tag));
  }

  Future<void> _onDateSelected(
    RootNoteDateSelected event,
    Emitter<RootNoteState> emit,
  ) async {
    switch (event.tab) {
      case RootNoteTab.gallery:
        emit(state.copyWith(galleryDate: event.date));
      case RootNoteTab.written:
      case RootNoteTab.task:
      case RootNoteTab.timeline:
      case RootNoteTab.tag:
        emit(state.copyWith(tagDate: event.date));
    }
  }

  Future<void> _onRefreshRequested(
    RootNoteRefreshRequested event,
    Emitter<RootNoteState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await _notesRepository.syncNotes(force: true);
    emit(state.copyWith(status: PageStatus.success));
  }
}
