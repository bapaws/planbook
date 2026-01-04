import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
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

    final Jiffy normalizedFocusAt;
    final String title;
    final content = state.type.isSummary
        ? state.summaryContent
        : state.focusContent;

    switch (state.type) {
      case NoteType.dailyFocus:
        // 日目标：使用当天开始作为 focusAt
        normalizedFocusAt = state.focusAt.startOf(Unit.day);
        title = _l10n.dailyFocusTitle(state.focusAt.dateTime);
      case NoteType.dailySummary:
        normalizedFocusAt = state.focusAt.startOf(Unit.day);
        title = _l10n.dailySummaryTitle(state.focusAt.dateTime);
      case NoteType.weeklyFocus:
        // 周目标：使用该周的周一作为 focusAt
        // weekday: 1=周一, 7=周日 (ISO 8601)
        normalizedFocusAt = state.focusAt
            .subtract(days: state.focusAt.dateTime.weekday - 1)
            .startOf(Unit.day);
        title = _l10n.weeklyFocusTitle(normalizedFocusAt.weekOfYear);
      case NoteType.weeklySummary:
        normalizedFocusAt = state.focusAt
            .subtract(days: state.focusAt.dateTime.weekday - 1)
            .startOf(Unit.day);
        title = _l10n.weeklySummaryTitle(normalizedFocusAt.weekOfYear);
      case NoteType.monthlyFocus:
        // 月目标：使用该月的第一天作为 focusAt
        normalizedFocusAt = state.focusAt.startOf(Unit.month);
        title = _l10n.monthlyFocusTitle(normalizedFocusAt.yMMM);
      case NoteType.monthlySummary:
        normalizedFocusAt = state.focusAt.startOf(Unit.month);
        title = _l10n.monthlySummaryTitle(normalizedFocusAt.yMMM);
      case NoteType.yearlyFocus:
        normalizedFocusAt = state.focusAt.startOf(Unit.year);
        title = _l10n.yearlyFocusTitle(normalizedFocusAt.format(pattern: 'y'));
      case NoteType.yearlySummary:
        normalizedFocusAt = state.focusAt.startOf(Unit.year);
        title = _l10n.yearlySummaryTitle(
          normalizedFocusAt.format(pattern: 'y'),
        );
      case NoteType.journal:
        throw UnimplementedError();
    }

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
