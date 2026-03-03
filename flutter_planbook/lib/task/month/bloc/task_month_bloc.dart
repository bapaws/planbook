import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'task_month_event.dart';
part 'task_month_state.dart';

class TaskMonthBloc extends Bloc<TaskMonthEvent, TaskMonthState> {
  TaskMonthBloc({
    required NotesRepository notesRepository,
    required AppLocalizations l10n,
  }) : _notesRepository = notesRepository,
       _l10n = l10n,
       super(TaskMonthState(date: Jiffy.now())) {
    on<TaskMonthDateSelected>(_onDateSelected);
    on<TaskMonthFocusNoteRequested>(
      _onFocusNoteRequested,
      transformer: restartable(),
    );
    on<TaskMonthSummaryNoteRequested>(
      _onSummaryNoteRequested,
      transformer: restartable(),
    );
    on<TaskMonthCalendarToggled>(_onCalendarToggled);
    on<TaskMonthNoteTaskAppended>(_onNoteTaskAppended);
  }

  final NotesRepository _notesRepository;
  final AppLocalizations _l10n;

  Future<void> _onDateSelected(
    TaskMonthDateSelected event,
    Emitter<TaskMonthState> emit,
  ) async {
    final startOfMonth = event.date.startOf(Unit.month);
    final daysInMonth = event.date.daysInMonth;

    final firstDay = startOfMonth;
    final startOfWeek = firstDay.startOf(Unit.week);

    // 计算第一天是周几（0-6）
    final firstDayOffset = firstDay.dateTime
        .difference(startOfWeek.dateTime)
        .inDays;

    final weeks = <List<Jiffy?>>[];
    var currentWeek = <Jiffy?>[];

    // 填充第一周前面的空白
    for (var i = 0; i < firstDayOffset; i++) {
      currentWeek.add(null);
    }

    // 填充月份的每一天
    for (var i = 0; i < daysInMonth; i++) {
      final day = startOfMonth.add(days: i);
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = <Jiffy?>[];
      }
    }

    // 填充最后一周后面的空白
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    emit(state.copyWith(date: event.date, weeks: weeks));

    add(TaskMonthFocusNoteRequested(date: event.date));
    add(TaskMonthSummaryNoteRequested(date: event.date));
  }

  Future<void> _onFocusNoteRequested(
    TaskMonthFocusNoteRequested event,
    Emitter<TaskMonthState> emit,
  ) async {
    await emit.forEach(
      _notesRepository.getNoteByFocusAt(
        event.date,
        type: NoteType.monthlyFocus,
      ),
      onData: (note) => state.copyWith(
        focusNote: note,
        status: PageStatus.success,
      ),
    );
  }

  Future<void> _onSummaryNoteRequested(
    TaskMonthSummaryNoteRequested event,
    Emitter<TaskMonthState> emit,
  ) async {
    await emit.forEach(
      _notesRepository.getNoteByFocusAt(
        event.date,
        type: NoteType.monthlySummary,
      ),
      onData: (note) => state.copyWith(
        summaryNote: note,
        status: PageStatus.success,
      ),
    );
  }

  Future<void> _onCalendarToggled(
    TaskMonthCalendarToggled event,
    Emitter<TaskMonthState> emit,
  ) async {
    emit(state.copyWith(isCalendarExpanded: !state.isCalendarExpanded));
  }

  Future<void> _onNoteTaskAppended(
    TaskMonthNoteTaskAppended event,
    Emitter<TaskMonthState> emit,
  ) async {
    final currentNote = event.noteType.isFocus
        ? state.focusNote
        : state.summaryNote;
    final title = event.noteType.noteTitle(state.date, _l10n);
    final focusAt = event.noteType.normalizedFocusAt(state.date);
    await _notesRepository.appendTaskLineToNote(
      title: title,
      focusAt: focusAt,
      noteType: event.noteType,
      task: event.task,
      currentNote: currentNote,
    );
  }
}
