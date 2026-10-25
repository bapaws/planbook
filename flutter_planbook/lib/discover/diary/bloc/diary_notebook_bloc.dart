import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/discover/diary/model/diary_notebook_look.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'diary_notebook_event.dart';
part 'diary_notebook_state.dart';

class DiaryNotebookBloc extends Bloc<DiaryNotebookEvent, DiaryNotebookState> {
  DiaryNotebookBloc({required UsersRepository usersRepository})
    : _usersRepository = usersRepository,
      super(
        DiaryNotebookState(
          year: DateTime.now().year,
          byYear: DiaryNotebookLook.fromProfile(
            usersRepository.userProfile?.diaryNotebookLooks ?? const {},
          ),
        ),
      ) {
    on<DiaryNotebookStarted>(_onStarted, transformer: restartable());
    on<DiaryNotebookSaved>(_onSaved, transformer: sequential());
    on<DiaryNotebookYearChanged>(_onYearChanged, transformer: sequential());
    on<DiaryNotebookCalendarToggled>(
      _onCalendarToggled,
      transformer: droppable(),
    );
    add(const DiaryNotebookStarted());
  }

  final UsersRepository _usersRepository;

  Future<void> _onStarted(
    DiaryNotebookStarted event,
    Emitter<DiaryNotebookState> emit,
  ) async {
    await emit.forEach(
      _usersRepository.onUserProfileChange,
      onData: (profile) {
        if (profile != null) {
          unawaited(_usersRepository.migrateLegacyDiaryNotebookLooks());
        }
        return state.copyWith(
          byYear: DiaryNotebookLook.fromProfile(
            profile?.diaryNotebookLooks ?? const {},
          ),
        );
      },
    );
  }

  Future<void> _onSaved(
    DiaryNotebookSaved event,
    Emitter<DiaryNotebookState> emit,
  ) async {
    await _usersRepository.updateDiaryNotebookLook(
      year: event.year,
      look: event.look.toJson(),
    );
  }

  void _onYearChanged(
    DiaryNotebookYearChanged event,
    Emitter<DiaryNotebookState> emit,
  ) {
    emit(state.copyWith(year: event.year));
  }

  void _onCalendarToggled(
    DiaryNotebookCalendarToggled event,
    Emitter<DiaryNotebookState> emit,
  ) {
    emit(
      state.copyWith(
        isCalendarExpanded: event.isExpanded ?? !state.isCalendarExpanded,
      ),
    );
  }
}
