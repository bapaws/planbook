import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:paper_notebook/src/paper_notebook_cover_style.dart';
import 'package:paper_notebook/src/paper_notebook_scope.dart';
import 'package:paper_notebook/src/paper_notebook_theme.dart';

/// 封面装饰相对书脊的朝向。打开后左扇书脊在右侧。
class PaperNotebookCoverHinge extends InheritedWidget {
  const PaperNotebookCoverHinge({
    required this.onRight,
    required super.child,
    super.key,
  });

  final bool onRight;

  static bool onRightOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<PaperNotebookCoverHinge>()
            ?.onRight ??
        false;
  }

  @override
  bool updateShouldNotify(PaperNotebookCoverHinge oldWidget) =>
      onRight != oldWidget.onRight;
}

/// 印在封面上的标题、年份与风格装饰。
class PaperNotebookCover extends StatelessWidget {
  const PaperNotebookCover({
    this.year,
    this.title,
    this.subtitle,
    this.accentColor,
    this.template,
    super.key,
  });

  static const ribbonKey = Key('paper-notebook-cover-ribbon');
  static const badgeKey = Key('paper-notebook-cover-badge');
  static const plateKey = Key('paper-notebook-cover-plate');
  static const splitKey = Key('paper-notebook-cover-split');
  static const polaroidKey = Key('paper-notebook-cover-polaroid');
  static const bandKey = Key('paper-notebook-cover-band');
  static const stitchKey = Key('paper-notebook-cover-stitch');

  final int? year;
  final String? title;
  final String? subtitle;
  final Color? accentColor;
  final PaperNotebookCoverTemplate? template;

  @override
  Widget build(BuildContext context) {
    final scope = PaperNotebookScope.maybeOf(context);
    final theme = scope?.theme ?? PaperNotebookTheme.defaults;
    final leather = theme.paletteFor(Theme.of(context).brightness).leather;
    final onLeather =
        theme.onCover ?? PaperNotebookCoverColors.onCover(leather);
    final accent = accentColor ?? theme.accentColor;
    final resolvedYear = year ?? theme.year;
    final resolvedTitle = title ?? theme.title;
    final layout = template ?? theme.template;
    final overPhoto = theme.coverBackground != null;
    return switch (layout) {
      PaperNotebookCoverTemplate.classic => _ClassicCover(
        year: resolvedYear,
        title: resolvedTitle,
        subtitle: subtitle,
        accent: accent,
        leather: leather,
        onLeather: onLeather,
        overPhoto: overPhoto,
      ),
      PaperNotebookCoverTemplate.yearOnly => _YearOnlyCover(
        year: resolvedYear,
        accent: accent,
        onLeather: onLeather,
      ),
      PaperNotebookCoverTemplate.titlePlate => _TitlePlateCover(
        year: resolvedYear,
        title: resolvedTitle,
        accent: accent,
        leather: leather,
        onLeather: onLeather,
        overPhoto: overPhoto,
      ),
      PaperNotebookCoverTemplate.spineStamp => _SpineStampCover(
        year: resolvedYear,
        title: resolvedTitle,
        accent: accent,
        onLeather: onLeather,
        overPhoto: overPhoto,
      ),
      PaperNotebookCoverTemplate.frame => _FrameCover(
        year: resolvedYear,
        title: resolvedTitle,
        accent: accent,
        onLeather: onLeather,
      ),
      PaperNotebookCoverTemplate.bellyBand => _BellyBandCover(
        year: resolvedYear,
        title: resolvedTitle,
        accent: accent,
        leather: leather,
        onLeather: onLeather,
        overPhoto: overPhoto,
      ),
      PaperNotebookCoverTemplate.stabBound => _StabBoundCover(
        year: resolvedYear,
        title: resolvedTitle,
        accent: accent,
        onLeather: onLeather,
        leather: leather,
        overPhoto: overPhoto,
      ),
    };
  }
}

/// 有封面图时色块半透明，让油画透出来。文字压在色块上的略实一点。
Color _coverFill(Color color, {required bool overPhoto, double alpha = 0.46}) {
  if (!overPhoto) return color;
  return color.withValues(alpha: alpha);
}

TextStyle? _kicker(BuildContext context, Color color) {
  return Theme.of(context).textTheme.labelLarge?.copyWith(
    color: color,
    letterSpacing: 2.2,
    fontWeight: FontWeight.w600,
    fontSize: 13.5,
    height: 1.2,
  );
}

class _CoverKickerText extends StatelessWidget {
  const _CoverKickerText({
    required this.text,
    required this.color,
    this.textAlign,
  });

  final String text;
  final Color color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      PaperNotebookCoverColors.brandImprint(text),
      textAlign: textAlign,
      style: _kicker(context, color),
    );
  }
}

TextStyle? _yearStyle(BuildContext context, Color color, {double size = 54}) {
  return Theme.of(context).textTheme.headlineMedium?.copyWith(
    color: color,
    fontSize: size,
    fontWeight: FontWeight.w600,
    height: 1.05,
    letterSpacing: 0.4,
  );
}

class _Hairline extends StatelessWidget {
  const _Hairline({required this.color, this.width = 28});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 1,
      child: ColoredBox(color: color.withValues(alpha: 0.45)),
    );
  }
}

class _ClassicCover extends StatelessWidget {
  const _ClassicCover({
    required this.year,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.leather,
    required this.onLeather,
    required this.overPhoto,
  });

  final int? year;
  final String? title;
  final String? subtitle;
  final Color accent;
  final Color leather;
  final Color onLeather;
  final bool overPhoto;

  @override
  Widget build(BuildContext context) {
    final ribbon = _coverFill(
      PaperNotebookCoverColors.ribbonFrom(leather),
      overPhoto: overPhoto,
      alpha: 0.55,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final hingeRight = PaperNotebookCoverHinge.onRightOf(context);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              key: PaperNotebookCover.ribbonKey,
              left: hingeRight ? constraints.maxWidth * 0.11 : null,
              right: hingeRight ? null : constraints.maxWidth * 0.11,
              top: constraints.maxHeight * 0.1,
              bottom: constraints.maxHeight * 0.1,
              width: 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ribbon,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 0.6,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth * (hingeRight ? 0.2 : 0.14),
                0,
                constraints.maxWidth * (hingeRight ? 0.14 : 0.2),
                0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    _CoverKickerText(text: title!, color: onLeather),
                  if (year != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      '$year',
                      style: _yearStyle(context, onLeather, size: 56),
                    ),
                    const SizedBox(height: 14),
                    _Hairline(color: accent, width: 36),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: 14),
                    _CoverKickerText(text: subtitle!, color: accent),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _YearOnlyCover extends StatelessWidget {
  const _YearOnlyCover({
    required this.year,
    required this.accent,
    required this.onLeather,
  });

  final int? year;
  final Color accent;
  final Color onLeather;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side =
            math.min(constraints.maxWidth, constraints.maxHeight) * 0.46;
        return Center(
          child: SizedBox(
            key: PaperNotebookCover.badgeKey,
            width: side,
            height: side,
            child: CustomPaint(
              painter: _MedallionPainter(color: accent.withValues(alpha: 0.7)),
              child: Center(
                child: year == null
                    ? const SizedBox.shrink()
                    : Text(
                        '$year',
                        style: _yearStyle(
                          context,
                          onLeather,
                          size: math.max(42.0, side * 0.36),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TitlePlateCover extends StatelessWidget {
  const _TitlePlateCover({
    required this.year,
    required this.title,
    required this.accent,
    required this.leather,
    required this.onLeather,
    required this.overPhoto,
  });

  final int? year;
  final String? title;
  final Color accent;
  final Color leather;
  final Color onLeather;
  final bool overPhoto;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth * 0.14,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                key: PaperNotebookCover.plateKey,
                decoration: BoxDecoration(
                  color: _coverFill(
                    Color.lerp(leather, Colors.black, 0.22)!,
                    overPhoto: overPhoto,
                    alpha: 0.58,
                  ),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.45),
                    width: 0.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: onLeather.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: title == null
                          ? const SizedBox(width: 72, height: 16)
                          : _CoverKickerText(
                              text: title!,
                              color: onLeather,
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                ),
              ),
              if (year != null) ...[
                const SizedBox(height: 22),
                Text('$year', style: _yearStyle(context, onLeather, size: 50)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SpineStampCover extends StatelessWidget {
  const _SpineStampCover({
    required this.year,
    required this.title,
    required this.accent,
    required this.onLeather,
    required this.overPhoto,
  });

  final int? year;
  final String? title;
  final Color accent;
  final Color onLeather;
  final bool overPhoto;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final split = math.max(22.0, constraints.maxWidth * 0.18);
        final hingeRight = PaperNotebookCoverHinge.onRightOf(context);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              key: PaperNotebookCover.splitKey,
              left: hingeRight ? null : 0,
              right: hingeRight ? 0 : null,
              top: 0,
              bottom: 0,
              width: split,
              child: ColoredBox(
                color: _coverFill(
                  Color.lerp(accent, PaperNotebookCoverColors.paper, 0.18)!,
                  overPhoto: overPhoto,
                ),
              ),
            ),
            Padding(
              padding: hingeRight
                  ? EdgeInsets.fromLTRB(24, 40, split + 22, 40)
                  : EdgeInsets.fromLTRB(split + 22, 40, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    _CoverKickerText(text: title!, color: onLeather),
                  const Spacer(),
                  if (year != null)
                    Text(
                      '$year',
                      style: _yearStyle(context, onLeather, size: 56),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FrameCover extends StatelessWidget {
  const _FrameCover({
    required this.year,
    required this.title,
    required this.accent,
    required this.onLeather,
  });

  final int? year;
  final String? title;
  final Color accent;
  final Color onLeather;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 34, 26, 34),
      child: DecoratedBox(
        key: PaperNotebookCover.polaroidKey,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: accent.withValues(alpha: 0.55), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: onLeather.withValues(alpha: 0.18),
                width: 0.8,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
              child: Column(
                children: [
                  const Spacer(),
                  if (year != null)
                    Text(
                      '$year',
                      style: _yearStyle(context, onLeather, size: 54),
                    ),
                  const Spacer(),
                  if (title != null)
                    _CoverKickerText(text: title!, color: onLeather),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BellyBandCover extends StatelessWidget {
  const _BellyBandCover({
    required this.year,
    required this.title,
    required this.accent,
    required this.leather,
    required this.onLeather,
    required this.overPhoto,
  });

  final int? year;
  final String? title;
  final Color accent;
  final Color leather;
  final Color onLeather;
  final bool overPhoto;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bandH = math.max(64.0, constraints.maxHeight * 0.18);
        final top = (constraints.maxHeight - bandH) / 2;
        final bandFill = _coverFill(
          Color.lerp(leather, Colors.black, 0.22)!,
          overPhoto: overPhoto,
          alpha: 0.58,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            if (title != null)
              Positioned(
                left: 0,
                right: 0,
                top: math.max(28, top - 36),
                child: _CoverKickerText(
                  text: title!,
                  color: onLeather,
                  textAlign: TextAlign.center,
                ),
              ),
            Positioned(
              key: PaperNotebookCover.bandKey,
              left: 0,
              right: 0,
              top: top,
              height: bandH,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bandFill,
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: accent.withValues(alpha: 0.55),
                      width: 1,
                    ),
                  ),
                ),
                child: Center(
                  child: year == null
                      ? const SizedBox.shrink()
                      : Text(
                          '$year',
                          style: _yearStyle(context, onLeather, size: 46),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StabBoundCover extends StatelessWidget {
  const _StabBoundCover({
    required this.year,
    required this.title,
    required this.accent,
    required this.onLeather,
    required this.leather,
    required this.overPhoto,
  });

  final int? year;
  final String? title;
  final Color accent;
  final Color onLeather;
  final Color leather;
  final bool overPhoto;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spine = math.max(28.0, constraints.maxWidth * 0.11);
        final hingeRight = PaperNotebookCoverHinge.onRightOf(context);
        final tape = _coverFill(
          Color.lerp(leather, PaperNotebookCoverColors.paper, 0.35)!,
          overPhoto: overPhoto,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              key: PaperNotebookCover.stitchKey,
              left: hingeRight ? null : 0,
              right: hingeRight ? 0 : null,
              top: 0,
              bottom: 0,
              width: spine,
              child: ColoredBox(
                color: tape,
                child: CustomPaint(
                  painter: _StabStitchPainter(
                    color: overPhoto ? accent : accent.withValues(alpha: 0.85),
                    bold: overPhoto,
                  ),
                ),
              ),
            ),
            Padding(
              padding: hingeRight
                  ? EdgeInsets.fromLTRB(26, 40, spine + 22, 40)
                  : EdgeInsets.fromLTRB(spine + 22, 40, 26, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    _CoverKickerText(text: title!, color: onLeather),
                  const Spacer(),
                  if (year != null)
                    Text(
                      '$year',
                      style: _yearStyle(context, onLeather, size: 54),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MedallionPainter extends CustomPainter {
  const _MedallionPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 1.5;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(c, r, stroke);
    canvas.drawCircle(c, r - 7, stroke..strokeWidth = 0.7);
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _StabStitchPainter extends CustomPainter {
  const _StabStitchPainter({required this.color, this.bold = false});

  final Color color;
  final bool bold;

  @override
  void paint(Canvas canvas, Size size) {
    final thread = Paint()
      ..color = color
      ..strokeWidth = bold ? 1.7 : 1.15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final hole = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = bold ? 1.45 : 1;
    const count = 4;
    final inset = size.height * 0.16;
    final span = size.height - inset * 2;
    final cx = size.width * 0.55;
    final arm = math.min(size.width * 0.22, 7.0);
    final radius = bold ? 2.6 : 2.1;
    for (var i = 0; i < count; i++) {
      final y = inset + span * (i + 0.5) / count;
      canvas.drawCircle(Offset(cx, y), radius, hole);
      canvas.drawLine(Offset(cx - arm, y), Offset(cx + arm, y), thread);
    }
  }

  @override
  bool shouldRepaint(covariant _StabStitchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bold != bold;
}
