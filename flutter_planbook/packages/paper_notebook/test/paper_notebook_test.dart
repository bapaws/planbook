import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_notebook/paper_notebook.dart';
import 'package:paper_notebook/src/layout/notebook_format.dart';

/// 数每个页面挂载了几次，用来盯纸页子树有没有被整棵重建。
class _MountCounter extends StatefulWidget {
  const _MountCounter({
    required this.label,
    required this.into,
    required super.key,
  });

  final String label;
  final Map<String, int> into;

  @override
  State<_MountCounter> createState() => _MountCounterState();
}

class _MountCounterState extends State<_MountCounter> {
  @override
  void initState() {
    super.initState();
    widget.into.update(widget.label, (n) => n + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) => Text(widget.label);
}

void main() {
  test('style peek is concentric for A4 and A5', () {
    const a4 = PaperNotebookStyle.defaults;
    expect(a4.leatherPeek, a4.leatherRadius - a4.pageOuterRadius);
    expect(a4.leatherPeek, 10);
    expect(NotebookFormat(a4).pageWidth, 420);
    expect(NotebookFormat(a4).pageHeight, 594);

    final a5 = PaperNotebookStyle.a5();
    expect(a5.pageSize.mmWidth, 148);
    expect(a5.pageSize.mmHeight, 210);
    expect(a5.leatherPeek, a5.leatherRadius - a5.pageOuterRadius);
    expect(a5.leatherPeek, 16);
    expect(NotebookFormat(a5).pageWidth, 296);
    expect(NotebookFormat(a5).pageHeight, 420);
  });

  testWidgets('pageBuilder turns to the next page', (tester) async {
    final controller = PaperNotebookController();
    await tester.pumpWidget(
      MaterialApp(
        home: PaperNotebook(
          controller: controller,
          coverClosed: false,
          pageCount: 3,
          pageBuilder: (_, i) => Text('page-$i'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('page-0'), findsOneWidget);
    expect(controller.index, 0);

    final future = controller.nextPage();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await future;
    await tester.pump();
    expect(controller.index, 1);
    expect(find.text('page-1'), findsOneWidget);
  });

  testWidgets('openCover reveals the inner page', (tester) async {
    final controller = PaperNotebookController();
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PaperNotebook(
          controller: controller,
          coverClosed: true,
          theme: const PaperNotebookTheme(year: 2026, title: 'Journal'),
          onCoverOpened: () => opened = true,
          pageBuilder: (_, i) => Text('leaf-$i'),
        ),
      ),
    );
    await tester.pump();
    expect(controller.isCoverClosed, isTrue);
    expect(find.text('2026'), findsOneWidget);

    final future = controller.openCover();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(opened, isFalse);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    await future;
    expect(opened, isTrue);
    expect(controller.isCoverClosed, isFalse);
    expect(find.text('leaf-0'), findsOneWidget);
  });

  testWidgets('animateTo flips once onto a far page', (tester) async {
    final controller = PaperNotebookController();
    await tester.pumpWidget(
      MaterialApp(
        home: PaperNotebook(
          controller: controller,
          coverClosed: false,
          pageCount: 8,
          pageBuilder: (_, i) => Text('page-$i'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('page-0'), findsOneWidget);

    final future = controller.animateTo(5);
    await tester.pump();
    await tester.pump();
    expect(controller.isAnimating, isTrue);
    expect(find.text('page-1'), findsNothing);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    await future;
    expect(controller.index, 5);
    expect(find.text('page-5'), findsOneWidget);
    expect(find.text('page-0'), findsNothing);
    expect(find.text('page-1'), findsNothing);
  });

  testWidgets('animateTo folds both ways and keeps live pages mounted', (
    tester,
  ) async {
    final mounts = <String, int>{};
    final controller = PaperNotebookController();
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => PaperNotebook(
            controller: controller,
            coverClosed: false,
            initialIndex: 3,
            pageCount: 8,
            pageBuilder: (_, i) =>
                _MountCounter(key: ValueKey(i), label: 'page-$i', into: mounts),
          ),
        ),
      ),
    );
    await tester.pump();
    final startMounts = mounts['page-3'];

    Future<int> foldFrames(Future<void> turn) async {
      var frames = 0;
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        if (find.byKey(const Key('paper-fold-overlay')).evaluate().isNotEmpty) {
          frames++;
        }
      }
      await tester.pumpAndSettle();
      await turn;
      return frames;
    }

    expect(await foldFrames(controller.animateTo(6)), greaterThan(8));
    expect(controller.index, 6);

    expect(await foldFrames(controller.animateTo(1)), greaterThan(8));
    expect(controller.index, 1);

    // 翻页期间手势被禁用，但那不该把纸页子树整棵重建掉。
    expect(mounts['page-3'], startMounts);
  });

  testWidgets('leaf pins header and footer around the body', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: PaperNotebookLeaf(
            header: Text('top-header'),
            footer: Text('bottom-footer'),
            body: Text('middle-body'),
          ),
        ),
      ),
    );
    expect(find.text('top-header'), findsOneWidget);
    expect(find.text('middle-body'), findsOneWidget);
    expect(find.text('bottom-footer'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('top-header')).dy,
      lessThan(tester.getTopLeft(find.text('middle-body')).dy),
    );
    expect(
      tester.getTopLeft(find.text('middle-body')).dy,
      lessThan(tester.getTopLeft(find.text('bottom-footer')).dy),
    );
  });

  testWidgets('closed preview lays out once inside a short scroll slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 280,
                  child: PaperNotebook(
                    coverClosed: true,
                    coverGesturesEnabled: false,
                    gesturesEnabled: false,
                    pageCount: 1,
                    theme: const PaperNotebookTheme(year: 2026),
                    pageBuilder: (context, index) => const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 400),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(PaperNotebook), findsOneWidget);
  });

  testWidgets('controller listenable parent can wrap a closed notebook', (
    tester,
  ) async {
    final controller = PaperNotebookController();
    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, child) => child!,
          child: PaperNotebook(
            controller: controller,
            coverClosed: true,
            pageCount: 1,
            pageBuilder: (context, index) => const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(controller.isCoverClosed, isTrue);
  });

  testWidgets('turning back from the first page closes the cover', (
    tester,
  ) async {
    final controller = PaperNotebookController();
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PaperNotebook(
          controller: controller,
          coverClosed: false,
          pageCount: 3,
          onCoverClosed: () => closed = true,
          pageBuilder: (_, i) => Text('page-$i'),
        ),
      ),
    );
    await tester.pump();
    expect(controller.index, 0);
    expect(controller.isCoverClosed, isFalse);

    final future = controller.previousPage();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    await future;
    expect(closed, isTrue);
    expect(controller.isCoverClosed, isTrue);
    expect(controller.index, 0);
  });

  testWidgets('turning forward from the last page closes the cover', (
    tester,
  ) async {
    final controller = PaperNotebookController();
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PaperNotebook(
          controller: controller,
          coverClosed: false,
          initialIndex: 2,
          pageCount: 3,
          onCoverClosed: () => closed = true,
          pageBuilder: (_, i) => Text('page-$i'),
        ),
      ),
    );
    await tester.pump();
    expect(controller.index, 2);
    expect(controller.isCoverClosed, isFalse);

    final future = controller.nextPage();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    await future;
    expect(closed, isTrue);
    expect(controller.isCoverClosed, isTrue);
    expect(controller.index, 2);
  });

  testWidgets('export-style scope hides the spine gutter', (tester) async {
    late bool showShadow;
    await tester.pumpWidget(
      MaterialApp(
        home: PaperNotebookScope(
          format: NotebookFormat.defaults,
          theme: PaperNotebookTheme.defaults,
          pattern: PaperNotebookPattern.dots,
          showSpineShadow: false,
          child: Builder(
            builder: (context) {
              showShadow = PaperNotebookScope.showSpineShadowOf(context);
              return const PaperNotebookLeaf(
                kindLabel: 'DAY',
                title: 'Hi',
                body: SizedBox.expand(),
              );
            },
          ),
        ),
      ),
    );
    expect(showShadow, isFalse);
    expect(find.byType(PaperNotebookSurface), findsWidgets);
  });
}
