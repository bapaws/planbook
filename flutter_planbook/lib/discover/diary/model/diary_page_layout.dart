import 'package:flutter/material.dart';

/// 纸张中的图文网格同时用于分页和绘制，避免装饰改变正文的实际可用空间。
enum DiaryPageLayout {
  editorial,
  ruled,
  essay,
  columns,
  letter,
  hero,
  sidebar,
  feature,
  postcard,
  framed,
  diptych,
  horizon,
  portfolio,
  gallery,
  mosaic,
  contactSheet,
  quartet,
  fourStory,
  fiveFeature,
  fiveEssay,
  sixGrid,
  sixFilm,
  sevenFeature,
  sevenMosaic,
  eightGrid,
  eightStory,
  nineGrid,
  nineFeature,
  quietNoteLeft(isQuiet: true),
  quietNoteRight(isQuiet: true),
  quietNoteCenter(isQuiet: true),
  quietBottomLeft(isQuiet: true),
  quietBottomRight(isQuiet: true),
  quietFloatingPhoto(isQuiet: true),
  quietTopRight(isQuiet: true),
  quietRightNote(isQuiet: true),
  quietPhotoTop(isQuiet: true),
  quietBookends(isQuiet: true),
  quietPairBottom(isQuiet: true),
  quietPairCenter(isQuiet: true),
  quietCrossPair(isQuiet: true),
  quietTriptychBottom(isQuiet: true),
  quietOrbit(isQuiet: true),
  quietSideTriptych(isQuiet: true),
  quietQuartetAround(isQuiet: true),
  quietQuartetBelow(isQuiet: true),
  quietFiveWindow(isQuiet: true),
  quietFiveBelow(isQuiet: true),
  quietSixWindow(isQuiet: true),
  quietSixBelow(isQuiet: true),
  quietSevenWindow(isQuiet: true),
  quietSevenBelow(isQuiet: true),
  quietEightWindow(isQuiet: true),
  quietEightBelow(isQuiet: true),
  quietNineBelow(isQuiet: true),
  quietNineSplit(isQuiet: true),
  proseColumns(isQuiet: true, isLongForm: true),
  proseStaggered(isQuiet: true, isLongForm: true),
  proseIntermission(isQuiet: true, isLongForm: true),
  proseNarrow(isQuiet: true, isLongForm: true),
  proseInterlude(isQuiet: true, isLongForm: true),
  proseColumnPhoto(isQuiet: true, isLongForm: true),
  proseShoulder(isQuiet: true, isLongForm: true),
  proseMargin(isQuiet: true, isLongForm: true),
  proseAlternating(isQuiet: true, isLongForm: true),
  proseTwinColumns(isQuiet: true, isLongForm: true),
  proseRibbon(isQuiet: true, isLongForm: true),
  proseBookends(isQuiet: true, isLongForm: true),
  proseThreeIslands(isQuiet: true, isLongForm: true),
  prosePhotoEssay(isQuiet: true, isLongForm: true),
  proseTriptych(isQuiet: true, isLongForm: true),
  proseGalleryColumns(isQuiet: true, isLongForm: true);

  const DiaryPageLayout({this.isQuiet = false, this.isLongForm = false});

  final bool isQuiet;
  final bool isLongForm;

  /// 构图分组用于近似适配时轮换，避免实际总是选到同一种图文关系。
  String get composition => switch (this) {
    proseColumns ||
    proseColumnPhoto ||
    proseTwinColumns ||
    proseGalleryColumns => 'prose-columns',
    proseStaggered ||
    proseMargin ||
    proseAlternating ||
    proseThreeIslands => 'prose-staggered',
    proseIntermission ||
    proseInterlude ||
    proseRibbon ||
    proseTriptych => 'prose-interleaved',
    proseNarrow || prosePhotoEssay => 'prose-margin',
    proseShoulder || proseBookends => 'prose-wrap',
    quietNoteLeft || quietNoteRight || quietNoteCenter => 'quiet-note',
    quietBottomLeft || quietBottomRight || quietFloatingPhoto => 'lower-photo',
    quietTopRight || quietRightNote || quietPhotoTop => 'diagonal-photo',
    quietPairBottom ||
    quietTriptychBottom ||
    quietQuartetBelow ||
    quietFiveBelow ||
    quietSixBelow ||
    quietSevenBelow ||
    quietEightBelow ||
    quietNineBelow => 'lower-gallery',
    quietBookends ||
    quietPairCenter ||
    quietCrossPair ||
    quietSideTriptych => 'diagonal-gallery',
    quietOrbit ||
    quietQuartetAround ||
    quietFiveWindow ||
    quietSixWindow ||
    quietSevenWindow ||
    quietEightWindow => 'surround-note',
    quietNineSplit => 'split-gallery',
    sidebar || mosaic || fiveEssay => 'side-photo',
    horizon || eightStory => 'lower-gallery',
    _ => imagesBeforeText ? 'upper-gallery' : 'article',
  };

  bool get imagesBeforeText =>
      imageRects.isNotEmpty && imageRects.first.top < textRects.first.top;

  Alignment imageAlignment(int index) => switch (this) {
    quietBottomLeft => Alignment.bottomLeft,
    quietBottomRight => Alignment.bottomRight,
    quietTopRight => Alignment.topRight,
    quietPhotoTop => Alignment.topCenter,
    _ => Alignment.center,
  };

  static DiaryPageLayout select(int seed, int imageCount) {
    final candidates = candidatesForImageCount(imageCount);
    return candidates[seed % candidates.length];
  }

  static List<DiaryPageLayout> candidatesForImageCount(int imageCount) {
    return switch (imageCount) {
      0 => [
        editorial,
        ruled,
        essay,
        columns,
        letter,
        quietNoteLeft,
        quietNoteRight,
        quietNoteCenter,
        proseColumns,
        proseStaggered,
        proseIntermission,
        proseNarrow,
      ],
      1 => [
        hero,
        sidebar,
        feature,
        postcard,
        framed,
        quietBottomLeft,
        quietBottomRight,
        quietFloatingPhoto,
        quietTopRight,
        quietRightNote,
        quietPhotoTop,
        proseInterlude,
        proseColumnPhoto,
        proseShoulder,
        proseMargin,
      ],
      2 => [
        diptych,
        horizon,
        portfolio,
        quietBookends,
        quietPairBottom,
        quietPairCenter,
        quietCrossPair,
        proseAlternating,
        proseTwinColumns,
        proseRibbon,
        proseBookends,
      ],
      3 => [
        gallery,
        mosaic,
        contactSheet,
        quietTriptychBottom,
        quietOrbit,
        quietSideTriptych,
        proseThreeIslands,
        prosePhotoEssay,
        proseTriptych,
        proseGalleryColumns,
      ],
      4 => [quartet, fourStory, quietQuartetAround, quietQuartetBelow],
      5 => [fiveFeature, fiveEssay, quietFiveWindow, quietFiveBelow],
      6 => [sixGrid, sixFilm, quietSixWindow, quietSixBelow],
      7 => [sevenFeature, sevenMosaic, quietSevenWindow, quietSevenBelow],
      8 => [eightGrid, eightStory, quietEightWindow, quietEightBelow],
      _ => [nineGrid, nineFeature, quietNineBelow, quietNineSplit],
    };
  }

  bool get hasPhotoIndex => switch (this) {
    sixFilm || eightGrid || nineGrid => true,
    _ => false,
  };

  bool get serif => switch (this) {
    essay || letter || postcard || framed || editorial => true,
    _ => false,
  };

  TextStyle get bodyStyle => TextStyle(
    fontSize: isLongForm || this == columns || this == portfolio ? 13.5 : 14,
    height: 1.8,
    letterSpacing: serif ? 0.3 : 0,
    fontFamily: serif ? 'Georgia' : 'Helvetica Neue',
    fontFamilyFallback: serif
        ? const ['Songti SC', 'Noto Serif CJK SC', 'serif']
        : const ['Roboto', 'Noto Sans CJK SC', 'sans-serif'],
  );

  TextStyle get titleStyle => TextStyle(
    fontSize: isQuiet
        ? isLongForm
              ? 18
              : 16
        : switch (this) {
            feature || editorial => 30,
            essay || letter => 28,
            sidebar => 24,
            portfolio || mosaic => 22,
            fiveEssay => 20,
            _ => 26,
          },
    height: 1.25,
    fontWeight: isQuiet || serif ? FontWeight.w500 : FontWeight.w600,
    letterSpacing: isQuiet
        ? 0
        : serif
        ? 0.5
        : -0.8,
  );

  List<Rect> get textRects => isQuiet
      ? _textRects
      : [
          for (final rect in _textRects)
            Rect.fromLTRB(
              rect.left + 8,
              rect.top,
              rect.right - 8,
              rect.bottom - 8,
            ),
        ];

  List<Rect> get _textRects => switch (this) {
    editorial => const [Rect.fromLTWH(64, 164, 292, 368)],
    ruled => const [Rect.fromLTWH(48, 108, 324, 422)],
    essay => const [Rect.fromLTWH(66, 142, 288, 382)],
    columns => const [
      Rect.fromLTWH(32, 100, 356, 112),
      Rect.fromLTWH(32, 232, 168, 300),
      Rect.fromLTWH(220, 232, 168, 300),
    ],
    letter => const [Rect.fromLTWH(60, 128, 300, 388)],
    hero => const [Rect.fromLTWH(32, 320, 356, 212)],
    sidebar => const [Rect.fromLTWH(192, 100, 196, 432)],
    feature => const [Rect.fromLTWH(40, 370, 340, 162)],
    postcard => const [Rect.fromLTWH(48, 354, 324, 178)],
    framed => const [Rect.fromLTWH(56, 332, 308, 192)],
    diptych => const [Rect.fromLTWH(32, 322, 356, 210)],
    horizon => const [Rect.fromLTWH(32, 100, 356, 180)],
    portfolio => const [
      Rect.fromLTWH(32, 354, 168, 178),
      Rect.fromLTWH(220, 354, 168, 178),
    ],
    gallery => const [Rect.fromLTWH(32, 338, 356, 194)],
    mosaic => const [Rect.fromLTWH(32, 100, 176, 248)],
    contactSheet => const [Rect.fromLTWH(40, 300, 340, 224)],
    quartet || fourStory => const [Rect.fromLTWH(32, 416, 356, 116)],
    fiveFeature => const [Rect.fromLTWH(32, 408, 356, 124)],
    fiveEssay => const [Rect.fromLTWH(32, 100, 156, 192)],
    sixGrid => const [Rect.fromLTWH(32, 400, 356, 132)],
    sixFilm => const [Rect.fromLTWH(32, 412, 356, 120)],
    sevenFeature => const [Rect.fromLTWH(32, 402, 356, 130)],
    sevenMosaic || eightGrid || nineGrid || nineFeature => const [
      Rect.fromLTWH(32, 424, 356, 108),
    ],
    eightStory => const [Rect.fromLTWH(32, 88, 356, 112)],
    quietNoteLeft => const [Rect.fromLTWH(52, 92, 236, 240)],
    quietNoteRight => const [Rect.fromLTWH(172, 92, 196, 272)],
    quietNoteCenter => const [Rect.fromLTWH(90, 232, 240, 276)],
    quietBottomLeft => const [Rect.fromLTWH(184, 76, 150, 148)],
    quietBottomRight => const [Rect.fromLTWH(44, 80, 304, 136)],
    quietFloatingPhoto => const [Rect.fromLTWH(80, 88, 260, 120)],
    quietTopRight => const [Rect.fromLTWH(44, 400, 224, 132)],
    quietRightNote => const [Rect.fromLTWH(264, 370, 112, 146)],
    quietPhotoTop => const [Rect.fromLTWH(188, 428, 188, 104)],
    quietBookends => const [Rect.fromLTWH(64, 292, 148, 144)],
    quietPairBottom => const [Rect.fromLTWH(44, 80, 304, 128)],
    quietPairCenter => const [Rect.fromLTWH(44, 430, 300, 100)],
    quietCrossPair => const [Rect.fromLTWH(44, 102, 132, 172)],
    quietTriptychBottom => const [Rect.fromLTWH(44, 82, 300, 132)],
    quietOrbit => const [Rect.fromLTWH(144, 272, 160, 110)],
    quietSideTriptych => const [Rect.fromLTWH(44, 88, 164, 196)],
    quietQuartetAround => const [Rect.fromLTWH(148, 268, 124, 116)],
    quietQuartetBelow => const [Rect.fromLTWH(44, 80, 272, 124)],
    quietFiveWindow => const [Rect.fromLTWH(40, 244, 158, 132)],
    quietFiveBelow ||
    quietSixBelow ||
    quietSevenBelow ||
    quietEightBelow => const [Rect.fromLTWH(44, 88, 296, 124)],
    quietSixWindow => const [Rect.fromLTWH(158, 100, 104, 252)],
    quietSevenWindow => const [Rect.fromLTWH(158, 100, 104, 264)],
    quietEightWindow => const [Rect.fromLTWH(158, 244, 104, 132)],
    quietNineBelow => const [Rect.fromLTWH(44, 88, 300, 104)],
    quietNineSplit => const [Rect.fromLTWH(44, 272, 300, 88)],
    // 文字栏按阅读顺序声明：同栏从上到下，再进入右栏；横向分区先上后下。
    proseColumns => const [
      Rect.fromLTWH(44, 88, 148, 444),
      Rect.fromLTWH(228, 88, 148, 444),
    ],
    proseStaggered => const [
      Rect.fromLTWH(44, 88, 148, 324),
      Rect.fromLTWH(228, 196, 148, 336),
    ],
    proseIntermission => const [
      Rect.fromLTWH(60, 88, 300, 168),
      Rect.fromLTWH(60, 314, 300, 218),
    ],
    proseNarrow => const [Rect.fromLTWH(84, 104, 252, 396)],
    proseInterlude => const [
      Rect.fromLTWH(44, 88, 332, 144),
      Rect.fromLTWH(44, 420, 332, 112),
    ],
    proseColumnPhoto => const [
      Rect.fromLTWH(44, 88, 148, 444),
      Rect.fromLTWH(228, 304, 148, 228),
    ],
    proseShoulder => const [
      Rect.fromLTWH(44, 88, 332, 112),
      Rect.fromLTWH(44, 228, 148, 168),
      Rect.fromLTWH(44, 424, 332, 108),
    ],
    proseMargin => const [
      Rect.fromLTWH(44, 88, 332, 138),
      Rect.fromLTWH(204, 254, 172, 278),
    ],
    proseAlternating => const [
      Rect.fromLTWH(44, 88, 176, 224),
      Rect.fromLTWH(200, 340, 176, 192),
    ],
    proseTwinColumns => const [
      Rect.fromLTWH(44, 88, 148, 164),
      Rect.fromLTWH(44, 404, 148, 128),
      Rect.fromLTWH(228, 236, 148, 296),
    ],
    proseRibbon => const [
      Rect.fromLTWH(44, 88, 332, 112),
      Rect.fromLTWH(44, 396, 148, 136),
      Rect.fromLTWH(228, 396, 148, 136),
    ],
    proseBookends => const [
      Rect.fromLTWH(228, 88, 148, 132),
      Rect.fromLTWH(44, 248, 332, 124),
      Rect.fromLTWH(44, 400, 148, 132),
    ],
    proseThreeIslands => const [
      Rect.fromLTWH(44, 88, 192, 152),
      Rect.fromLTWH(184, 268, 192, 152),
      Rect.fromLTWH(44, 448, 192, 84),
    ],
    prosePhotoEssay => const [Rect.fromLTWH(192, 88, 184, 444)],
    proseTriptych => const [
      Rect.fromLTWH(44, 88, 148, 150),
      Rect.fromLTWH(228, 88, 148, 150),
      Rect.fromLTWH(44, 422, 332, 110),
    ],
    proseGalleryColumns => const [
      Rect.fromLTWH(44, 216, 148, 188),
      Rect.fromLTWH(228, 88, 148, 136),
      Rect.fromLTWH(228, 396, 148, 136),
    ],
  };

  List<Rect> get imageRects => isQuiet
      ? _imageRects
      : [
          for (final rect in _imageRects)
            Rect.fromLTRB(
              rect.left == 0 ? 32 : rect.left + 8,
              rect.top + 8,
              rect.right == 420 ? 388 : rect.right - 8,
              rect.bottom - 8,
            ),
        ];

  List<Rect> get _imageRects => switch (this) {
    hero => const [Rect.fromLTWH(32, 88, 356, 208)],
    sidebar => const [Rect.fromLTWH(32, 100, 136, 336)],
    feature => const [Rect.fromLTWH(0, 76, 420, 270)],
    postcard => const [Rect.fromLTWH(56, 104, 308, 204)],
    framed => const [Rect.fromLTWH(68, 108, 284, 188)],
    diptych => const [
      Rect.fromLTWH(32, 88, 172, 206),
      Rect.fromLTWH(216, 116, 172, 178),
    ],
    horizon => const [
      Rect.fromLTWH(32, 306, 216, 226),
      Rect.fromLTWH(260, 366, 128, 166),
    ],
    portfolio => const [
      Rect.fromLTWH(32, 88, 356, 144),
      Rect.fromLTWH(170, 246, 218, 84),
    ],
    gallery => const [
      Rect.fromLTWH(32, 88, 216, 226),
      Rect.fromLTWH(260, 88, 128, 107),
      Rect.fromLTWH(260, 207, 128, 107),
    ],
    mosaic => const [
      Rect.fromLTWH(232, 100, 156, 248),
      Rect.fromLTWH(32, 372, 172, 160),
      Rect.fromLTWH(216, 372, 172, 160),
    ],
    contactSheet => const [
      Rect.fromLTWH(40, 122, 106, 146),
      Rect.fromLTWH(157, 122, 106, 146),
      Rect.fromLTWH(274, 122, 106, 146),
    ],
    quartet => _grid(2, 2, const Rect.fromLTWH(32, 88, 356, 304)),
    fourStory => [
      const Rect.fromLTWH(32, 88, 356, 200),
      ..._grid(3, 1, const Rect.fromLTWH(32, 300, 356, 92)),
    ],
    fiveFeature => [
      const Rect.fromLTWH(32, 88, 356, 184),
      ..._grid(4, 1, const Rect.fromLTWH(32, 284, 356, 100)),
    ],
    fiveEssay => [
      const Rect.fromLTWH(212, 88, 176, 204),
      ..._grid(2, 2, const Rect.fromLTWH(32, 316, 356, 216)),
    ],
    sixGrid => _grid(3, 2, const Rect.fromLTWH(32, 88, 356, 288)),
    sixFilm => _grid(2, 3, const Rect.fromLTWH(32, 88, 356, 300)),
    sevenFeature => [
      const Rect.fromLTWH(32, 88, 356, 150),
      ..._grid(3, 2, const Rect.fromLTWH(32, 250, 356, 128)),
    ],
    sevenMosaic => [
      const Rect.fromLTWH(32, 88, 172, 312),
      ..._grid(2, 3, const Rect.fromLTWH(216, 88, 172, 312)),
    ],
    eightGrid => _grid(4, 2, const Rect.fromLTWH(32, 88, 356, 312)),
    eightStory => [
      ..._grid(2, 1, const Rect.fromLTWH(32, 224, 356, 148)),
      ..._grid(3, 2, const Rect.fromLTWH(32, 384, 356, 148)),
    ],
    nineGrid => _grid(3, 3, const Rect.fromLTWH(32, 88, 356, 312)),
    nineFeature => [
      const Rect.fromLTWH(32, 88, 356, 144),
      ..._grid(4, 2, const Rect.fromLTWH(32, 244, 356, 156)),
    ],
    quietBottomLeft => const [Rect.fromLTWH(40, 288, 244, 244)],
    quietBottomRight => const [Rect.fromLTWH(100, 316, 280, 216)],
    quietFloatingPhoto => const [Rect.fromLTWH(92, 278, 236, 224)],
    quietTopRight => const [Rect.fromLTWH(196, 92, 184, 220)],
    quietRightNote => const [Rect.fromLTWH(40, 120, 192, 300)],
    quietPhotoTop => const [Rect.fromLTWH(72, 88, 276, 260)],
    quietBookends => const [
      Rect.fromLTWH(40, 100, 176, 172),
      Rect.fromLTWH(228, 390, 152, 142),
    ],
    quietPairBottom => const [
      Rect.fromLTWH(40, 306, 184, 216),
      Rect.fromLTWH(252, 380, 128, 142),
    ],
    quietPairCenter => const [
      Rect.fromLTWH(40, 160, 156, 208),
      Rect.fromLTWH(224, 232, 156, 136),
    ],
    quietCrossPair => const [
      Rect.fromLTWH(212, 132, 168, 180),
      Rect.fromLTWH(72, 356, 204, 176),
    ],
    quietTriptychBottom => const [
      Rect.fromLTWH(40, 324, 108, 156),
      Rect.fromLTWH(170, 380, 100, 104),
      Rect.fromLTWH(292, 300, 88, 212),
    ],
    quietOrbit => const [
      Rect.fromLTWH(40, 100, 132, 140),
      Rect.fromLTWH(248, 100, 132, 140),
      Rect.fromLTWH(120, 410, 180, 122),
    ],
    quietSideTriptych => const [
      Rect.fromLTWH(244, 124, 136, 152),
      Rect.fromLTWH(40, 330, 148, 202),
      Rect.fromLTWH(224, 412, 156, 120),
    ],
    quietQuartetAround => const [
      Rect.fromLTWH(40, 92, 140, 144),
      Rect.fromLTWH(244, 120, 136, 128),
      Rect.fromLTWH(40, 390, 136, 142),
      Rect.fromLTWH(248, 408, 132, 124),
    ],
    quietQuartetBelow => const [
      Rect.fromLTWH(40, 266, 148, 150),
      Rect.fromLTWH(216, 244, 164, 128),
      Rect.fromLTWH(76, 442, 112, 90),
      Rect.fromLTWH(240, 408, 140, 124),
    ],
    quietFiveWindow => const [
      Rect.fromLTWH(40, 88, 158, 132),
      Rect.fromLTWH(222, 88, 158, 132),
      Rect.fromLTWH(222, 244, 158, 132),
      Rect.fromLTWH(40, 400, 158, 132),
      Rect.fromLTWH(222, 400, 158, 132),
    ],
    quietFiveBelow => [
      const Rect.fromLTWH(40, 276, 156, 256),
      ..._grid(2, 2, const Rect.fromLTWH(220, 276, 160, 256), gap: 24),
    ],
    quietSixWindow => [
      for (var row = 0; row < 3; row++) ...[
        Rect.fromLTWH(40, 100 + row * 152, 100, 128),
        Rect.fromLTWH(280, 100 + row * 152, 100, 128),
      ],
    ],
    quietSixBelow => _grid(
      2,
      3,
      const Rect.fromLTWH(40, 270, 340, 262),
      gap: 24,
    ),
    quietSevenWindow => [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          if (!(col == 1 && row < 2))
            Rect.fromLTWH(40 + col * 124, 88 + row * 156, 92, 132),
    ],
    quietSevenBelow => [
      const Rect.fromLTWH(40, 270, 340, 116),
      ..._grid(3, 2, const Rect.fromLTWH(40, 410, 340, 122), gap: 20),
    ],
    quietEightWindow => [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          if (!(col == 1 && row == 1))
            Rect.fromLTWH(40 + col * 124, 88 + row * 156, 92, 132),
    ],
    quietEightBelow => _grid(
      2,
      4,
      const Rect.fromLTWH(40, 270, 340, 262),
      gap: 20,
    ),
    quietNineBelow => _grid(
      3,
      3,
      const Rect.fromLTWH(40, 258, 340, 274),
      gap: 20,
    ),
    quietNineSplit => [
      ..._grid(3, 1, const Rect.fromLTWH(40, 88, 340, 144), gap: 24),
      ..._grid(3, 2, const Rect.fromLTWH(40, 388, 340, 144), gap: 20),
    ],
    proseInterlude => const [Rect.fromLTWH(84, 260, 252, 132)],
    proseColumnPhoto => const [Rect.fromLTWH(228, 88, 148, 188)],
    proseShoulder => const [Rect.fromLTWH(228, 228, 148, 168)],
    proseMargin => const [Rect.fromLTWH(44, 254, 132, 212)],
    proseAlternating => const [
      Rect.fromLTWH(248, 88, 128, 168),
      Rect.fromLTWH(44, 364, 128, 168),
    ],
    proseTwinColumns => const [
      Rect.fromLTWH(44, 280, 148, 96),
      Rect.fromLTWH(228, 88, 148, 120),
    ],
    proseRibbon => const [
      Rect.fromLTWH(44, 228, 148, 140),
      Rect.fromLTWH(228, 228, 148, 140),
    ],
    proseBookends => const [
      Rect.fromLTWH(44, 88, 148, 132),
      Rect.fromLTWH(228, 400, 148, 132),
    ],
    proseThreeIslands => const [
      Rect.fromLTWH(264, 88, 112, 136),
      Rect.fromLTWH(44, 268, 112, 136),
      Rect.fromLTWH(264, 448, 112, 84),
    ],
    prosePhotoEssay => const [
      Rect.fromLTWH(44, 88, 116, 132),
      Rect.fromLTWH(44, 248, 116, 132),
      Rect.fromLTWH(44, 408, 116, 124),
    ],
    proseTriptych => const [
      Rect.fromLTWH(44, 266, 96, 128),
      Rect.fromLTWH(162, 266, 96, 128),
      Rect.fromLTWH(280, 266, 96, 128),
    ],
    proseGalleryColumns => const [
      Rect.fromLTWH(44, 88, 148, 100),
      Rect.fromLTWH(228, 252, 148, 116),
      Rect.fromLTWH(44, 432, 148, 100),
    ],
    _ => const [],
  };

  /// 保持照片顺序从左到右、从上到下，主图始终先于附图。
  static List<Rect> _grid(
    int columns,
    int rows,
    Rect bounds, {
    double gap = 8,
  }) {
    final width = (bounds.width - gap * (columns - 1)) / columns;
    final height = (bounds.height - gap * (rows - 1)) / rows;
    return [
      for (var row = 0; row < rows; row++)
        for (var column = 0; column < columns; column++)
          Rect.fromLTWH(
            bounds.left + column * (width + gap),
            bounds.top + row * (height + gap),
            width,
            height,
          ),
    ];
  }
}
