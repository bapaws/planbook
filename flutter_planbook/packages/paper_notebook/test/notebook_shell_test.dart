import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_notebook/paper_notebook.dart';
import 'package:paper_notebook/src/engine/notebook_shell.dart';
import 'package:paper_notebook/src/engine/turnable_paper_flip.dart';
import 'package:paper_notebook/src/layout/notebook_format.dart';

void main() {
  const format = NotebookFormat.defaults;

  test('cover shift finishes around 135 degrees', () {
    expect(format.openShiftX(0), closeTo(-format.pageLeft / 2, 0.001));
    expect(format.openShiftX(0.75), closeTo(0, 0.001));
    expect(format.openShiftX(1), closeTo(0, 0.001));
    expect(format.openShiftX(1, 1), closeTo(format.filledViewShiftX, 0.001));
    expect(format.openShiftX(0.5), lessThan(0));
    expect(format.openShiftX(0.5), greaterThan(format.openShiftX(0)));
  });

  test('cover inside page maps onto the landed left leaf', () {
    final hinge = format.pageLeft;
    final localLeft = BookVersoLeaf.coverInsideLeft;
    final localRight = localLeft + BookVersoLeaf.stackWidthOf(format);
    expect(
      hinge - localRight,
      closeTo(BookVersoLeaf.stackLeft(hinge, format.leftLeafWidth), 0.001),
    );
    expect(
      hinge - localLeft,
      closeTo(
        BookVersoLeaf.stackLeft(hinge, format.leftLeafWidth) +
            BookVersoLeaf.stackWidthOf(format),
        0.001,
      ),
    );
    expect(
      BookVersoLeaf.borderRadius(spineOnLeft: true).topRight,
      const Radius.circular(BookVersoLeaf.outerRadius),
    );
    expect(
      BookVersoLeaf.borderRadius(spineOnLeft: true).topLeft,
      const Radius.circular(BookVersoLeaf.spineRadius),
    );
  });

  test('kraft and page outer corners share a center', () {
    expect(format.leatherPeek, format.leatherRadius - format.pageOuterRadius);
    final radius = BorderRadius.only(
      topRight: Radius.circular(format.leatherRadius),
      bottomRight: Radius.circular(format.leatherRadius),
    );
    expect(radius.topRight.x, format.leatherRadius);
    expect(radius.bottomRight.x, format.leatherRadius);
    expect(radius.topLeft.x, 0);
    expect(radius.bottomLeft.x, 0);
    final kraftCenter = Offset(
      format.frontCoverWidth - format.leatherRadius,
      format.leatherRadius,
    );
    final pageCenter = Offset(
      format.pageWidth - format.pageOuterRadius,
      format.leatherPeekTop + format.pageOuterRadius,
    );
    expect(pageCenter.dx, closeTo(kraftCenter.dx, 0.001));
    expect(pageCenter.dy, closeTo(kraftCenter.dy, 0.001));
  });

  testWidgets('notebook shell shows the page on a leather cover', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotebookShell(child: Text('inner-page'))),
    );
    expect(find.text('inner-page'), findsOneWidget);
    expect(find.byType(NotebookShell), findsOneWidget);
    final stackFinder = find.descendant(
      of: find.byType(NotebookShell),
      matching: find.byType(Stack),
    );
    expect(
      tester
          .widgetList<Stack>(stackFinder)
          .any((stack) => stack.clipBehavior == Clip.none),
      isTrue,
    );
  });

  testWidgets('notebook centers the full dual-page canvas in the viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: NotebookShell(child: Text('page'))),
    );
    await tester.pump();
    final shell = tester.getRect(find.byType(NotebookShell));
    final viewport = tester.getRect(find.byKey(NotebookShell.viewportKey));
    final canvas = tester.getRect(find.byKey(NotebookShell.canvasKey));
    expect(viewport.width, closeTo(canvas.width, 0.5));
    expect(viewport.height, closeTo(canvas.height, 0.5));
    expect(canvas.left, closeTo(viewport.left, 0.5));
    expect(canvas.right, closeTo(viewport.right, 0.5));
    expect(viewport.center.dx, closeTo(shell.center.dx, 1));
    expect(format.viewCropLeft, 0);
  });

  testWidgets('opened notebook fills the screen with the right page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: NotebookShell(child: Text('page'))),
    );
    await tester.pump();
    final shell = tester.getRect(find.byType(NotebookShell));
    final canvas = tester.getRect(find.byKey(NotebookShell.canvasKey));
    final scale = canvas.width / format.designWidth;
    expect(format.filledViewWidth * scale, closeTo(shell.width, 2));
  });

  testWidgets('closed cover is kraft paper with the year on it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: NotebookShell(
          cover: PaperNotebookCover(year: 2026),
          coverClosed: true,
          child: Text('today-page'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('2026'), findsOneWidget);
    expect(find.byType(PaperNotebookCover), findsOneWidget);
    expect(find.byKey(NotebookShell.frontCoverKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NotebookShell),
        matching: find.byType(ClipRect),
      ),
      findsAtLeastNWidgets(1),
    );
    final shell = tester.getRect(find.byType(NotebookShell));
    final cover = tester.getRect(find.byKey(NotebookShell.frontCoverKey));
    expect(cover.center.dx, closeTo(shell.center.dx, 12));
  });

  testWidgets('opening the closed cover shifts the notebook right', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CoverTurnController();
    await tester.pumpWidget(
      MaterialApp(
        home: NotebookShell(
          cover: const PaperNotebookCover(year: 2026),
          coverClosed: true,
          controller: controller,
          child: const Text('today-page'),
        ),
      ),
    );
    await tester.pump();
    final closed = tester.widget<Transform>(
      find.byKey(NotebookShell.openShiftKey),
    );
    expect(
      closed.transform.getTranslation().x,
      closeTo(-format.pageLeft / 2, 0.5),
    );

    controller.open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final opening = tester.widget<Transform>(
      find.byKey(NotebookShell.openShiftKey),
    );
    expect(
      opening.transform.getTranslation().x,
      greaterThan(closed.transform.getTranslation().x + 40),
    );

    await tester.pump(const Duration(milliseconds: 180));
    final settledShift = tester.widget<Transform>(
      find.byKey(NotebookShell.openShiftKey),
    );
    expect(settledShift.transform.getTranslation().x, closeTo(0, 0.5));
    await tester.pumpAndSettle();
  });

  testWidgets('opening the kraft cover settles on the inner page', (
    tester,
  ) async {
    final controller = CoverTurnController();
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: NotebookShell(
          cover: const PaperNotebookCover(year: 2026),
          coverClosed: true,
          controller: controller,
          onCoverOpened: () => opened = true,
          child: const Text('today-page'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('2026'), findsOneWidget);
    expect(opened, isFalse);

    final future = controller.open();
    await tester.pump();
    expect(opened, isFalse);
    expect(find.byKey(NotebookShell.coverInsideKey), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(opened, isFalse);
    expect(find.byKey(NotebookShell.frontCoverKey), findsOneWidget);
    expect(find.byKey(NotebookShell.coverInsideKey), findsOneWidget);
    expect(
      tester.getSize(find.byKey(NotebookShell.coverInsideKey)),
      Size(BookVersoLeaf.stackWidthOf(format), format.pageHeight),
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    await future;
    expect(opened, isTrue);
    expect(find.byKey(NotebookShell.frontCoverKey), findsNothing);
    expect(find.text('today-page'), findsOneWidget);
  });

  testWidgets('opened notebook keeps cover artwork on the left board', (
    tester,
  ) async {
    final controller = CoverTurnController();
    await tester.pumpWidget(
      MaterialApp(
        home: NotebookShell(
          coverBuilder: (_) => PaperNotebookCover(
            year: 2026,
            template: PaperNotebookCoverTemplate.spineStamp,
          ),
          coverClosed: true,
          controller: controller,
          child: const Text('today-page'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(PaperNotebookCover.splitKey), findsOneWidget);
    final closedCover = tester.getRect(find.byKey(NotebookShell.frontCoverKey));
    final closedSplit = tester.getRect(find.byKey(PaperNotebookCover.splitKey));
    expect(closedSplit.center.dx, lessThan(closedCover.center.dx));

    final future = controller.open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    await future;
    expect(find.byKey(NotebookShell.frontCoverKey), findsNothing);
    expect(find.byKey(NotebookShell.landedCoverKey), findsOneWidget);
    expect(find.byKey(PaperNotebookCover.splitKey), findsOneWidget);
    final landed = tester.getRect(find.byKey(NotebookShell.landedCoverKey));
    final openedSplit = tester.getRect(find.byKey(PaperNotebookCover.splitKey));
    expect(openedSplit.center.dx, greaterThan(landed.center.dx));
  });

  testWidgets('closed cover paints a photo background', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaperNotebook(
          coverClosed: true,
          coverGesturesEnabled: false,
          theme: PaperNotebookTheme(
            year: 2026,
            coverBackground: PaperNotebookCoverImage.wheat.image,
            onCover: PaperNotebookCoverImage.wheat.onCover,
          ),
          coverBuilder: (_) => const PaperNotebookCover(year: 2026),
          pageBuilder: (_, _) => const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(NotebookShell.coverBackgroundKey), findsOneWidget);
    expect(find.byKey(NotebookShell.frontCoverKey), findsOneWidget);
  });

  testWidgets('opened notebook keeps the photo on the left board', (
    tester,
  ) async {
    final controller = PaperNotebookController();
    await tester.pumpWidget(
      MaterialApp(
        home: PaperNotebook(
          controller: controller,
          coverClosed: true,
          theme: PaperNotebookTheme(
            year: 2026,
            coverBackground: PaperNotebookCoverImage.moonlight.image,
            onCover: PaperNotebookCoverImage.moonlight.onCover,
          ),
          coverBuilder: (_) => const PaperNotebookCover(year: 2026),
          pageBuilder: (_, _) => const Text('today-page'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(NotebookShell.coverBackgroundKey), findsOneWidget);

    final future = controller.openCover();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    await future;
    expect(find.byKey(NotebookShell.frontCoverKey), findsNothing);
    expect(find.byKey(NotebookShell.landedCoverKey), findsOneWidget);
    expect(find.byKey(NotebookShell.coverBackgroundKey), findsOneWidget);
  });
}
