import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'note_type_new_state.dart';

class NoteTypeNewCubit extends Cubit<NoteTypeNewState> {
  NoteTypeNewCubit({
    required NotesRepository notesRepository,
    required Jiffy focusAt,
    required AppLocalizations l10n,
    NoteType? type,
    Note? initialNote,
  }) : _notesRepository = notesRepository,
       _l10n = l10n,
       super(
         NoteTypeNewState.fromData(
           note: initialNote,
           type: type,
           focusAt: focusAt,
         ),
       );

  final NotesRepository _notesRepository;
  final AppLocalizations _l10n;

  Future<void> onRequested({Jiffy? focusAt, NoteType? type}) async {
    emit(state.copyWith(status: PageStatus.loading));
    final note = await _notesRepository
        .getNoteByFocusAt(focusAt ?? state.focusAt, type: type ?? state.type)
        .first;
    final newState = NoteTypeNewState.fromData(
      note: note,
      type: type ?? state.type,
      focusAt: focusAt ?? state.focusAt,
    );
    emit(newState);
  }

  Future<void> onTypeChanged(NoteType type) async {
    await onRequested(type: type);
  }

  void onFocusAtChanged(Jiffy focusAt) {
    emit(state.copyWith(focusAt: focusAt));
  }

  void onContentChanged(String content) {
    if (state.type.isSummary) {
      emit(state.copyWith(summaryContent: content.trim()));
    } else {
      emit(state.copyWith(focusContent: content.trim()));
    }
  }

  Future<void> onSave() async {
    emit(state.copyWith(status: PageStatus.loading));

    final normalizedFocusAt = state.type.normalizedFocusAt(state.focusAt);
    final title = state.type.noteTitle(state.focusAt, _l10n);
    final content = state.type.isSummary
        ? state.summaryContent
        : state.focusContent;

    if (state.initialNote == null) {
      await _notesRepository.create(
        title: title,
        content: content.trim(),
        focusAt: normalizedFocusAt,
        type: state.type,
      );
    } else {
      final note = state.initialNote!.copyWith(
        title: title,
        content: Value(content.trim()),
        updatedAt: Value(Jiffy.now()),
      );
      await _notesRepository.update(note: note);
    }
    emit(state.copyWith(status: PageStatus.success));
  }
}
