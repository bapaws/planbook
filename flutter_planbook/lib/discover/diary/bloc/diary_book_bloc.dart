import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'diary_book_event.dart';
part 'diary_book_state.dart';

class DiaryBookBloc extends Bloc<DiaryBookEvent, DiaryBookState> {
  DiaryBookBloc({required this.notesRepository})
    : super(const DiaryBookState()) {
    on<DiaryBookRequested>(_onRequested, transformer: restartable());
  }

  final NotesRepository notesRepository;

  Future<void> _onRequested(
    DiaryBookRequested event,
    Emitter<DiaryBookState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    await emit.forEach(
      notesRepository.watchDiaryNotes(),
      onData: (notes) =>
          state.copyWith(status: PageStatus.success, notes: notes),
      onError: (_, _) => state.copyWith(status: PageStatus.failure),
    );
  }
}
