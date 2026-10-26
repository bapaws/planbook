import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_bookshelf.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_flight.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_reader_page.dart';
import 'package:flutter_planbook/discover/bookshelf/view/notebook_reader_scope.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/diary/view/diary_book_view.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_flip_view.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paper_notebook/paper_notebook.dart';
import 'package:planbook_core/view/flip_page_view.dart';
import 'package:planbook_repository/planbook_repository.dart';

class _NotesRepository extends Mock implements NotesRepository {}

Widget _cover(BuildContext context) => const SizedBox(
  width: kDiscoverJournalDailyPageWidth,
  height: kDiscoverJournalDailyPageHeight,
  child: ColoredBox(color: Colors.green),
);

/// 使用真实计划本翻页引擎，省去与开合无关的数据加载。
class _PlannerReader extends StatefulWidget {
  const _PlannerReader();

  @override
  State<_PlannerReader> createState() => _PlannerReaderState();
}

class _PlannerReaderState extends State<_PlannerReader> {
  final controller = FlipPageController(initialPage: FlipPageIndex.cover);
  final GlobalKey _coverKey = GlobalKey();
  NotebookReaderController? _reader;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reader = NotebookReaderScope.maybeOf(context);
    _reader!.attach(
      this,
      open: () => controller.animateToPage(FlipPageIndex.fromLeft(0)),
      close: () async {
        await _reader!.waitForIdle(controller, () => controller.isAnimating);
        if (mounted) await controller.animateToPage(FlipPageIndex.cover);
      },
      coverRect: () => notebookRenderRect(_coverKey.currentContext),
    );
  }

  @override
  void dispose() {
    _reader?.detach(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: DiscoverJournalFlipView(
      autoOpen: false,
      controller: controller,
      itemsCount: 4,
      coverBuilder: (context) => KeyedSubtree(
        key: _coverKey,
        child: _cover(context),
      ),
      backCoverBuilder: _cover,
      itemBuilder: (context, index) => SizedBox(
        width: kDiscoverJournalDailyPageWidth,
        height: kDiscoverJournalDailyPageHeight,
        child: ColoredBox(color: index.isEven ? Colors.white : Colors.amber),
      ),
      onPageChanged: (_) {},
      onCoverClosed: () => _reader?.onCoverClosed?.call(),
    ),
  );
}

class _Host extends StatefulWidget {
  const _Host({
    required this.pageKey,
    required this.changes,
    required this.readerBuilder,
  });

  final GlobalKey<NotebookReaderPageState> pageKey;
  final List<NotebookKind?> changes;
  final Widget Function(BuildContext, NotebookKind) readerBuilder;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final _shelfKey = GlobalKey<NotebookBookshelfState>();

  Future<void> _open(NotebookKind kind) async {
    final rect = _shelfKey.currentState?.coverGlobalRect(kind);
    if (rect == null) return;
    widget.changes.add(kind);
    NotebookLaunch.request = NotebookLaunchRequest(
      sourceRect: rect,
      coverRectOf: () => _shelfKey.currentState?.coverGlobalRect(kind),
      readerBuilder: widget.readerBuilder,
      productionChrome: false,
    );
    await Navigator.of(context).push<void>(
      NotebookFlightRoute<void>(
        builder: (_) => NotebookReaderPage(key: widget.pageKey, kind: kind),
      ),
    );
    widget.changes.add(null);
  }

  @override
  Widget build(BuildContext context) {
    return NotebookBookshelf(
      key: _shelfKey,
      onOpen: _open,
      onSelected: (_) {},
      plannerCoverBuilder: _cover,
      plannerBackCoverBuilder: _cover,
    );
  }
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    GlobalKey<NotebookReaderPageState> key,
    List<NotebookKind?> changes, {
    List<NoteEntity> diaryNotes = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final notes = _NotesRepository();
    when(notes.watchDiaryNotes).thenAnswer((_) => Stream.value(diaryNotes));
    await tester.pumpWidget(
      RepositoryProvider<NotesRepository>.value(
        value: notes,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(title: const Text('Notebooks')),
            body: _Host(
              pageKey: key,
              changes: changes,
              readerBuilder: (context, kind) => kind == NotebookKind.planner
                  ? const _PlannerReader()
                  : const DiaryBookView(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('有损坏图片的日记可正常打开、翻页和关闭', (tester) async {
    final key = GlobalKey<NotebookReaderPageState>();
    final changes = <NotebookKind?>[];
    await mount(
      tester,
      key,
      changes,
      diaryNotes: [
        for (final id in ['photo-entry', 'text-entry'])
          NoteEntity(
            note: Note(
              id: id,
              title: id,
              content: '即使图片失效，日记正文也应该可以继续阅读。',
              images: id == 'photo-entry'
                  ? const ['assets/images/missing_diary_photo.jpg']
                  : const [],
              createdAt: Jiffy.parse('2026-10-23'),
            ),
          ),
      ],
    );
    await tester.drag(
      find.byKey(const Key('notebook-bookshelf')),
      const Offset(-340, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final notebook = tester.widget<PaperNotebook>(
      find.descendant(
        of: find.byType(DiaryBookView),
        matching: find.byType(PaperNotebook),
      ),
    );
    expect(notebook.controller!.isCoverClosed, isFalse);
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(notebook.controller!.index, 1);
    final closing = key.currentState!.closeNotebook();
    await tester.pumpAndSettle();
    await closing;
    expect(changes, [NotebookKind.diary, null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('开合过渡期间只暴露当前可操作页面的语义', (tester) async {
    final key = GlobalKey<NotebookReaderPageState>();
    final changes = <NotebookKind?>[];
    await mount(tester, key, changes);
    expect(find.semantics.byLabel('Open'), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pump();
    // 书架已不可操作，不能等淡出结束后才从无障碍树中移除。
    expect(find.semantics.byLabel('Open'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('Open'), findsNothing);
    final closing = key.currentState!.closeNotebook();
    await tester.pump();
    expect(find.semantics.byLabel('Open'), findsNothing);
    await tester.pumpAndSettle();
    await closing;
    expect(find.semantics.byLabel('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('计划本从同一封面位置放大，合上后缩回原位，可重复打开', (tester) async {
    final key = GlobalKey<NotebookReaderPageState>();
    final changes = <NotebookKind?>[];
    await mount(tester, key, changes);
    final shelf = tester.state<NotebookBookshelfState>(
      find.byType(NotebookBookshelf),
    );
    final source = shelf.coverGlobalRect(NotebookKind.planner)!;
    await tester.tap(find.text('Open'));
    // 路由首帧只布局终点，下一帧才把封面对齐到书架位置。
    await tester.pump();
    await tester.pump();
    await tester.pump();
    final reader = tester.state<_PlannerReaderState>(
      find.byType(_PlannerReader),
    );
    expect(reader.controller.value, FlipPageIndex.cover);
    final start = notebookRenderRect(reader._coverKey.currentContext)!;
    expect(start.left, closeTo(source.left, 1));
    expect(start.top, closeTo(source.top, 1));
    expect(start.width, closeTo(source.width, 1));
    await tester.pumpAndSettle();
    expect(reader.controller.value, FlipPageIndex.fromLeft(0));
    expect(changes, [NotebookKind.planner]);
    final closing = key.currentState!.closeNotebook();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(_PlannerReader), findsOneWidget);
    expect(changes, [NotebookKind.planner]);
    await tester.pumpAndSettle();
    await closing;
    expect(changes, [NotebookKind.planner, null]);
    expect(find.byType(_PlannerReader), findsNothing);
    expect(tester.state(find.byType(NotebookBookshelf)), same(shelf));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(changes.last, NotebookKind.planner);
    expect(tester.takeException(), isNull);
  });

  testWidgets('开书途中返回会完成合书再回书架，保留日记本选中项', (tester) async {
    final key = GlobalKey<NotebookReaderPageState>();
    final changes = <NotebookKind?>[];
    await mount(tester, key, changes);
    await tester.drag(
      find.byKey(const Key('notebook-bookshelf')),
      const Offset(-340, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pump();
    unawaited(key.currentState!.closeNotebook());
    await tester.pumpAndSettle();
    expect(changes, [NotebookKind.diary, null]);
    expect(find.byType(DiaryBookView), findsNothing);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(changes.last, NotebookKind.diary);
    final notebook = tester.widget<PaperNotebook>(
      find.descendant(
        of: find.byType(DiaryBookView),
        matching: find.byType(PaperNotebook),
      ),
    );
    expect(notebook.controller!.isCoverClosed, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('日记本在第一页往回翻可合上封面并回书架', (tester) async {
    final key = GlobalKey<NotebookReaderPageState>();
    final changes = <NotebookKind?>[];
    await mount(tester, key, changes);
    await tester.drag(
      find.byKey(const Key('notebook-bookshelf')),
      const Offset(-340, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final notebook = tester.widget<PaperNotebook>(
      find.descendant(
        of: find.byType(DiaryBookView),
        matching: find.byType(PaperNotebook),
      ),
    );
    final closing = notebook.controller!.previousPage();
    await tester.pumpAndSettle();
    await closing;
    expect(changes, [NotebookKind.diary, null]);
    expect(find.byType(DiaryBookView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final back in [false, true]) {
    testWidgets('日记本${back ? '向前' : '向后'}翻页中关闭可正常返回书架', (tester) async {
      final key = GlobalKey<NotebookReaderPageState>();
      final changes = <NotebookKind?>[];
      await mount(
        tester,
        key,
        changes,
        diaryNotes: [
          for (var i = 0; i < 3; i++)
            NoteEntity(
              note: Note(
                id: 'entry-$i',
                title: '日记 $i',
                content: '今天的一小段记录。',
                images: const [],
                createdAt: Jiffy.parse('2026-10-23'),
              ),
            ),
        ],
      );
      await tester.drag(
        find.byKey(const Key('notebook-bookshelf')),
        const Offset(-340, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final controller = tester
          .widget<PaperNotebook>(find.byType(PaperNotebook).last)
          .controller!;
      if (back) {
        controller.jumpTo(1);
        await tester.pumpAndSettle();
      }
      final turn = back ? controller.previousPage() : controller.nextPage();
      await tester.pump(const Duration(milliseconds: 60));
      expect(controller.isAnimating, isTrue);
      var closed = false;
      unawaited(key.currentState!.closeNotebook().then((_) => closed = true));
      await tester.pumpAndSettle();
      await turn;
      expect(closed, isTrue);
      expect(changes, [NotebookKind.diary, null]);
      expect(find.byType(DiaryBookView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('计划本正在翻页时关闭，会等待纸页落定再合上', (tester) async {
    final key = GlobalKey<NotebookReaderPageState>();
    final changes = <NotebookKind?>[];
    await mount(tester, key, changes);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final reader = tester.state<_PlannerReaderState>(
      find.byType(_PlannerReader),
    );
    final turn = reader.controller.nextPage();
    await tester.pump(const Duration(milliseconds: 60));
    final close = key.currentState!.closeNotebook();
    await tester.pumpAndSettle();
    await turn;
    await close;
    expect(changes, [NotebookKind.planner, null]);
    expect(find.byType(_PlannerReader), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
