import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations_en.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/note/type/cubit/note_type_new_cubit.dart';
import 'package:flutter_planbook/note/type/view/note_new_type_textfield.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

class _Notes extends Mock implements NotesRepository {}

void main() {
  final date = Jiffy.parse('2026-10-20');
  late _Notes notes;
  late StreamController<Note?> feed;
  late NoteTypeNewCubit cubit;
  late GlobalKey<NavigatorState> navigator;

  Note note(Jiffy at, {String content = '已有正文'}) => Note(
    id: 'note',
    title: '重点',
    content: content,
    images: const [],
    type: NoteType.dailyFocus,
    focusAt: at,
    createdAt: at,
  );

  setUpAll(() {
    registerFallbackValue(date);
    registerFallbackValue(NoteType.dailyFocus);
    registerFallbackValue(
      PeriodNoteTarget(date: date, type: NoteType.dailyFocus),
    );
  });
  setUp(() {
    notes = _Notes();
    feed = StreamController<Note?>.broadcast();
    navigator = GlobalKey<NavigatorState>();
    when(() => notes.userId).thenReturn(null);
    when(
      () => notes.getNoteByFocusAt(any(), type: any(named: 'type')),
    ).thenAnswer((_) => feed.stream);
    cubit = NoteTypeNewCubit(
      notesRepository: notes,
      l10n: AppLocalizationsEn(),
      focusAt: date,
      type: NoteType.dailyFocus,
    );
  });
  tearDown(() async {
    await cubit.close();
    await feed.close();
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          navigatorKey: navigator,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: NoteNewTypeTextfield()),
        ),
      ),
    );
    await tester.pump();
  }

  EditableText editor(WidgetTester tester) => tester.widget<EditableText>(
    find.descendant(
      of: find.byType(NoteNewTypeTextfield, skipOffstage: false),
      matching: find.byType(EditableText, skipOffstage: false),
    ),
  );

  Future<void> load(WidgetTester tester, Note? value) async {
    feed.add(value);
    // 第一帧恢复 enabled，帧末请求焦点，下一帧提交焦点和输入连接。
    await tester.pump();
    await tester.pump();
    expect(cubit.state.isReady, isTrue);
  }

  for (final existing in [false, true]) {
    testWidgets('延迟加载已有笔记=$existing，首次就绪后自动聚焦并弹出键盘', (tester) async {
      unawaited(cubit.onRequested());
      await mount(tester);
      expect(editor(tester).focusNode.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

      await load(tester, existing ? note(date) : null);
      expect(editor(tester).controller.text, existing ? '已有正文' : '');
      expect(editor(tester).focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(find.byType(TextField), '继续编辑');
      expect(cubit.state.content, '继续编辑');
    });
  }

  testWidgets('挂载前已加载完成，仍在首帧后聚焦且保留正文', (tester) async {
    when(
      () => notes.getNoteByFocusAt(any(), type: any(named: 'type')),
    ).thenAnswer((_) => Stream.value(note(date)));
    await cubit.onRequested();
    await mount(tester);
    expect(editor(tester).controller.text, '已有正文');
    expect(editor(tester).focusNode.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('加载失败不聚焦，重试首次就绪才恢复键盘', (tester) async {
    unawaited(cubit.onRequested());
    await mount(tester);
    feed.addError(StateError('读取失败'));
    await tester.pump();
    expect(cubit.state.status, PageStatus.failure);
    expect(editor(tester).focusNode.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);

    unawaited(cubit.onRequested());
    await load(tester, note(date));
    expect(editor(tester).focusNode.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('首次聚焦回调前快速换日期，旧回调跳过并等待新日期就绪', (tester) async {
    unawaited(cubit.onRequested());
    await mount(tester);
    feed.add(note(date));
    await tester.idle();
    expect(cubit.state.isReady, isTrue);

    final nextDate = date.add(days: 1);
    unawaited(cubit.onRequested(focusAt: nextDate));
    await tester.pump();
    expect(cubit.state.isReady, isFalse);
    expect(editor(tester).focusNode.hasFocus, isFalse);
    await load(tester, note(nextDate, content: '新日期正文'));
    expect(editor(tester).controller.text, '新日期正文');
    expect(editor(tester).focusNode.hasFocus, isTrue);
    expect(cubit.state.focusAt, nextDate);
  });

  testWidgets('用户收起键盘后，内容更新与切换日期不再次抢焦点', (tester) async {
    unawaited(cubit.onRequested());
    await mount(tester);
    await load(tester, note(date));
    editor(tester).focusNode.unfocus();
    await tester.pump();
    cubit.onContentChanged('用户修改正文');
    await tester.pump();
    expect(editor(tester).focusNode.hasFocus, isFalse);

    final nextDate = date.add(days: 1);
    unawaited(cubit.onRequested(focusAt: nextDate));
    await tester.pump();
    await load(tester, note(nextDate));
    expect(editor(tester).controller.text, '已有正文');
    expect(editor(tester).focusNode.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('保存失败后不重复自动聚焦或抢回已收起的键盘', (tester) async {
    final saving = Completer<Note>();
    when(
      () => notes.savePeriodNote(
        target: any(named: 'target'),
        title: any(named: 'title'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((_) => saving.future);
    unawaited(cubit.onRequested());
    await mount(tester);
    await load(tester, note(date));
    editor(tester).focusNode.unfocus();
    await tester.pump();
    unawaited(cubit.onSave());
    await tester.pump();
    saving.completeError(StateError('保存失败'));
    await tester.pump();
    await tester.pump();
    expect(cubit.state.status, PageStatus.failure);
    expect(editor(tester).focusNode.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('就绪回调待执行时关闭页面，不操作已销毁的 FocusNode', (tester) async {
    unawaited(cubit.onRequested());
    await mount(tester);
    feed.add(note(date));
    await tester.idle();
    expect(cubit.state.isReady, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('查询返回前被其他页面覆盖，不抢走覆盖页的输入焦点', (tester) async {
    unawaited(cubit.onRequested());
    await mount(tester);
    const covered = ValueKey('covered-input');
    unawaited(
      navigator.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: TextField(key: covered, autofocus: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final otherEditor = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(covered),
        matching: find.byType(EditableText),
      ),
    );
    expect(otherEditor.focusNode.hasFocus, isTrue);
    await load(tester, note(date));
    expect(editor(tester).focusNode.hasFocus, isFalse);
    expect(otherEditor.focusNode.hasFocus, isTrue);
  });
}
