import 'package:flutter/material.dart';

/// 内页纸张平铺底纹。
enum PaperNotebookPattern {
  dots,
  grid,
  solid;

  static const packageName = 'paper_notebook';
  static const tileScale = 3.0;

  static const _assets = {
    PaperNotebookPattern.dots: (
      light: 'assets/tiles/bg_dot_light.png',
      dark: 'assets/tiles/bg_dot_dark.png',
    ),
    PaperNotebookPattern.grid: (
      light: 'assets/tiles/bg_grid_light.png',
      dark: 'assets/tiles/bg_grid_dark.png',
    ),
  };

  bool get hasTile => this != PaperNotebookPattern.solid;

  String assetFor(Brightness brightness) {
    final pair = _assets[this];
    if (pair == null) {
      throw StateError('PaperNotebookPattern.$name has no tile');
    }
    return brightness == Brightness.dark ? pair.dark : pair.light;
  }

  AssetImage? imageFor(Brightness brightness) {
    if (!hasTile) return null;
    return AssetImage(assetFor(brightness), package: packageName);
  }

  Color fallbackColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF1C1A17)
        : Colors.white;
  }

  static PaperNotebookPattern parse(String? name) {
    for (final value in PaperNotebookPattern.values) {
      if (value.name == name) return value;
    }
    return PaperNotebookPattern.dots;
  }
}
