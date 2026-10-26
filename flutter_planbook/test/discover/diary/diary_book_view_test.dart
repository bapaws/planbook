import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';
import 'package:flutter_planbook/discover/diary/view/diary_book_leaf.dart';
import 'package:flutter_planbook/discover/diary/view/diary_book_view.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper_notebook/paper_notebook.dart';
import 'package:planbook_repository/planbook_repository.dart';

class _NotesRepository extends Mock implements NotesRepository {}

class _AssetsRepository extends Mock implements AssetsRepository {}

NoteEntity _note(String id) => NoteEntity(
  note: Note(
    id: id,
    title: 'A quiet afternoon',
    content: 'A little story to remember.',
    images: const [],
    createdAt: Jiffy.parse('2026-10-23'),
  ),
);

void main() {
  for (final scale in [0.8, 1.6]) {
    testWidgets('系统字号 $scale 在分页和真实阅读页中保持一致', (tester) async {
      final repository = _NotesRepository();
      when(repository.watchDiaryNotes).thenAnswer(
        (_) => Stream.value([
          _note('scaled').copyWith(
            note: _note('scaled').note.copyWith(
              content: Value('记下今天的心情。\n' * 30),
            ),
          ),
        ]),
      );
      final scaler = TextScaler.linear(scale);
      await tester.pumpWidget(
        RepositoryProvider<NotesRepository>.value(
          value: repository,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: scaler),
              child: child!,
            ),
            home: const Scaffold(body: DiaryBookView()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final leafFinder = find.byType(DiaryBookLeaf).first;
      final page = tester.widget<DiaryBookLeaf>(leafFinder).page;
      final texts = tester.widgetList<RichText>(
        find.descendant(of: leafFinder, matching: find.byType(RichText)),
      );
      for (final frame in page.frames.where((frame) => frame.text.isNotEmpty)) {
        final text = texts.firstWhere(
          (text) => text.text.toPlainText() == frame.text,
        );
        expect(text.textScaler.scale(14), scaler.scale(14));
        final painter = TextPainter(
          text: text.text,
          textDirection: text.textDirection,
          textScaler: text.textScaler,
        )..layout(maxWidth: frame.rect.width);
        expect(painter.height, lessThanOrEqualTo(frame.rect.height));
        painter.dispose();
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('日记变更保留阅读位置，删除末篇后页码不会越界', (tester) async {
    final stream = StreamController<List<NoteEntity>>.broadcast();
    final repository = _NotesRepository();
    when(repository.watchDiaryNotes).thenAnswer((_) => stream.stream);
    addTearDown(stream.close);
    await tester.pumpWidget(
      RepositoryProvider<NotesRepository>.value(
        value: repository,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: DiaryBookView()),
        ),
      ),
    );
    await tester.pump();
    stream.add([_note('first'), _note('second')]);
    await tester.pumpAndSettle();
    PaperNotebook notebook() => tester.widget(find.byType(PaperNotebook));
    expect(notebook().pageCount, 2);
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(notebook().controller!.index, 1);
    stream.add([_note('older'), _note('first'), _note('second')]);
    await tester.pumpAndSettle();
    expect(notebook().controller!.index, 2);
    stream.add([_note('older'), _note('first')]);
    await tester.pumpAndSettle();
    expect(notebook().controller!.index, 1);
    stream.add([]);
    await tester.pumpAndSettle();
    expect(notebook().pageCount, 1);
    expect(notebook().controller!.index, 0);
    expect(find.text('Your story starts here'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('热重载会刷新旧排版缓存，同时保留正在阅读的页码', (tester) async {
    final repository = _NotesRepository();
    final note = NoteEntity(
      note: Note(
        id: 'long-diary',
        title: '慢慢记录',
        content: '沿着河边慢慢走，把日常的心情写下来。\n' * 60,
        images: const [],
        createdAt: Jiffy.parse('2026-10-23'),
      ),
    );
    when(repository.watchDiaryNotes).thenAnswer((_) => Stream.value([note]));
    await tester.pumpWidget(
      RepositoryProvider<NotesRepository>.value(
        value: repository,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: DiaryBookView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final controller = tester
        .widget<PaperNotebook>(find.byType(PaperNotebook))
        .controller!;
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    final index = controller.index;
    final before = tester
        .widgetList<DiaryBookLeaf>(find.byType(DiaryBookLeaf))
        .firstWhere((leaf) => leaf.page.part == index)
        .page;
    expect(before.text, isNotEmpty);
    unawaited(tester.binding.reassembleApplication());
    await tester.pumpAndSettle();
    final after = tester
        .widgetList<DiaryBookLeaf>(find.byType(DiaryBookLeaf))
        .firstWhere((leaf) => leaf.page.part == index)
        .page;
    expect(identical(after, before), isFalse);
    expect(after.text, before.text);
    expect(after.layout, before.layout);
    expect(controller.index, index);
    verify(repository.watchDiaryNotes).called(1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('按需读取相邻篇照片比例，翻页中完成读取会在停稳后重排', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _NotesRepository();
    final assets = _AssetsRepository();
    Future<Uint8List> png(int width, int height) async {
      final image = await createTestImage(
        width: width,
        height: height,
        cache: false,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return bytes!.buffer.asUint8List();
    }

    final portrait = (await tester.runAsync(() => png(100, 300)))!;
    final landscape = (await tester.runAsync(() => png(300, 100)))!;
    final delayed = Completer<Uint8List?>();
    const first = '${AssetsRepository.host}/first.png';
    const second = '${AssetsRepository.host}/second.png';
    const third = '${AssetsRepository.host}/third.png';
    when(() => assets.downloadImage(first)).thenAnswer((_) async => portrait);
    when(() => assets.downloadImage(second)).thenAnswer((_) => delayed.future);
    when(() => assets.downloadImage(third)).thenAnswer((_) async => portrait);
    NoteEntity photoNote(String id, String path) {
      final note = _note(id);
      return note.copyWith(note: note.note.copyWith(images: [path]));
    }

    when(repository.watchDiaryNotes).thenAnswer(
      (_) => Stream.value([
        photoNote('first', first),
        photoNote('second', second),
        photoNote('third', third),
      ]),
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<NotesRepository>.value(value: repository),
          RepositoryProvider<AssetsRepository>.value(value: assets),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: DiaryBookView()),
        ),
      ),
    );
    await tester.pump();
    Future<void> decoded(String path) => precacheImage(
      ResizeImage(
        SupaStorageImageProvider(url: path, repository: assets),
        width: 320,
        height: 320,
        policy: ResizeImagePolicy.fit,
      ),
      tester.element(find.byType(DiaryBookView)),
    );
    await tester.runAsync(() => decoded(first));
    await tester.pumpAndSettle();
    verifyNever(() => assets.downloadImage(third));
    DiaryBookLeaf leaf(String id) => tester
        .widgetList<DiaryBookLeaf>(find.byType(DiaryBookLeaf))
        .firstWhere((leaf) => leaf.page.note.id == id);
    final firstRect = leaf('first').page.imageRects.single;
    expect(firstRect.width / firstRect.height, closeTo(1 / 3, 0.001));
    final controller = tester
        .widget<PaperNotebook>(find.byType(PaperNotebook))
        .controller!;
    await tester.tap(find.byTooltip('Next page'));
    await tester.pump(const Duration(milliseconds: 40));
    expect(controller.isAnimating, isTrue);
    delayed.complete(landscape);
    await tester.runAsync(() => decoded(second));
    await tester.pump(const Duration(milliseconds: 20));
    expect(controller.isAnimating, isTrue);
    await tester.pumpAndSettle();
    expect(controller.index, 1);
    final secondRect = leaf('second').page.imageRects.single;
    expect(secondRect.width / secondRect.height, closeTo(3, 0.001));
    expect(
      tester
          .widgetList<AppNetworkImage>(find.byType(AppNetworkImage))
          .map((image) => image.fit),
      everyElement(BoxFit.contain),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
