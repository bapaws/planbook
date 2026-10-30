import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_notebook/paper_notebook.dart';

void main() {
  test('defaults and parses paper patterns', () {
    expect(PaperNotebookPattern.parse(null), PaperNotebookPattern.dots);
    expect(PaperNotebookPattern.parse('grid'), PaperNotebookPattern.grid);
    expect(PaperNotebookPattern.parse('solid'), PaperNotebookPattern.solid);
    expect(PaperNotebookPattern.parse('nope'), PaperNotebookPattern.dots);
    expect(PaperNotebookPattern.solid.hasTile, isFalse);
    expect(PaperNotebookPattern.dots.hasTile, isTrue);
  });

  test('picks light and dark tile assets', () {
    expect(
      PaperNotebookPattern.dots.assetFor(Brightness.light),
      'assets/tiles/bg_dot_light.png',
    );
    expect(
      PaperNotebookPattern.dots.assetFor(Brightness.dark),
      'assets/tiles/bg_dot_dark.png',
    );
    expect(
      PaperNotebookPattern.grid.assetFor(Brightness.light),
      'assets/tiles/bg_grid_light.png',
    );
    expect(
      PaperNotebookPattern.grid.assetFor(Brightness.dark),
      'assets/tiles/bg_grid_dark.png',
    );
    expect(PaperNotebookPattern.solid.imageFor(Brightness.light), isNull);
    expect(
      () => PaperNotebookPattern.solid.assetFor(Brightness.light),
      throwsStateError,
    );
  });

  testWidgets('solid paper has no tile image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 80,
          height: 80,
          child: PaperNotebookSurface(
            pattern: PaperNotebookPattern.solid,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(Image), findsNothing);
  });
}
