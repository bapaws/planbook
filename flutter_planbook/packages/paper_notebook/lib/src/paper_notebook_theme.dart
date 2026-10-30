import 'package:flutter/material.dart';
import 'package:paper_notebook/src/paper_notebook_cover_style.dart';

/// 桌面 / 皮革配色。
class PaperNotebookPalette {
  const PaperNotebookPalette({
    required this.desk,
    required this.leather,
    required this.leatherEdge,
    required this.pageEdge,
  });

  const PaperNotebookPalette.light()
    : desk = Colors.white,
      leather = PaperNotebookCoverColors.sage,
      leatherEdge = const Color(0xFF9AAF97),
      pageEdge = const Color(0xFFEFE6D6);

  const PaperNotebookPalette.dark()
    : desk = const Color(0xFF121212),
      leather = PaperNotebookCoverColors.sage,
      leatherEdge = const Color(0xFF9AAF97),
      pageEdge = const Color(0xFF3A342C);

  final Color desk;
  final Color leather;
  final Color leatherEdge;
  final Color pageEdge;

  @override
  bool operator ==(Object other) {
    return other is PaperNotebookPalette &&
        other.desk == desk &&
        other.leather == leather &&
        other.leatherEdge == leatherEdge &&
        other.pageEdge == pageEdge;
  }

  @override
  int get hashCode => Object.hash(desk, leather, leatherEdge, pageEdge);
}

/// 封面文案、颜色与材质。
class PaperNotebookTheme {
  const PaperNotebookTheme({
    this.title,
    this.year,
    this.accentColor = const Color(0xFF8FA38C),
    this.texture = PaperNotebookCoverTexture.leather,
    this.template = PaperNotebookCoverTemplate.classic,
    this.coverBackground,
    this.onCover,
    this.light = const PaperNotebookPalette.light(),
    this.dark = const PaperNotebookPalette.dark(),
  });

  static const defaults = PaperNotebookTheme();

  final String? title;
  final int? year;
  final Color accentColor;
  final PaperNotebookCoverTexture texture;
  final PaperNotebookCoverTemplate template;
  final ImageProvider? coverBackground;
  final Color? onCover;
  final PaperNotebookPalette light;
  final PaperNotebookPalette dark;

  PaperNotebookPalette paletteFor(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  @override
  bool operator ==(Object other) {
    return other is PaperNotebookTheme &&
        other.title == title &&
        other.year == year &&
        other.accentColor == accentColor &&
        other.texture == texture &&
        other.template == template &&
        other.coverBackground == coverBackground &&
        other.onCover == onCover &&
        other.light == light &&
        other.dark == dark;
  }

  @override
  int get hashCode => Object.hash(
    title,
    year,
    accentColor,
    texture,
    template,
    coverBackground,
    onCover,
    light,
    dark,
  );
}
