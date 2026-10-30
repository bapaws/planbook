import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/diary/model/diary_book_document.dart';
import 'package:flutter_planbook/discover/diary/view/diary_book_leaf.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

void main() {
  testWidgets('日记图片失效时占位图尺寸有限，不破坏页面布局与语义', (tester) async {
    await tester.binding.setSurfaceSize(kDiaryPageSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final document = DiaryBookDocument.fromNotes([
      NoteEntity(
        note: Note(
          id: 'broken-photo',
          title: '有照片的日记',
          content: '图片失效时，文字仍应该正常显示。',
          images: const ['assets/images/missing_diary_photo.jpg'],
          createdAt: Jiffy.parse('2026-10-23'),
        ),
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DiaryBookLeaf(page: document.pages.first, number: 1),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('全部杂志版式、深色模式和大字号续页没有布局溢出', (tester) async {
    await tester.binding.setSurfaceSize(kDiaryPageSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final (brightness, scale) in [
      (Brightness.light, 1.0),
      (Brightness.light, 1.6),
      (Brightness.dark, 1.0),
    ]) {
      final scaler = TextScaler.linear(scale);
      final notes = [
        for (var count = 0; count <= 9; count++)
          for (var seed = 0; seed < 10; seed++)
            NoteEntity(
              note: Note(
                id: 'layout-$seed',
                title: '夏日的午后',
                content: '阳光穿过树叶，咖啡的香气慢慢散开。\n生活中细小的快乐，值得认真记下。\n' * 4,
                images: List.generate(
                  count,
                  (index) => index < 4
                      ? [
                          'assets/images/cover1.jpg',
                          'assets/images/cover2.jpg',
                          'assets/images/cover3.png',
                          'assets/images/cover.jpg',
                        ][index]
                      : 'assets/images/missing_diary_photo_$index.jpg',
                ),
                createdAt: Jiffy.parse('2026-10-23'),
              ),
            ),
      ];
      final document = DiaryBookDocument.fromNotes(notes, textScaler: scaler);
      for (var index = 0; index < document.pages.length; index++) {
        final page = document.pages[index];
        final entryCount = document.pages
            .where((item) => item.note.id == page.note.id)
            .length;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: scaler),
              child: child!,
            ),
            home: DiaryBookLeaf(
              page: page,
              number: index + 1,
              entryCount: entryCount,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason:
              '${document.pages[index].layout} / $brightness / $scale / $index',
        );
      }
    }
  });

  testWidgets('所有新增留白构图在深色和放大字号下仍正常渲染', (tester) async {
    await tester.binding.setSurfaceSize(kDiaryPageSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final note = NoteEntity(
      note: Note(
        id: 'quiet-render',
        title: '',
        images: const [],
        createdAt: Jiffy.parse('2026-10-24'),
      ),
    );
    for (final (brightness, scale) in [
      (Brightness.light, 1.0),
      (Brightness.light, 2.5),
      (Brightness.dark, 1.0),
    ]) {
      for (final layout in DiaryPageLayout.values.where(
        (layout) => layout.isQuiet,
      )) {
        final page = DiaryBookPage(
          note: note,
          part: 0,
          layout: layout,
          images: List.filled(
            layout.imageRects.length,
            'assets/images/cover2.jpg',
          ),
          frames: [
            for (final rect in layout.textRects)
              DiaryTextFrame(
                rect: rect,
                text: '留白',
                titleLength: 0,
                layout: layout,
              ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: DiaryBookLeaf(page: page, number: 1),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${layout.name} / $brightness / $scale',
        );
      }
    }
  });

  testWidgets('跨页日记的续页标出标题和篇内页码', (tester) async {
    await tester.binding.setSurfaceSize(kDiaryPageSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final document = DiaryBookDocument.fromNotes([
      NoteEntity(
        note: Note(
          id: 'long-entry',
          title: '很长的一天',
          content: '这一天发生了很多事。\n' * 80,
          images: const [],
          createdAt: Jiffy.parse('2026-10-23'),
        ),
      ),
    ]);
    expect(document.pages.length, greaterThan(1));
    final total = document.pages.length;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DiaryBookLeaf(
          page: document.pages[1],
          number: 2,
          entryCount: total,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('很长的一天'), findsOneWidget);
    expect(find.text('2 / $total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
