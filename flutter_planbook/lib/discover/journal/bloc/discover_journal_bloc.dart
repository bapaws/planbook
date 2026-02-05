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
    on<JournalHomeYearChanged>(_onYearChanged);
    on<JournalHomeCalendarToggled>(_onCalendarToggled);
  }

  Future<void> _onRequested(
    JournalHomeRequested event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    emit(state.copyWith(status: PageStatus.loading));
    emit(state.copyWith(status: PageStatus.success));
  }

  Future<void> _onYearChanged(
    JournalHomeYearChanged event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    final startOfYear = event.date.startOf(Unit.year);
    emit(state.copyWith(date: startOfYear));
  }

  Future<void> _onCalendarToggled(
    JournalHomeCalendarToggled event,
    Emitter<DiscoverJournalState> emit,
  ) async {
    emit(state.copyWith(isCalendarExpanded: !state.isCalendarExpanded));
  }
}
