import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';
import 'package:flutter_planbook/discover/diary/model/diary_book_document.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:paper_notebook/paper_notebook.dart';

class DiaryBookLeaf extends StatelessWidget {
  const DiaryBookLeaf({
    required this.page,
    required this.number,
    this.entryCount = 1,
    this.paperPattern,
    super.key,
  });

  final DiaryBookPage page;
  final int number;

  /// 同一篇日记占用的纸页数。大于 1 时标出「第几页 / 共几页」。
  final int entryCount;

  /// 书外单独渲染时传入。在本子里则跟着 [PaperNotebookScope]。
  final PaperNotebookPattern? paperPattern;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = _DiaryPalette.forPage(page, dark: dark);
    final date = page.note.createdAt;
    final layout = page.layout;
    final imageRects = page.imageRects;
    final day = date.format(pattern: 'dd');
    final continued = page.part > 0;
    final entryMark = entryCount > 1 ? '${page.part + 1} / $entryCount' : null;
    final heading = continued && page.note.title.isNotEmpty
        ? page.note.title
        : context.l10n.diaryBook;
    final pattern =
        paperPattern ?? PaperNotebookScope.maybeOf(context)?.pattern;
    return FittedBox(
      child: SizedBox.fromSize(
        size: kDiaryPageSize,
        child: _paper(
          palette: palette,
          pattern: pattern,
          child: DefaultTextStyle(
            style: TextStyle(
              color: palette.ink,
              fontFamily: 'Helvetica Neue',
              fontFamilyFallback: const ['Roboto', 'sans-serif'],
              decoration: TextDecoration.none,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: _DiaryPageFurniture(layout, palette),
                    ),
                  ),
                ),
                if (!layout.isQuiet)
                  Positioned(
                    left: 32,
                    top: 30,
                    right: 32,
                    height: 28,
                    child: Row(
                      children: [
                        Container(width: 5, height: 5, color: palette.accent),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _label(
                            heading,
                            palette.accent,
                            spacing: 2,
                          ),
                        ),
                        if (entryMark != null) ...[
                          const SizedBox(width: 12),
                          _label(entryMark, palette.accent),
                        ],
                        const SizedBox(width: 12),
                        _label(date.yMMMd, palette.ink),
                      ],
                    ),
                  ),
                if (layout.isQuiet)
                  Positioned(
                    left: 44,
                    top: 30,
                    right: 44,
                    height: 14,
                    child: Row(
                      children: [
                        Expanded(
                          child: _label(
                            continued && page.note.title.isNotEmpty
                                ? page.note.title
                                : date.yMMMd,
                            palette.accent,
                            size: 9,
                          ),
                        ),
                        if (entryMark != null)
                          _label(entryMark, palette.accent, size: 9),
                      ],
                    ),
                  ),
                if (layout == DiaryPageLayout.editorial)
                  Positioned(
                    left: 28,
                    top: 72,
                    child: ExcludeSemantics(
                      child: Text(
                        day,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 76,
                          height: 1,
                          letterSpacing: -5,
                          color: palette.accent,
                        ),
                      ),
                    ),
                  ),
                if (layout == DiaryPageLayout.essay)
                  Positioned(
                    left: 60,
                    top: 78,
                    child: ExcludeSemantics(
                      child: Text(
                        '“',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 88,
                          height: 1,
                          color: palette.accent,
                        ),
                      ),
                    ),
                  ),
                if (layout == DiaryPageLayout.letter)
                  Positioned(
                    left: 60,
                    top: 92,
                    child: _label(
                      date.format(pattern: 'yyyy / MM / dd'),
                      palette.accent,
                      spacing: 2,
                    ),
                  ),
                for (var i = 0; i < page.images.length; i++)
                  Positioned.fromRect(
                    rect: imageRects[i],
                    child: _photo(i, palette),
                  ),
                if (layout == DiaryPageLayout.sidebar)
                  Positioned(
                    left: 32,
                    top: 454,
                    width: 136,
                    child: _label(
                      date.format(pattern: 'MM / dd'),
                      palette.accent,
                      spacing: 2,
                    ),
                  ),
                if (layout == DiaryPageLayout.postcard ||
                    layout == DiaryPageLayout.framed)
                  Positioned(
                    left: 68,
                    top: layout == DiaryPageLayout.postcard ? 318 : 306,
                    width: 284,
                    child: _label(
                      date.format(pattern: 'yyyy.MM.dd'),
                      palette.accent,
                      spacing: 2,
                    ),
                  ),
                if (layout == DiaryPageLayout.contactSheet)
                  for (var i = 0; i < 3; i++)
                    Positioned(
                      left: imageRects[i].left,
                      top: 274,
                      child: ExcludeSemantics(
                        child: _label('0${i + 1}', palette.accent, size: 9),
                      ),
                    ),
                for (final frame in page.frames)
                  Positioned.fromRect(
                    rect: frame.rect,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: palette.ink),
                        children: [frame.span],
                      ),
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                    ),
                  ),
                Positioned(
                  left: 32,
                  top: 558,
                  right: 32,
                  height: 20,
                  child: layout.isQuiet
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: _label('$number', palette.accent, size: 9),
                        )
                      : Row(
                          children: [
                            _label(
                              date.format(pattern: 'yyyy'),
                              palette.accent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: palette.accent.withValues(alpha: 0.2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _label(
                              number.toString().padLeft(3, '0'),
                              palette.ink,
                              spacing: 2,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 纹路画在这一页自己的底上，并铺满不透明底色，翻页时不会透出下一页。
  Widget _paper({
    required _DiaryPalette palette,
    required PaperNotebookPattern? pattern,
    required Widget child,
  }) {
    if (pattern == null || !pattern.hasTile) {
      return ColoredBox(color: palette.paper, child: child);
    }
    return PaperNotebookSurface(pattern: pattern, child: child);
  }

  Widget _label(
    String value,
    Color color, {
    double spacing = 1,
    double size = 10,
  }) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontSize: size,
        letterSpacing: spacing,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }

  Widget _photo(int index, _DiaryPalette palette) => HeroMode(
    enabled: false,
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(
            url: page.images[index],
            fit: BoxFit.contain,
            // 占位图会按宽高计算字号，必须传实际栏位尺寸，不能使用 infinity。
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          ),
          if (page.layout.hasPhotoIndex)
            Positioned(
              left: 4,
              bottom: 4,
              child: ExcludeSemantics(
                child: ColoredBox(
                  color: palette.paper.withValues(alpha: 0.9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: _label(
                      (index + 1).toString().padLeft(2, '0'),
                      palette.ink,
                      size: 8,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _DiaryPalette {
  const _DiaryPalette({
    required this.paper,
    required this.ink,
    required this.accent,
    required this.tint,
  });

  factory _DiaryPalette.forPage(DiaryBookPage page, {required bool dark}) {
    if (page.layout.isQuiet) {
      return _DiaryPalette(
        paper: dark ? const Color(0xFF252523) : const Color(0xFFFCFBF9),
        ink: dark ? const Color(0xFFEDE7DB) : const Color(0xFF302F2B),
        accent: dark ? const Color(0xFF9C9A94) : const Color(0xFF9A9892),
        tint: Colors.transparent,
      );
    }
    final accent = [
      const Color(0xFFA54F39),
      const Color(0xFF527061),
      const Color(0xFF4A617E),
      const Color(0xFF957444),
    ][(diaryLayoutSeed(page.note.id) ~/ 7) % 4];
    final paper = dark ? const Color(0xFF252521) : const Color(0xFFFFFCF5);
    return _DiaryPalette(
      paper: paper,
      ink: dark ? const Color(0xFFEDE7DB) : const Color(0xFF292C29),
      accent: dark ? Color.lerp(accent, Colors.white, 0.4)! : accent,
      tint: Color.alphaBlend(
        accent.withValues(alpha: dark ? 0.08 : 0.025),
        paper,
      ),
    );
  }

  final Color paper;
  final Color ink;
  final Color accent;
  final Color tint;
}

class _DiaryPageFurniture extends CustomPainter {
  const _DiaryPageFurniture(this.layout, this.palette);

  final DiaryPageLayout layout;
  final _DiaryPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.isQuiet) return;
    final accent = Paint()..color = palette.accent;
    final fine = Paint()
      ..color = palette.accent.withValues(alpha: 0.28)
      ..strokeWidth = 0.6;
    final tint = Paint()..color = palette.tint;
    canvas.drawLine(const Offset(32, 68), const Offset(388, 68), fine);
    switch (layout) {
      case DiaryPageLayout.editorial:
        canvas
          ..drawRect(const Rect.fromLTWH(32, 164, 3, 54), accent)
          ..drawLine(const Offset(132, 134), const Offset(356, 134), fine);
      case DiaryPageLayout.ruled:
        canvas.drawLine(const Offset(36, 96), const Offset(36, 532), fine);
        final rules = Paint()..color = palette.accent.withValues(alpha: 0.09);
        for (var y = 133.2; y <= 532; y += 25.2) {
          canvas.drawLine(Offset(48, y), Offset(372, y), rules);
        }
      case DiaryPageLayout.essay:
        canvas.drawLine(const Offset(66, 116), const Offset(354, 116), fine);
      case DiaryPageLayout.columns:
        canvas
          ..drawRect(const Rect.fromLTWH(32, 84, 30, 3), accent)
          ..drawLine(const Offset(210, 232), const Offset(210, 532), fine)
          ..drawLine(const Offset(32, 220), const Offset(388, 220), fine);
      case DiaryPageLayout.letter:
        canvas
          ..drawRect(const Rect.fromLTWH(44, 78, 332, 458), tint)
          ..drawLine(const Offset(60, 114), const Offset(108, 114), accent);
      case DiaryPageLayout.feature:
        canvas
          ..drawRect(const Rect.fromLTWH(0, 346, 420, 202), tint)
          ..drawRect(const Rect.fromLTWH(40, 354, 34, 3), accent);
      case DiaryPageLayout.postcard:
        const card = Rect.fromLTWH(44, 92, 332, 244);
        canvas
          ..drawShadow(Path()..addRect(card), Colors.black26, 3, false)
          ..drawRect(card, Paint()..color = palette.paper);
      case DiaryPageLayout.framed:
        canvas.drawRect(
          const Rect.fromLTWH(56, 96, 308, 226),
          fine..style = PaintingStyle.stroke,
        );
      case DiaryPageLayout.sidebar:
        canvas
          ..drawRect(const Rect.fromLTWH(24, 92, 152, 352), tint)
          ..drawLine(const Offset(32, 478), const Offset(92, 478), accent);
      case DiaryPageLayout.horizon:
        canvas.drawRect(const Rect.fromLTWH(248, 294, 152, 250), tint);
      case DiaryPageLayout.portfolio:
        canvas
          ..drawLine(const Offset(32, 342), const Offset(388, 342), fine)
          ..drawLine(const Offset(210, 354), const Offset(210, 532), fine);
      case DiaryPageLayout.contactSheet:
        canvas.drawRect(const Rect.fromLTWH(28, 108, 364, 178), tint);
        for (var x = 40.0; x < 380; x += 12) {
          canvas.drawRect(Rect.fromLTWH(x, 112, 5, 3), fine);
        }
      case DiaryPageLayout.mosaic:
        canvas
          ..drawRect(const Rect.fromLTWH(220, 88, 180, 272), tint)
          ..drawLine(const Offset(32, 360), const Offset(388, 360), fine);
      case DiaryPageLayout.hero:
      case DiaryPageLayout.diptych:
      case DiaryPageLayout.gallery:
      case DiaryPageLayout.fourStory:
      case DiaryPageLayout.fiveFeature:
      case DiaryPageLayout.sevenFeature:
      case DiaryPageLayout.nineFeature:
      case DiaryPageLayout.sixGrid:
        canvas.drawRect(
          Rect.fromLTWH(32, layout.textRects.first.top - 12, 28, 2),
          accent,
        );
      case DiaryPageLayout.quartet:
        canvas.drawRect(const Rect.fromLTWH(24, 80, 372, 320), tint);
      case DiaryPageLayout.fiveEssay:
        canvas
          ..drawRect(const Rect.fromLTWH(32, 84, 24, 3), accent)
          ..drawLine(const Offset(32, 304), const Offset(388, 304), fine);
      case DiaryPageLayout.sixFilm:
      case DiaryPageLayout.eightGrid:
      case DiaryPageLayout.nineGrid:
        canvas.drawRect(
          const Rect.fromLTWH(32, 88, 356, 312),
          fine..style = PaintingStyle.stroke,
        );
      case DiaryPageLayout.sevenMosaic:
        canvas.drawRect(const Rect.fromLTWH(24, 80, 188, 328), tint);
      case DiaryPageLayout.eightStory:
        canvas.drawLine(const Offset(32, 212), const Offset(388, 212), fine);
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(_DiaryPageFurniture oldDelegate) =>
      layout != oldDelegate.layout || palette != oldDelegate.palette;
}
