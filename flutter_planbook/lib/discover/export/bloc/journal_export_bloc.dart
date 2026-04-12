import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'journal_export_event.dart';
part 'journal_export_state.dart';

class JournalExportBloc extends Bloc<JournalExportEvent, JournalExportState> {
  JournalExportBloc()
    : super(
        JournalExportReady(
          startDate: Jiffy.now().startOf(Unit.day),
          endDate: Jiffy.now().startOf(Unit.day),
        ),
      ) {
    on<JournalExportStartDateChanged>(_onStartChanged);
    on<JournalExportEndDateChanged>(_onEndChanged);
    on<JournalExportPresetSelected>(_onPreset);
  }

  void _onStartChanged(
    JournalExportStartDateChanged event,
    Emitter<JournalExportState> emit,
  ) {
    final current = state as JournalExportReady;
    final start = event.date.startOf(Unit.day);
    final end = current.endDate.startOf(Unit.day);
    emit(
      current.copyWith(
        startDate: start,
        endDate: start.isAfter(end) ? start : end,
      ),
    );
  }

  void _onEndChanged(
    JournalExportEndDateChanged event,
    Emitter<JournalExportState> emit,
  ) {
    final current = state as JournalExportReady;
    final end = event.date.startOf(Unit.day);
    final start = current.startDate.startOf(Unit.day);
    emit(
      current.copyWith(
        endDate: end,
        startDate: end.isBefore(start) ? end : start,
      ),
    );
  }

  void _onPreset(
    JournalExportPresetSelected event,
    Emitter<JournalExportState> emit,
  ) {
    final now = Jiffy.now();
    switch (event.preset) {
      case JournalExportPreset.today:
        final d = now.startOf(Unit.day);
        emit(JournalExportReady(startDate: d, endDate: d));
      case JournalExportPreset.thisWeek:
        final start = now.startOf(Unit.week).startOf(Unit.day);
        final end = now.endOf(Unit.week).startOf(Unit.day);
        emit(JournalExportReady(startDate: start, endDate: end));
      case JournalExportPreset.thisMonth:
        final start = now.startOf(Unit.month).startOf(Unit.day);
        final end = now.endOf(Unit.month).startOf(Unit.day);
        emit(JournalExportReady(startDate: start, endDate: end));
      case JournalExportPreset.thisYear:
        final start = now.startOf(Unit.year).startOf(Unit.day);
        final end = now.endOf(Unit.year).startOf(Unit.day);
        emit(JournalExportReady(startDate: start, endDate: end));
    }
  }
}
