import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/bloc/app_bloc.dart';
import 'package:flutter_planbook/app/model/app_seed_colors.dart';
import 'package:flutter_planbook/discover/diary/bloc/diary_notebook_bloc.dart';
import 'package:flutter_planbook/discover/export/view/diary_export_page.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planbook_repository/planbook_repository.dart';

class _Notes extends Mock implements NotesRepository {}

class _Assets extends Mock implements AssetsRepository {}

class _App extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _Notebook extends MockBloc<DiaryNotebookEvent, DiaryNotebookState>
    implements DiaryNotebookBloc {}

void main() {
  testWidgets('iPad 导出真实 PDF 时传入按钮的有效分享锚点', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1366));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final directory = Directory.systemTemp.createTempSync('planbook-export-');
    addTearDown(() => directory.deleteSync(recursive: true));
    const paths = MethodChannel('plugins.flutter.io/path_provider');
    const share = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    Map<Object?, Object?>? shared;
    messenger
      ..setMockMethodCallHandler(paths, (_) async => directory.path)
      ..setMockMethodCallHandler(share, (call) async {
        shared = call.arguments as Map<Object?, Object?>;
        return 'selected';
      });
    addTearDown(() {
      messenger
        ..setMockMethodCallHandler(paths, null)
        ..setMockMethodCallHandler(share, null);
    });
    final notes = _Notes();
    when(notes.watchDiaryNotes).thenAnswer(
      (_) => Stream.value([_note('diary', '2026-10-23')]),
    );
    final app = _App();
    when(() => app.state).thenReturn(
      const AppState(darkMode: null, seedColor: AppSeedColors.green),
    );
    final notebook = _Notebook();
    when(() => notebook.state).thenReturn(const DiaryNotebookState(year: 2026));
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<NotesRepository>.value(value: notes),
          RepositoryProvider<AssetsRepository>.value(value: _Assets()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: app),
            BlocProvider<DiaryNotebookBloc>.value(value: notebook),
          ],
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: EasyLoading.init(),
            home: const DiaryExportPage(year: 2026),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pdf = find.widgetWithText(CupertinoButton, 'Export PDF');
    final buttonRect = tester.getRect(pdf);
    await tester.tap(pdf);
    // 截图编码、PDF 生成及写盘需要真实异步环境；持续推进帧以完成逐页截图。
    await tester.runAsync(() async {
      for (var frame = 0; frame < 100 && shared == null; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    expect(shared, isNotNull);
    final args = shared!;
    final origin = Rect.fromLTWH(
      args['originX']! as double,
      args['originY']! as double,
      args['originWidth']! as double,
      args['originHeight']! as double,
    );
    expect(origin, buttonRect);
    expect(origin.isEmpty, isFalse);
    expect(
      (Offset.zero & const Size(1024, 1366)).contains(origin.center),
      isTrue,
    );
    final file = File((args['paths']! as List).single as String);
    final bytes = file.readAsBytesSync();
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    await EasyLoading.dismiss();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('只保留指定年份写下的日记', () {
    final notes = [
      _note('this-year', '2026-10-23'),
      _note('last-year', '2025-12-31'),
      _note('next-year', '2027-01-01'),
    ];

    final selected = diaryNotesForYear(notes, 2026);

    expect(selected.map((note) => note.id), ['this-year']);
  });
}

NoteEntity _note(String id, String day) => NoteEntity(
  note: Note(
    id: id,
    title: 'A quiet afternoon',
    content: 'A little story to remember.',
    images: const [],
    createdAt: Jiffy.parse(day),
  ),
);
