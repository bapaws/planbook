import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_notebook/paper_notebook.dart';

void main() {
  test('defaults and parses cover texture and template', () {
    expect(
      PaperNotebookCoverTexture.parse(null),
      PaperNotebookCoverTexture.leather,
    );
    expect(
      PaperNotebookCoverTexture.parse('none'),
      PaperNotebookCoverTexture.none,
    );
    expect(
      PaperNotebookCoverTexture.parse('cloth'),
      PaperNotebookCoverTexture.cloth,
    );
    expect(
      PaperNotebookCoverTexture.parse('nope'),
      PaperNotebookCoverTexture.leather,
    );
    expect(
      PaperNotebookCoverTemplate.parse(null),
      PaperNotebookCoverTemplate.classic,
    );
    expect(
      PaperNotebookCoverTemplate.parse('yearOnly'),
      PaperNotebookCoverTemplate.yearOnly,
    );
    expect(
      PaperNotebookCoverTemplate.parse('frame'),
      PaperNotebookCoverTemplate.frame,
    );
    expect(
      PaperNotebookCoverTemplate.parse('nope'),
      PaperNotebookCoverTemplate.classic,
    );
    expect(PaperNotebookCoverTemplate.classic.recommendedColors, isNotEmpty);
    final defaults = {
      for (final template in PaperNotebookCoverTemplate.values)
        template.defaultColor.toARGB32(),
    };
    // 不同封面允许共享默认色；每种版式的默认色必须来自其色板。
    expect(defaults, isNotEmpty);
    for (final template in PaperNotebookCoverTemplate.values) {
      expect(template.recommendedColors, contains(template.defaultColor));
    }
    expect(
      PaperNotebookCoverTemplate.classic.recommendedColors.first,
      isNot(PaperNotebookCoverTemplate.yearOnly.recommendedColors.first),
    );
    expect(
      PaperNotebookCoverColors.onCover(PaperNotebookCoverColors.navy),
      Colors.white,
    );
    expect(
      PaperNotebookCoverColors.onCover(PaperNotebookCoverColors.ivory),
      PaperNotebookCoverColors.ink,
    );
    expect(
      PaperNotebookCoverColors.onCover(PaperNotebookCoverColors.sage),
      Colors.white,
    );
    expect(PaperNotebookCoverImage.parse(null), PaperNotebookCoverImage.none);
    expect(PaperNotebookCoverImage.parse(''), PaperNotebookCoverImage.none);
    expect(
      PaperNotebookCoverImage.parse('wheat'),
      PaperNotebookCoverImage.wheat,
    );
    expect(
      PaperNotebookCoverImage.parse('file:covers/x.jpg'),
      PaperNotebookCoverImage.none,
    );
    expect(PaperNotebookCoverImage.wheat.hasAsset, isTrue);
    expect(PaperNotebookCoverImage.none.image, isNull);
    expect(PaperNotebookCoverImage.bundled, hasLength(4));
    expect(
      PaperNotebookCoverImage.bundled,
      isNot(contains(PaperNotebookCoverImage.none)),
    );
    expect(PaperNotebookCoverImage.parse('farmhouse').id, 'farmhouse');
    expect(PaperNotebookCoverImage.parse('farmhouse').hasAsset, isFalse);
    expect(
      PaperNotebookCoverImage.parse('farmhouse').image,
      isA<NetworkImage>(),
    );
    expect(PaperNotebookCoverImage.none.resized(width: 28, height: 40), isNull);
    expect(
      PaperNotebookCoverImage.wheat.resized(width: 84, height: 120),
      isA<ResizeImage>(),
    );
    for (final image in PaperNotebookCoverImage.bundled) {
      expect(image.onCover, Colors.white);
    }
  });

  test('catalog lists every remote cover', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final covers = await PaperNotebookCoverCatalog.load();
    expect(covers, hasLength(36));
    expect(covers.first.image, PaperNotebookCoverImage.wheat);
    expect(covers.first.image.hasAsset, isTrue);
    final farmhouse = covers.firstWhere(
      (cover) => cover.image.id == 'farmhouse',
    );
    expect(farmhouse.image.hasAsset, isFalse);
    expect(farmhouse.image.resized(width: 28, height: 40), isA<NetworkImage>());
    expect(farmhouse.labelFor(const Locale('zh')), farmhouse.zh);
    expect(farmhouse.labelFor(const Locale('en')), farmhouse.en);
  });

  test('each template offers visually distinct swatches', () {
    const minSwatch = 38 * 38;
    final templates = PaperNotebookCoverTemplate.values;
    for (final template in templates) {
      final colors = template.recommendedColors;
      for (var i = 0; i < colors.length; i++) {
        for (var j = i + 1; j < colors.length; j++) {
          expect(
            _rgbDistanceSq(colors[i], colors[j]),
            greaterThan(minSwatch),
            reason: '${template.name} swatch $i vs $j',
          );
        }
      }
    }
  });

  Future<void> pumpCover(
    WidgetTester tester, {
    required PaperNotebookCoverTemplate template,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 480,
          child: PaperNotebookCover(
            year: 2026,
            title: 'Journal',
            template: template,
          ),
        ),
      ),
    );
  }

  testWidgets('classic cover shows title year and ribbon', (tester) async {
    await pumpCover(tester, template: PaperNotebookCoverTemplate.classic);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('JOURNAL'), findsOneWidget);
    expect(find.byKey(PaperNotebookCover.ribbonKey), findsOneWidget);
  });

  testWidgets('yearOnly cover is a badge without title', (tester) async {
    await pumpCover(tester, template: PaperNotebookCoverTemplate.yearOnly);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('JOURNAL'), findsNothing);
    expect(find.byKey(PaperNotebookCover.badgeKey), findsOneWidget);
    expect(find.byKey(PaperNotebookCover.ribbonKey), findsNothing);
  });

  testWidgets('spineStamp cover is a two-tone split', (tester) async {
    await pumpCover(tester, template: PaperNotebookCoverTemplate.spineStamp);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('JOURNAL'), findsOneWidget);
    expect(find.byKey(PaperNotebookCover.splitKey), findsOneWidget);
    expect(find.byKey(PaperNotebookCover.ribbonKey), findsNothing);
  });

  testWidgets('titlePlate cover shows a name sticker', (tester) async {
    await pumpCover(tester, template: PaperNotebookCoverTemplate.titlePlate);
    expect(find.text('JOURNAL'), findsOneWidget);
    expect(find.byKey(PaperNotebookCover.plateKey), findsOneWidget);
    expect(find.byKey(PaperNotebookCover.ribbonKey), findsNothing);
  });

  testWidgets('frame cover shows a polaroid', (tester) async {
    await pumpCover(tester, template: PaperNotebookCoverTemplate.frame);
    expect(find.text('2026'), findsOneWidget);
    expect(find.byKey(PaperNotebookCover.polaroidKey), findsOneWidget);
  });

  testWidgets('bellyBand cover shows a wide band', (tester) async {
    await pumpCover(tester, template: PaperNotebookCoverTemplate.bellyBand);
    expect(find.text('2026'), findsOneWidget);
    expect(find.byKey(PaperNotebookCover.bandKey), findsOneWidget);
  });

  testWidgets('stabBound cover shows stitching', (tester) async {
    await pumpCover(tester, template: PaperNotebookCoverTemplate.stabBound);
    expect(find.text('2026'), findsOneWidget);
    expect(find.byKey(PaperNotebookCover.stitchKey), findsOneWidget);
  });

  testWidgets('theme leather color change rebuilds the cover shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PaperNotebook(
          coverClosed: true,
          theme: PaperNotebookTheme(
            year: 2026,
            light: PaperNotebookPalette(
              desk: Colors.white,
              leather: Color(0xFF8B9BA8),
              leatherEdge: Color(0xFF9AADB4),
              pageEdge: Color(0xFFEFE6D6),
            ),
            texture: PaperNotebookCoverTexture.cloth,
          ),
          pageBuilder: _emptyPage,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('2026'), findsOneWidget);
    expect(find.byKey(PaperNotebook.frontCoverKey), findsOneWidget);
  });

  testWidgets('each cover texture paints a closed notebook', (tester) async {
    for (final texture in PaperNotebookCoverTexture.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: PaperNotebook(
            coverClosed: true,
            theme: PaperNotebookTheme(
              year: 2026,
              texture: texture,
              light: const PaperNotebookPalette(
                desk: Colors.white,
                leather: Color(0xFFA3B194),
                leatherEdge: Color(0xFF9AAF97),
                pageEdge: Color(0xFFEFE6D6),
              ),
            ),
            pageBuilder: _emptyPage,
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(PaperNotebook.frontCoverKey), findsOneWidget);
    }
  });
}

Widget _emptyPage(BuildContext context, int index) => const SizedBox.expand();

int _rgbDistanceSq(Color a, Color b) {
  int channel(Color color, int shift) => (color.toARGB32() >> shift) & 0xFF;
  final dr = channel(a, 16) - channel(b, 16);
  final dg = channel(a, 8) - channel(b, 8);
  final db = channel(a, 0) - channel(b, 0);
  return dr * dr + dg * dg + db * db;
}
