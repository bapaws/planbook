import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'discover_journal_event.dart';
part 'discover_journal_state.dart';

class DiscoverJournalBloc
    extends Bloc<DiscoverJournalEvent, DiscoverJournalState> {
  DiscoverJournalBloc({
    required Jiffy now,
  }) : super(
         DiscoverJournalState(date: now),
       ) {
    on<JournalHomeRequested>(_onRequested);
    on<DiscoverJournalDateChanged>(_onDateChanged);

    on<JournalHomeCalendarToggled>(_onCalendarToggled);
    on<JournalHomeViewTypeChanged>(_onViewTypeChanged);
  }

  Future<void> _onRequested(
    JournalHomeRequested event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    emit(state.copyWith(status: PageStatus.success));
  }

  Future<void> _onDateChanged(
    DiscoverJournalDateChanged event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    emit(state.copyWith(date: event.date));
  }

  Future<void> _onCalendarToggled(
    JournalHomeCalendarToggled event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    emit(state.copyWith(isCalendarExpanded: !state.isCalendarExpanded));
  }

  Future<void> _onViewTypeChanged(
    JournalHomeViewTypeChanged event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    emit(state.copyWith(viewType: event.viewType));
  }
}
