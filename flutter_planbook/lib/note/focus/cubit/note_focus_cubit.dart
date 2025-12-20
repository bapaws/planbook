import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'note_focus_state.dart';

class NoteFocusCubit extends Cubit<NoteFocusState> {
  NoteFocusCubit({
    required NotesRepository notesRepository,
    required this.type,
    required this.focusAt,
    Note? initialNote,
  }) : _notesRepository = notesRepository,
       super(NoteFocusState.fromData(note: initialNote));

  final NoteType type;
  final Jiffy focusAt;
  final NotesRepository _notesRepository;

  void onTitleChanged(String title) {
    emit(state.copyWith(title: title.trim()));
  }

  Future<void> onSave() async {
    emit(state.copyWith(status: PageStatus.loading));
    if (state.initialNote == null) {
      await _notesRepository.create(
        title: state.title,
        focusAt: focusAt,
        type: type,
      );
    } else {
      final note = state.initialNote!.copyWith(title: state.title);
      await _notesRepository.update(note: note);
    }
    emit(state.copyWith(status: PageStatus.success));
  }
}
