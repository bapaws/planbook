// 保留公开命名参数及私有依赖字段，兼容项目最低 SDK。
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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
           note:
               initialNote != null &&
                   PeriodNoteTarget(
                     date: focusAt,
                     type: type ?? initialNote.type ?? NoteType.dailyFocus,
                   ).accepts(initialNote)
               ? initialNote
               : null,
           type: type,
           focusAt: focusAt,
         ),
       );

  final NotesRepository _notesRepository;
  final AppLocalizations _l10n;
  int _requestGeneration = 0;
  String? _loadedAccount;
  Future<void>? _saveFuture;

  Future<void> onRequested({Jiffy? focusAt, NoteType? type}) async {
    if (_saveFuture != null || isClosed) return;
    final generation = ++_requestGeneration;
    final account = _notesRepository.userId;
    final target = PeriodNoteTarget(
      date: focusAt ?? state.focusAt,
      type: type ?? state.type,
    );
    emit(
      state.copyWith(
        status: PageStatus.loading,
        isReady: false,
        initialNote: () => null,
        type: target.type,
        focusAt: target.focusAt,
        focusContent: '',
        summaryContent: '',
      ),
    );
    try {
      final note = await _notesRepository
          .getNoteByFocusAt(target.focusAt, type: target.type)
          .first;
      if (isClosed || generation != _requestGeneration) return;
      if (account != _notesRepository.userId ||
          (note != null && (!target.accepts(note) || note.userId != account))) {
        emit(state.copyWith(status: PageStatus.failure, isReady: false));
        return;
      }
      _loadedAccount = account;
      emit(
        NoteTypeNewState.fromData(
          note: note,
          type: target.type,
          focusAt: target.focusAt,
          isReady: true,
        ),
      );
    } on Object {
      if (!isClosed && generation == _requestGeneration) {
        emit(state.copyWith(status: PageStatus.failure, isReady: false));
      }
    }
  }

  Future<void> onTypeChanged(NoteType type) async {
    await onRequested(type: type);
  }

  void onFocusAtChanged(Jiffy focusAt) {
    unawaited(onRequested(focusAt: focusAt));
  }

  void onContentChanged(String content) {
    if (!state.isReady || _saveFuture != null) return;
    if (state.type.isSummary) {
      emit(state.copyWith(summaryContent: content));
    } else {
      emit(state.copyWith(focusContent: content));
    }
  }

  Future<void> onSave() {
    final pending = _saveFuture;
    if (pending != null) return pending;
    if (!state.isReady ||
        isClosed ||
        _loadedAccount != _notesRepository.userId) {
      return Future.value();
    }
    return _saveFuture = _save().whenComplete(() => _saveFuture = null);
  }

  Future<void> _save() async {
    final current = state;
    final target = PeriodNoteTarget(date: current.focusAt, type: current.type);
    emit(state.copyWith(status: PageStatus.loading));
    try {
      await _notesRepository.savePeriodNote(
        target: target,
        title: current.type.noteTitle(target.focusAt, _l10n),
        content: current.content,
      );
      if (!isClosed) emit(state.copyWith(status: PageStatus.success));
    } on Object {
      if (!isClosed) emit(state.copyWith(status: PageStatus.failure));
    }
  }
}
