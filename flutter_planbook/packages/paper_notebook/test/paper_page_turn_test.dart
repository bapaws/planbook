import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_notebook/paper_notebook.dart';
import 'package:paper_notebook/src/engine/paper_page_turn.dart';
import 'package:paper_notebook/src/engine/turnable_paper_flip.dart';

void main() {
  testWidgets('ritual forward always animates then settles on next', (
    tester,
  ) async {
    final controller = PaperPageTurnController();
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PaperPageTurn(
          controller: controller,
          gesturesEnabled: false,
          current: const ColoredBox(color: Colors.red, child: Text('cover')),
          next: const ColoredBox(color: Colors.blue, child: Text('today')),
          previous: const SizedBox.expand(),
          onForward: () => opened = true,
          onBack: () {},
        ),
      ),
    );
    expect(find.text('cover'), findsOneWidget);
    expect(find.text('today'), findsNothing);

    final future = controller.playRitualForward();
    await tester.pump();
    expect(find.text('cover'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 450));
    expect(opened, isFalse);
    await tester.pump(const Duration(milliseconds: 500));
    await future;
    expect(opened, isTrue);
  });

  testWidgets('inner paper turn settles on next', (tester) async {
    final controller = PaperPageTurnController();
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PaperPageTurn(
          controller: controller,
          gesturesEnabled: false,
          current: const ColoredBox(color: Colors.red, child: Text('page')),
          next: const ColoredBox(color: Colors.blue, child: Text('after')),
          previous: const SizedBox.expand(),
          onForward: () => opened = true,
          onBack: () {},
        ),
      ),
    );
    await tester.pump();
    final future = controller.playRitualForward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(opened, isFalse);
    await tester.pump(const Duration(milliseconds: 500));
    await future;
    expect(opened, isTrue);
  });

  testWidgets('back restores previous over current', (tester) async {
    final controller = PaperPageTurnController();
    var wentBack = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PaperPageTurn(
          controller: controller,
          gesturesEnabled: false,
          current: const ColoredBox(color: Colors.red, child: Text('current')),
          next: const ColoredBox(color: Colors.blue, child: Text('next')),
          previous: const ColoredBox(
            color: Colors.green,
            child: Text('previous'),
          ),
          onForward: () {},
          onBack: () => wentBack = true,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('current'), findsOneWidget);
    expect(find.text('previous'), findsNothing);

    final turn = PaperNotebookStyle.defaults.pageTurn;
    final future = controller.playBack();
    await tester.pump();
    await tester.pump(turn * 0.3);
    expect(find.text('current'), findsOneWidget);
    expect(find.text('previous'), findsOneWidget);
    expect(wentBack, isFalse);
    await tester.pump(turn * 0.6);
    expect(find.text('previous'), findsOneWidget);
    expect(wentBack, isFalse);
    final previousClip = tester.widget<ClipPath>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('previous')),
        matching: find.byType(ClipPath),
      ),
    );
    expect(previousClip.clipper, isNot(isA<EmptyPageClipper>()));
    expect(previousClip.clipper, isA<FullPageClipper>());
    await tester.pump(turn * 0.3);
    await future;
    expect(wentBack, isTrue);
  });

  testWidgets('forward settle keeps destination without old page', (
    tester,
  ) async {
    final controller = PaperPageTurnController();
    var page = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return PaperPageTurn(
              controller: controller,
              gesturesEnabled: false,
              current: ColoredBox(
                color: Colors.red,
                child: Text(page == 0 ? 'A' : 'B'),
              ),
              next: ColoredBox(
                color: Colors.blue,
                child: Text(page == 0 ? 'B' : 'C'),
              ),
              previous: const SizedBox.expand(),
              onForward: () => setState(() => page = 1),
              onBack: () {},
            );
          },
        ),
      ),
    );
    await tester.pump();
    final future = controller.playRitualForward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('A'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 500));
    await future;
    await tester.pump();
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
    expect(find.byKey(const Key('turned-page-back')), findsOneWidget);
  });

  testWidgets('right-edge pan reveals next page while following finger', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: PaperPageTurn(
            current: ColoredBox(color: Colors.red, child: Text('page')),
            next: ColoredBox(color: Colors.blue, child: Text('after')),
            previous: SizedBox.expand(),
            onForward: _noop,
            onBack: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('after'), findsNothing);

    final rect = tester.getRect(find.byType(PaperPageTurn));
    final gesture = await tester.startGesture(
      Offset(rect.right - 24, rect.bottom - 80),
    );
    await gesture.moveBy(const Offset(-160, -110));
    await tester.pump();
    expect(find.text('after'), findsOneWidget);
    expect(find.text('page'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('top-right drag curls from the finger not the bottom corner', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: PaperPageTurn(
            current: ColoredBox(color: Colors.red, child: Text('page')),
            next: ColoredBox(color: Colors.blue, child: Text('after')),
            previous: SizedBox.expand(),
            onForward: _noop,
            onBack: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    final rect = tester.getRect(find.byType(PaperPageTurn));
    final gesture = await tester.startGesture(
      Offset(rect.right - 20, rect.top + 90),
    );
    await gesture.moveBy(const Offset(-150, 40));
    await tester.pump();
    expect(find.text('after'), findsOneWidget);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final overlay = tester.widget<PaperFoldOverlay>(
      find.byKey(const Key('paper-fold-overlay')),
    );
    expect(overlay.fold.isVerticalFold, isFalse);
    expect(
      (overlay.fold.grab.dy - overlay.fold.origin.dy).abs(),
      greaterThan(8),
    );
    expect(
      overlay.tileAsset,
      PaperNotebookPattern.dots.assetFor(Brightness.light),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('open book shows a left paper leaf without left-page content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: PaperPageTurn(
            current: ColoredBox(color: Colors.red, child: Text('recto')),
            next: ColoredBox(color: Colors.blue, child: Text('next')),
            previous: ColoredBox(color: Colors.green, child: Text('verso')),
            onForward: _noop,
            onBack: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('recto'), findsOneWidget);
    expect(find.text('verso'), findsNothing);
    expect(find.text('next'), findsNothing);
    expect(find.byKey(const Key('turned-page-back')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('turned-page-back'))).width,
      closeTo(BookVersoLeaf.stackWidth, 0.5),
    );
  });

  testWidgets('short forward drag snaps back without turning', (tester) async {
    var turned = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: PaperPageTurn(
            current: const ColoredBox(color: Colors.red, child: Text('page')),
            next: const ColoredBox(color: Colors.blue, child: Text('after')),
            previous: const SizedBox.expand(),
            onForward: () => turned = true,
            onBack: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    final rect = tester.getRect(find.byType(PaperPageTurn));
    final gesture = await tester.startGesture(
      Offset(rect.right - 24, rect.bottom - 80),
    );
    await gesture.moveBy(const Offset(-48, 0));
    await tester.pump();
    expect(find.text('after'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(turned, isFalse);
    expect(find.text('page'), findsOneWidget);
    expect(find.text('after'), findsNothing);
  });

  testWidgets('forward drag past the threshold commits to next page', (
    tester,
  ) async {
    var turned = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: PaperPageTurn(
            current: const ColoredBox(color: Colors.red, child: Text('page')),
            next: const ColoredBox(color: Colors.blue, child: Text('after')),
            previous: const SizedBox.expand(),
            onForward: () => turned = true,
            onBack: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    final rect = tester.getRect(find.byType(PaperPageTurn));
    final gesture = await tester.startGesture(
      Offset(rect.right - 24, rect.bottom - 80),
    );
    final step = Offset(-rect.width * 0.105, 0);
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(step);
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
    expect(turned, isFalse);
    await tester.pump(const Duration(milliseconds: 120));
    expect(turned, isFalse);
    await tester.pumpAndSettle();
    expect(turned, isTrue);
  });

  testWidgets('short fast fling commits to next page', (tester) async {
    var turned = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: PaperPageTurn(
            current: const ColoredBox(color: Colors.red, child: Text('page')),
            next: const ColoredBox(color: Colors.blue, child: Text('after')),
            previous: const SizedBox.expand(),
            onForward: () => turned = true,
            onBack: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    final rect = tester.getRect(find.byType(PaperPageTurn));

    await tester.flingFrom(
      Offset(rect.right - 24, rect.bottom - 80),
      const Offset(-70, 0),
      900,
    );
    await tester.pumpAndSettle();

    expect(turned, isTrue);
    expect(find.text('after'), findsOneWidget);
  });

  testWidgets('left-side drag restores previous from the left pile', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: PaperPageTurn(
            current: ColoredBox(color: Colors.red, child: Text('page')),
            next: ColoredBox(color: Colors.blue, child: Text('after')),
            previous: ColoredBox(color: Colors.green, child: Text('before')),
            onForward: _noop,
            onBack: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('before'), findsNothing);

    final rect = tester.getRect(find.byType(PaperPageTurn));
    final gesture = await tester.startGesture(
      Offset(rect.left + 28, rect.bottom - 80),
    );
    await gesture.moveBy(const Offset(170, -20));
    await tester.pump();
    expect(find.text('before'), findsOneWidget);
    expect(find.text('page'), findsOneWidget);
    expect(find.byKey(const Key('turned-page-back')), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('left-side pan start keeps resting left-leaf lighting', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: PaperPageTurn(
            current: ColoredBox(color: Colors.red, child: Text('page')),
            next: ColoredBox(color: Colors.blue, child: Text('after')),
            previous: ColoredBox(color: Colors.green, child: Text('before')),
            onForward: _noop,
            onBack: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    final rect = tester.getRect(find.byType(PaperPageTurn));
    final gesture = await tester.startGesture(
      Offset(rect.left + 28, rect.bottom - 80),
    );
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    final overlay = tester.widget<PaperFoldOverlay>(
      find.byKey(const Key('paper-fold-overlay')),
    );
    expect(overlay.settleToLeft, isFalse);
    expect(overlay.progress, greaterThan(0.9));
    expect(foldRestOnLeft(progress: overlay.progress), greaterThan(0.5));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('left-side drag closes cover instead of restoring paper', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: PaperPageTurn(
            current: const ColoredBox(color: Colors.red, child: Text('year')),
            next: const ColoredBox(color: Colors.blue, child: Text('next')),
            previous: const SizedBox.expand(),
            closesCoverOnBack: true,
            onCloseCover: () => closed = true,
            onForward: _noop,
            onBack: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    final rect = tester.getRect(find.byType(PaperPageTurn));
    await tester.dragFrom(
      Offset(rect.left + 28, rect.bottom - 80),
      const Offset(170, 0),
    );
    await tester.pump();
    expect(closed, isTrue);
    expect(find.text('year'), findsOneWidget);
  });

  testWidgets('right-side drag closes cover instead of turning past last', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: PaperPageTurn(
            current: const ColoredBox(color: Colors.red, child: Text('back')),
            next: const SizedBox.expand(),
            previous: const ColoredBox(
              color: Colors.green,
              child: Text('inner'),
            ),
            closesCoverOnForward: true,
            onCloseCover: () => closed = true,
            onForward: _noop,
            onBack: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    final rect = tester.getRect(find.byType(PaperPageTurn));
    await tester.dragFrom(
      Offset(rect.right - 24, rect.bottom - 80),
      const Offset(-170, 0),
    );
    await tester.pump();
    expect(closed, isTrue);
    expect(find.text('back'), findsOneWidget);
  });
}

void _noop() {}
