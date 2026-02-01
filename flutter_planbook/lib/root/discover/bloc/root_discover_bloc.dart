import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/note_type.dart';

part 'root_discover_event.dart';
part 'root_discover_state.dart';

class RootDiscoverBloc extends Bloc<RootDiscoverEvent, RootDiscoverState> {
  RootDiscoverBloc() : super(const RootDiscoverState()) {
    on<RootDiscoverAutoPlay>(_onAutoPlay);
    on<RootDiscoverFocusDateChanged>(
      _onFocusDateChanged,
      transformer: sequential(),
    );
    on<RootDiscoverSummaryDateChanged>(
      _onSummaryDateChanged,
      transformer: sequential(),
    );
  }

  Future<void> _onAutoPlay(
    RootDiscoverAutoPlay event,
    Emitter<RootDiscoverState> emit,
  ) async {
    emit(state.copyWith(autoPlayCount: state.autoPlayCount + 1));
  }

  Future<void> _onFocusDateChanged(
    RootDiscoverFocusDateChanged event,
    Emitter<RootDiscoverState> emit,
  ) async {
    emit(
      state.copyWith(
        focusDate: () => event.date,
        focusType: () => event.type,
      ),
    );
  }

  Future<void> _onSummaryDateChanged(
    RootDiscoverSummaryDateChanged event,
    Emitter<RootDiscoverState> emit,
  ) async {
    emit(
      state.copyWith(
        summaryDate: () => event.date,
        summaryType: () => event.type,
      ),
    );
  }
}
