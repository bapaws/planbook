import 'dart:async';

import 'package:flutter_planbook/l10n/gen/app_localizations_en.dart';
import 'package:flutter_planbook/note/type/cubit/note_type_new_cubit.dart';
import 'package:flutter_planbook/task/month/bloc/task_month_bloc.dart';
import 'package:flutter_planbook/task/today/bloc/task_today_bloc.dart';
import 'package:flutter_planbook/task/week/bloc/task_week_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';

class _Notes extends Mock implements NotesRepository {}

class _Tasks extends Mock implements TasksRepository {}

final _date = Jiffy.parse('2026-10-19');
TaskEntity _task() => TaskEntity(
  task: Task(
    id: 'task',
    title: '拖入任务',
    layer: 0,
    childCount: 0,
    order: 0,
    isAllDay: true,
    alarms: const [],
    createdAt: _date,
  ),
);
Note _note(Jiffy date, NoteType type, {String id = 'note'}) => Note(
  id: id,
  title: id,
  content: id,
  images: const [],
  type: type,
  focusAt: PeriodNoteTarget(date: date, type: type).focusAt,
  createdAt: date,
);

/// 同一组断言覆盖真实日/周/月 Bloc，保留各自原 emit.forEach 数据入口。
class _Harness {
  _Harness(this.kind) {
    when(() => notes.userId).thenReturn(null);
    when(() => notes.getNoteByFocusAt(any(), type: any(named: 'type')))
        .thenAnswer((call) {
          final date = call.positionalArguments.first as Jiffy;
          final type = call.namedArguments[#type] as NoteType;
          final key = PeriodNoteTarget(date: date, type: type);
          return (feeds[key] ??= StreamController<Note?>.broadcast()).stream;
        });
    when(
      () => notes.appendTaskLineToNote(
        title: any(named: 'title'),
        focusAt: any(named: 'focusAt'),
        noteType: any(named: 'noteType'),
        task: any(named: 'task'),
        currentNote: any(named: 'currentNote'),
      ),
    ).thenAnswer((call) async {
      writes.add(call);
    });
    switch (kind) {
      case 'day':
        when(
          () => tasks.getTaskCount(
            date: any(named: 'date'),
            mode: any(named: 'mode'),
            isCompleted: any(named: 'isCompleted'),
          ),
        ).thenAnswer((_) => const Stream<int>.empty());
        day = TaskTodayBloc(
          tasksRepository: tasks,
          notesRepository: notes,
          l10n: AppLocalizationsEn(),
        );
      case 'week':
        week = TaskWeekBloc(notesRepository: notes, l10n: AppLocalizationsEn());
      case 'month':
        month = TaskMonthBloc(
          notesRepository: notes,
          l10n: AppLocalizationsEn(),
        );
    }
  }
  final String kind;
  final notes = _Notes();
  final tasks = _Tasks();
  final feeds = <PeriodNoteTarget, StreamController<Note?>>{};
  final writes = <Invocation>[];
  TaskTodayBloc? day;
  TaskWeekBloc? week;
  TaskMonthBloc? month;
  NoteType get focus => switch (kind) {
    'day' => NoteType.dailyFocus,
    'week' => NoteType.weeklyFocus,
    _ => NoteType.monthlyFocus,
  };
  Jiffy get date => day?.state.date ?? week?.state.date ?? month!.state.date;
  PeriodNoteSnapshot snapshot(NoteType type) =>
      day?.state.noteSnapshot(type) ??
      week?.state.noteSnapshot(type) ??
      month!.state.noteSnapshot(type);
  void select(Jiffy date) {
    day?.add(TaskTodayDateSelected(date: date));
    week?.add(TaskWeekDateSelected(date: date));
    month?.add(TaskMonthDateSelected(date: date));
  }

  void data(Jiffy date, NoteType type, Note? value) =>
      feeds[PeriodNoteTarget(date: date, type: type)]!.add(value);
  void error(NoteType type) => feeds[PeriodNoteTarget(date: date, type: type)]!
      .addError(StateError('模拟读取失败'));
  void append(NoteType type, {PeriodNoteTarget? target}) {
    day?.add(
      TaskTodayNoteTaskAppended(task: _task(), noteType: type, target: target),
    );
    week?.add(
      TaskWeekNoteTaskAppended(task: _task(), noteType: type, target: target),
    );
    month?.add(
      TaskMonthNoteTaskAppended(task: _task(), noteType: type, target: target),
    );
  }

  Future<void> close() async {
    await day?.close();
    await week?.close();
    await month?.close();
    for (final feed in feeds.values) {
      await feed.close();
    }
  }
}

void main() {
  setUpAll(() async {
    await Jiffy.setLocale('en');
    registerFallbackValue(_date);
    registerFallbackValue(NoteType.dailyFocus);
    registerFallbackValue(TaskListMode.today);
    registerFallbackValue(_task());
    registerFallbackValue(
      PeriodNoteTarget(date: _date, type: NoteType.dailyFocus),
    );
  });
  for (final kind in ['day', 'week', 'month']) {
    for (final summary in [false, true]) {
      test('$kind summary=$summary：换周期清空旧值，未加载不写入，空结果就绪后可创建', () async {
        final h = _Harness(kind);
        addTearDown(h.close);
        final type = summary ? h.focus.sameRangeNoteType : h.focus;
        h.select(_date);
        await pumpEventQueue();
        final old = _note(_date, type);
        h.data(_date, type, old);
        await pumpEventQueue();
        expect(h.snapshot(type).canWrite, isTrue);
        final oldTarget = h.snapshot(type).target;
        final next = _date.add(months: 2);
        h.select(next);
        await pumpEventQueue();
        expect(h.snapshot(type).note, isNull);
        expect(h.snapshot(type).canWrite, isFalse);
        h.append(type, target: h.snapshot(type).target);
        await pumpEventQueue();
        expect(h.writes, isEmpty);
        h.data(_date, type, old);
        await pumpEventQueue();
        expect(h.snapshot(type).canWrite, isFalse);
        h.data(next, type, null);
        await pumpEventQueue();
        expect(h.snapshot(type).canWrite, isTrue);
        h.append(type, target: oldTarget);
        await pumpEventQueue();
        expect(h.writes, isEmpty);
        h.append(type, target: h.snapshot(type).target);
        await pumpEventQueue();
        expect(h.writes, hasLength(1));
        expect(h.writes.single.namedArguments[#currentNote], isNull);
        expect(
          h.writes.single.namedArguments[#focusAt],
          h.snapshot(type).target.focusAt,
        );
      });
    }
    test('$kind：返回空值清除笔记，错误与错误归属不能视为空笔记，恢复流后可写', () async {
      final h = _Harness(kind);
      addTearDown(h.close);
      h.select(_date);
      await pumpEventQueue();
      h.data(_date, h.focus, _note(_date, h.focus));
      await pumpEventQueue();
      h.data(_date, h.focus, null);
      await pumpEventQueue();
      expect(h.snapshot(h.focus).note, isNull);
      expect(h.snapshot(h.focus).canWrite, isTrue);
      h.error(h.focus);
      await pumpEventQueue();
      expect(h.snapshot(h.focus).canWrite, isFalse);
      h.append(h.focus);
      await pumpEventQueue();
      expect(h.writes, isEmpty);
      h.data(_date, h.focus, _note(_date.add(months: 2), h.focus));
      await pumpEventQueue();
      expect(h.snapshot(h.focus).note, isNull);
      expect(h.snapshot(h.focus).canWrite, isFalse);
      h.data(_date, h.focus, _note(_date, h.focus));
      await pumpEventQueue();
      expect(h.snapshot(h.focus).canWrite, isTrue);
    });
    test('$kind：A→B→A 迟到请求不覆盖当前周期，重点与总结独立就绪', () async {
      final h = _Harness(kind);
      addTearDown(h.close);
      final b = _date.add(months: 2);
      h
        ..select(_date)
        ..select(b)
        ..select(_date);
      await pumpEventQueue();
      h.data(_date, h.focus, _note(_date, h.focus, id: '当前'));
      await pumpEventQueue();
      if (h.feeds.containsKey(PeriodNoteTarget(date: b, type: h.focus))) {
        h.data(b, h.focus, _note(b, h.focus, id: '迟到'));
      }
      await pumpEventQueue();
      expect(h.snapshot(h.focus).note?.id, '当前');
      expect(h.snapshot(h.focus).canWrite, isTrue);
      expect(h.snapshot(h.focus.sameRangeNoteType).canWrite, isFalse);
    });
  }

  test('月 copyWith 不传保留，显式 null 独立清空重点与总结', () {
    final state = TaskMonthState(
      date: _date,
      focusNote: _note(_date, NoteType.monthlyFocus),
      summaryNote: _note(_date, NoteType.monthlySummary),
    );
    expect(state.copyWith().focusNote, state.focusNote);
    expect(state.copyWith(focusNote: () => null).focusNote, isNull);
    expect(
      state.copyWith(focusNote: () => null).summaryNote,
      state.summaryNote,
    );
    expect(state.copyWith(summaryNote: () => null).summaryNote, isNull);
  });

  test('编辑器重新核验归属：加载前不可保存，错周期旧快照不能写旧 ID', () async {
    final notes = _Notes();
    when(() => notes.userId).thenReturn(null);
    final feed = StreamController<Note?>();
    when(() => notes.getNoteByFocusAt(any(), type: any(named: 'type')))
        .thenAnswer((_) => feed.stream);
    final writes = <Invocation>[];
    when(
      () => notes.savePeriodNote(
        target: any(named: 'target'),
        title: any(named: 'title'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((call) async {
      writes.add(call);
      return _note(_date, NoteType.monthlyFocus);
    });
    final cubit = NoteTypeNewCubit(
      notesRepository: notes,
      l10n: AppLocalizationsEn(),
      focusAt: _date,
      type: NoteType.monthlyFocus,
      initialNote: _note(_date.add(months: -1), NoteType.monthlyFocus),
    );
    addTearDown(() async {
      await cubit.close();
      await feed.close();
    });
    expect(cubit.state.initialNote, isNull);
    final loading = cubit.onRequested();
    await pumpEventQueue();
    await cubit.onSave();
    expect(writes, isEmpty);
    feed.add(_note(_date, NoteType.monthlyFocus, id: '当前月'));
    await loading;
    expect(cubit.state.initialNote?.id, '当前月');
    expect(cubit.state.isReady, isTrue);
    cubit.onContentChanged('新内容');
    await cubit.onSave();
    expect(writes.single.namedArguments[#content], '新内容');
    expect(
      writes.single.namedArguments[#target],
      PeriodNoteTarget(date: _date, type: NoteType.monthlyFocus),
    );
  });

  test('编辑器快速换周期忽略迟到结果，并发保存合并一次', () async {
    final notes = _Notes();
    when(() => notes.userId).thenReturn(null);
    final a = StreamController<Note?>();
    final b = StreamController<Note?>();
    when(() => notes.getNoteByFocusAt(any(), type: any(named: 'type')))
        .thenAnswer(
          (call) =>
              (call.positionalArguments.first as Jiffy).month == _date.month
              ? a.stream
              : b.stream,
        );
    final saved = Completer<Note>();
    var writes = 0;
    when(
      () => notes.savePeriodNote(
        target: any(named: 'target'),
        title: any(named: 'title'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((_) {
      writes++;
      return saved.future;
    });
    final cubit = NoteTypeNewCubit(
      notesRepository: notes,
      l10n: AppLocalizationsEn(),
      focusAt: _date,
      type: NoteType.monthlyFocus,
    );
    addTearDown(() async {
      await cubit.close();
      await a.close();
      await b.close();
    });
    final old = cubit.onRequested();
    final next = _date.add(months: 1);
    final current = cubit.onRequested(focusAt: next);
    b.add(null);
    await current;
    a.add(_note(_date, NoteType.monthlyFocus));
    await old;
    expect(cubit.state.focusAt.month, next.month);
    expect(cubit.state.initialNote, isNull);
    cubit.onContentChanged('当前月');
    final first = cubit.onSave();
    final second = cubit.onSave();
    expect(identical(first, second), isTrue);
    expect(writes, 1);
    saved.complete(_note(next, NoteType.monthlyFocus));
    await first;
    expect(cubit.state.status, PageStatus.success);
  });
}
