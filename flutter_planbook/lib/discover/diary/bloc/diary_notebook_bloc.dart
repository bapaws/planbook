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
  int? _pendingYear;
  DiaryNotebookLook? _pendingLook;

  Future<void> _onStarted(
    DiaryNotebookStarted event,
    Emitter<DiaryNotebookState> emit,
  ) async {
    await emit.forEach(
      _usersRepository.onUserProfileChange,
      onData: (profile) {
        final looks = DiaryNotebookLook.fromProfile(
          profile?.diaryNotebookLooks ?? const {},
        );
        final pendingYear = _pendingYear;
        final pendingLook = _pendingLook;
        if (pendingYear != null && pendingLook != null) {
          looks[pendingYear] = pendingLook;
        }
        return state.copyWith(byYear: looks);
      },
    );
  }

  Future<void> _onSaved(
    DiaryNotebookSaved event,
    Emitter<DiaryNotebookState> emit,
  ) async {
    final hadYear = state.byYear.containsKey(event.year);
    final previous = state.byYear[event.year];
    _pendingYear = event.year;
    _pendingLook = event.look;
    emit(
      state.copyWith(
        byYear: {...state.byYear, event.year: event.look},
      ),
    );
    try {
      await _usersRepository.updateDiaryNotebookLook(
        year: event.year,
        look: event.look.toJson(),
      );
    } on Object {
      _pendingYear = null;
      _pendingLook = null;
      final restored = Map<int, DiaryNotebookLook>.from(state.byYear);
      if (hadYear && previous != null) {
        restored[event.year] = previous;
      } else {
        restored.remove(event.year);
      }
      emit(
        state.copyWith(
          byYear: restored,
          saveFailureCount: state.saveFailureCount + 1,
        ),
      );
      return;
    }
    _pendingYear = null;
    _pendingLook = null;
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
