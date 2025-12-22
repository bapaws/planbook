import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'note_focus_state.dart';

class NoteFocusCubit extends Cubit<NoteFocusState> {
  NoteFocusCubit({
    required NotesRepository notesRepository,
    required this.type,
    required this.focusAt,
    required AppLocalizations l10n,
    Note? initialNote,
  }) : _notesRepository = notesRepository,
       _l10n = l10n,
       super(NoteFocusState.fromData(note: initialNote));

  final NoteType type;
  final Jiffy focusAt;
  final NotesRepository _notesRepository;
  final AppLocalizations _l10n;

  void onContentChanged(String content) {
    emit(state.copyWith(content: content.trim()));
  }

  Future<void> onSave() async {
    emit(state.copyWith(status: PageStatus.loading));
    // 使用该周的周一作为 focusAt
    // dayOfWeek: 1=周一, 7=周日 (ISO 8601)
    final monday = focusAt
        .subtract(days: focusAt.dateTime.weekday - 1)
        .toUtc()
        .startOf(Unit.day);
    final title = _l10n.weeklyFocusTitle(monday.weekOfYear);
    if (state.initialNote == null) {
      await _notesRepository.create(
        title: title,
        content: state.content,
        focusAt: monday,
        type: type,
      );
    } else {
      final note = state.initialNote!.copyWith(
        title: title,
        content: Value(state.content),
        updatedAt: Value(Jiffy.now()),
      );
      await _notesRepository.update(note: note);
    }
    emit(state.copyWith(status: PageStatus.success));
  }
}
