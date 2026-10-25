import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:paper_notebook/paper_notebook.dart';

/// 某年日记本的封面和纸张，存法和 Jotbook 的笔记本外观一致。
class DiaryNotebookLook extends Equatable {
  const DiaryNotebookLook({
    this.color = PaperNotebookCoverColors.sage,
    this.texture = PaperNotebookCoverTexture.none,
    this.template = PaperNotebookCoverTemplate.classic,
    this.paperPattern = PaperNotebookPattern.solid,
    this.coverImage = PaperNotebookCoverImage.none,
  });

  /// 还没保存过的年份：版式、推荐色和包内封面按年轮换。
  factory DiaryNotebookLook.prefabFor(
    int year, {
    int startYear = prefabStartYear,
  }) {
    const templates = PaperNotebookCoverTemplate.values;
    final template = templates[year % templates.length];
    const images = PaperNotebookCoverImage.bundled;
    return DiaryNotebookLook(
      color: template.defaultColor,
      texture: template.defaultTexture,
      template: template,
      coverImage: images[_coverIndex(year, images.length, startYear)],
    );
  }

  factory DiaryNotebookLook.fromJson(Map<String, dynamic> json) {
    return DiaryNotebookLook(
      color: parseColor(json['color'] as String?),
      texture: PaperNotebookCoverTexture.parse(json['texture'] as String?),
      template: PaperNotebookCoverTemplate.parse(json['template'] as String?),
      paperPattern: PaperNotebookPattern.parse(
        json['paperPattern'] as String?,
      ),
      coverImage: PaperNotebookCoverImage.parse(
        json['coverImage'] as String?,
      ),
    );
  }

  static final _hexPattern = RegExp(r'^#?([0-9a-fA-F]{6})$');

  /// 目录第 0 张对应的年份，和 Jotbook 相同，避免默认封面逐年错位。
  static const prefabStartYear = 2016;

  final Color color;
  final PaperNotebookCoverTexture texture;
  final PaperNotebookCoverTemplate template;
  final PaperNotebookPattern paperPattern;
  final PaperNotebookCoverImage coverImage;

  String get storedColor => encodeColor(color);

  DiaryNotebookLook copyWith({
    Color? color,
    PaperNotebookCoverTexture? texture,
    PaperNotebookCoverTemplate? template,
    PaperNotebookPattern? paperPattern,
    PaperNotebookCoverImage? coverImage,
  }) {
    return DiaryNotebookLook(
      color: color ?? this.color,
      texture: texture ?? this.texture,
      template: template ?? this.template,
      paperPattern: paperPattern ?? this.paperPattern,
      coverImage: coverImage ?? this.coverImage,
    );
  }

  PaperNotebookTheme theme({
    required int year,
    required String title,
  }) {
    final leather = color;
    final darkLeather = PaperNotebookCoverColors.slightlyDarker(leather);
    final background = coverImage.image;
    return PaperNotebookTheme(
      year: year,
      title: title,
      accentColor: PaperNotebookCoverColors.accentFrom(leather),
      texture: texture,
      template: template,
      coverBackground: background,
      onCover: background != null ? coverImage.onCover : null,
      light: PaperNotebookPalette(
        desk: Colors.white,
        leather: leather,
        leatherEdge: PaperNotebookCoverColors.edgeFrom(leather),
        pageEdge: const Color(0xFFEFE6D6),
      ),
      dark: PaperNotebookPalette(
        desk: const Color(0xFF121212),
        leather: darkLeather,
        leatherEdge: PaperNotebookCoverColors.edgeFrom(darkLeather),
        pageEdge: const Color(0xFF3A342C),
      ),
    );
  }

  Map<String, String> toJson() => {
    'color': storedColor,
    'texture': texture.name,
    'template': template.name,
    'paperPattern': paperPattern.name,
    'coverImage': coverImage.id,
  };

  static Map<int, DiaryNotebookLook> fromProfile(
    Map<String, Map<String, String>> raw,
  ) {
    final looks = <int, DiaryNotebookLook>{};
    for (final entry in raw.entries) {
      final year = int.tryParse(entry.key);
      if (year == null) continue;
      looks[year] = DiaryNotebookLook.fromJson(
        Map<String, dynamic>.from(entry.value),
      );
    }
    return looks;
  }

  static Map<int, DiaryNotebookLook> decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final looks = <int, DiaryNotebookLook>{};
      for (final entry in decoded.entries) {
        final year = int.tryParse(entry.key.toString());
        final value = entry.value;
        if (year == null || value is! Map) continue;
        looks[year] = DiaryNotebookLook.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
      return looks;
    } on FormatException {
      return const {};
    }
  }

  static String encode(Map<int, DiaryNotebookLook> looks) {
    return jsonEncode({
      for (final entry in looks.entries) '${entry.key}': entry.value.toJson(),
    });
  }

  static Color parseColor(String? value) {
    final match = _hexPattern.firstMatch(value?.trim() ?? '');
    if (match == null) return PaperNotebookCoverColors.sage;
    final rgb = int.parse(match.group(1)!, radix: 16);
    return Color(0xFF000000 | rgb);
  }

  static String encodeColor(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static int _coverIndex(int year, int length, int startYear) {
    if (length <= 0) return 0;
    final offset = year - startYear;
    if (offset >= 0 && offset < length) return offset;
    final wrapped = offset % length;
    return wrapped < 0 ? wrapped + length : wrapped;
  }

  @override
  List<Object?> get props => [
    color,
    texture,
    template,
    paperPattern,
    coverImage,
  ];
}
