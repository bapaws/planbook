import 'package:flutter/material.dart';

/// 封面材质。未知名回落到皮革。
enum PaperNotebookCoverTexture {
  none,
  leather,
  kraft,
  cloth,
  smooth;

  static PaperNotebookCoverTexture parse(String? name) {
    for (final value in PaperNotebookCoverTexture.values) {
      if (value.name == name) return value;
    }
    return PaperNotebookCoverTexture.leather;
  }
}

/// 封面结构。未知名回落到书签带。
enum PaperNotebookCoverTemplate {
  classic,
  yearOnly,
  titlePlate,
  spineStamp,
  frame,
  bellyBand,
  stabBound;

  static PaperNotebookCoverTemplate parse(String? name) {
    for (final value in PaperNotebookCoverTemplate.values) {
      if (value.name == name) return value;
    }
    return PaperNotebookCoverTemplate.classic;
  }

  /// 该布局的 8 个快捷色，首个是默认色。浅色为主，最多一个深色。
  /// 同行色块拉开色相，避免米/绿/蓝灰挤在一起。
  List<Color> get recommendedColors => switch (this) {
    PaperNotebookCoverTemplate.classic => const [
      PaperNotebookCoverColors.sage,
      PaperNotebookCoverColors.ivory,
      PaperNotebookCoverColors.peach,
      PaperNotebookCoverColors.sky,
      PaperNotebookCoverColors.rose,
      PaperNotebookCoverColors.butter,
      PaperNotebookCoverColors.mist,
      PaperNotebookCoverColors.navy,
    ],
    PaperNotebookCoverTemplate.yearOnly => const [
      PaperNotebookCoverColors.sky,
      PaperNotebookCoverColors.chalk,
      PaperNotebookCoverColors.lilac,
      PaperNotebookCoverColors.blush,
      PaperNotebookCoverColors.sage,
      PaperNotebookCoverColors.rose,
      PaperNotebookCoverColors.butter,
      PaperNotebookCoverColors.navy,
    ],
    PaperNotebookCoverTemplate.titlePlate => const [
      PaperNotebookCoverColors.rose,
      PaperNotebookCoverColors.blush,
      PaperNotebookCoverColors.lilac,
      PaperNotebookCoverColors.peach,
      PaperNotebookCoverColors.ivory,
      PaperNotebookCoverColors.sage,
      PaperNotebookCoverColors.mist,
      PaperNotebookCoverColors.navy,
    ],
    PaperNotebookCoverTemplate.spineStamp => const [
      PaperNotebookCoverColors.sage,
      PaperNotebookCoverColors.ivory,
      PaperNotebookCoverColors.lilac,
      PaperNotebookCoverColors.peach,
      PaperNotebookCoverColors.sky,
      PaperNotebookCoverColors.butter,
      PaperNotebookCoverColors.blush,
      PaperNotebookCoverColors.navy,
    ],
    PaperNotebookCoverTemplate.frame => const [
      PaperNotebookCoverColors.butter,
      PaperNotebookCoverColors.ivory,
      PaperNotebookCoverColors.mist,
      PaperNotebookCoverColors.sage,
      PaperNotebookCoverColors.rose,
      PaperNotebookCoverColors.blush,
      PaperNotebookCoverColors.lilac,
      PaperNotebookCoverColors.navy,
    ],
    PaperNotebookCoverTemplate.bellyBand => const [
      PaperNotebookCoverColors.peach,
      PaperNotebookCoverColors.butter,
      PaperNotebookCoverColors.blush,
      PaperNotebookCoverColors.rose,
      PaperNotebookCoverColors.ivory,
      PaperNotebookCoverColors.sage,
      PaperNotebookCoverColors.sky,
      PaperNotebookCoverColors.navy,
    ],
    PaperNotebookCoverTemplate.stabBound => const [
      PaperNotebookCoverColors.mint,
      PaperNotebookCoverColors.ivory,
      PaperNotebookCoverColors.oat,
      PaperNotebookCoverColors.sky,
      PaperNotebookCoverColors.blush,
      PaperNotebookCoverColors.lilac,
      PaperNotebookCoverColors.mist,
      PaperNotebookCoverColors.navy,
    ],
  };

  Color get defaultColor => recommendedColors.first;

  /// 该布局的预览材质。
  PaperNotebookCoverTexture get defaultTexture => switch (this) {
    PaperNotebookCoverTemplate.classic => PaperNotebookCoverTexture.leather,
    PaperNotebookCoverTemplate.yearOnly => PaperNotebookCoverTexture.smooth,
    PaperNotebookCoverTemplate.titlePlate => PaperNotebookCoverTexture.cloth,
    PaperNotebookCoverTemplate.spineStamp => PaperNotebookCoverTexture.cloth,
    PaperNotebookCoverTemplate.frame => PaperNotebookCoverTexture.none,
    PaperNotebookCoverTemplate.bellyBand => PaperNotebookCoverTexture.kraft,
    PaperNotebookCoverTemplate.stabBound => PaperNotebookCoverTexture.leather,
  };
}

/// 浅色粉彩为主，深蓝作点缀。封面字一律奶白。
/// 同系色拉开饱和度与色相，避免米色、绿灰、蓝灰互相撞车。
abstract final class PaperNotebookCoverColors {
  static const ivory = Color(0xFFEDE6D8);
  static const chalk = Color(0xFFD2DCE6);
  static const butter = Color(0xFFDCC05A);
  static const blush = Color(0xFFE8B4BC);
  static const sageLight = Color(0xFFC5D4BE);
  static const lilac = Color(0xFFA888C0);
  static const peach = Color(0xFFE59B78);
  static const sky = Color(0xFF5B9EBF);
  static const mint = Color(0xFF5FBE8C);
  static const oat = Color(0xFFC49A62);

  static const sage = Color(0xFFA3B194);
  static const mist = Color(0xFF8B9BA8);
  static const rose = Color(0xFFC47872);
  static const sand = Color(0xFFD4A84A);
  static const navy = Color(0xFF2F3C4C);

  static const swatches = [
    ivory,
    chalk,
    butter,
    blush,
    sageLight,
    peach,
    sky,
    mint,
    oat,
    sage,
    mist,
    rose,
    sand,
    navy,
  ];

  static const ink = Color(0xFF3A3530);
  static const paper = Color(0xFFF7F1E8);
  static const paperSoft = Color(0xFFFBF7F0);
  static const cream = Color(0xFFF6F1E8);

  /// 封面 / 内页品牌字：全大写，配合 kicker 字距。
  static String brandImprint(String text) => text.toUpperCase();

  /// 封面主文字：默认白字；底色过浅时改墨色，避免发灰看不清。
  static Color onCover(Color leather) {
    return leather.computeLuminance() > 0.68 ? ink : Colors.white;
  }

  static Color accentFrom(Color leather) {
    final hsl = HSLColor.fromColor(leather);
    return hsl
        .withSaturation((hsl.saturation * 1.12).clamp(0.12, 0.42))
        .withLightness((hsl.lightness - 0.16).clamp(0.42, 0.62))
        .toColor();
  }

  static Color slightlyDarker(Color color) {
    final hsl = HSLColor.fromColor(color);
    final delta = color.computeLuminance() > 0.5 ? 0.04 : 0.08;
    return hsl.withLightness((hsl.lightness - delta).clamp(0, 1)).toColor();
  }

  static Color edgeFrom(Color leather) {
    final t = leather.computeLuminance() > 0.5 ? 0.08 : 0.16;
    return Color.lerp(leather, Colors.black, t)!;
  }

  static Color ribbonFrom(Color leather) {
    return Color.lerp(paper, accentFrom(leather), 0.55)!;
  }
}
