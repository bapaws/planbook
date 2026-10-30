import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:paper_notebook/src/engine/page_fold_geometry.dart';
import 'package:paper_notebook/src/layout/notebook_format.dart';
import 'package:paper_notebook/src/paper_notebook_pattern.dart';
import 'package:paper_notebook/src/paper_notebook_scope.dart';
import 'package:paper_notebook/src/paper_notebook_surface.dart';

/// 左页纸背与翻页落定纸瓣共用的几何 / 明暗，避免两套样式对不齐。
abstract final class BookVersoLeaf {
  /// 相对理想书脊位置向右贴一点，盖住装订缝。只加在书脊侧，不挤外缘露出。
  static const spineOverlap = 3.0;
  static const outerRadius = 16.0;
  static const spineRadius = 3.0;

  /// 落定后保留的折页明暗强度（与纸瓣 LinearGradient 同一套系数）。
  static const landedLight = 0.55;

  /// 书脊附近由深到浅的暗部宽度（占叶宽比例）。
  static const spineShadeWidth = 0.14;

  /// 静止 / 落定后书脊最深处的黑色透明度（偏淡）。
  static const spineShadeAlpha = 0.10;

  /// 翻页刚开始时书脊暗部额外加深的幅度。
  static const spineShadeFlipBoost = 0.10;

  /// 回翻时 fold.progress 高于此值，纸上仍印落定左叶明暗。
  /// 左滑落到左叶也走同一段。印在纸上（经折页镜像），不是钉在屏幕书脊。
  static const backRestProgress = 0.94;

  static Color edgeColor(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFF3A342C)
      : const Color(0xFFE8DFD2);

  /// 右页坐标系下的左叶矩形（书脊在 x≈0）。外缘对齐 A4，书脊侧多出 [spineOverlap]。
  static Rect rectInPage(Size page) =>
      Rect.fromLTWH(-page.width, 0, page.width + spineOverlap, page.height);

  static RRect rrectInPage(
    Size page, {
    double outerRadius = BookVersoLeaf.outerRadius,
    double spineRadius = BookVersoLeaf.spineRadius,
  }) => RRect.fromRectAndCorners(
    rectInPage(page),
    topLeft: Radius.circular(outerRadius),
    bottomLeft: Radius.circular(outerRadius),
    topRight: Radius.circular(spineRadius),
    bottomRight: Radius.circular(spineRadius),
  );

  static double stackLeft(double pageLeft, [double? leftLeafWidth]) =>
      pageLeft - (leftLeafWidth ?? NotebookFormat.defaults.leftLeafWidth);

  static double stackWidthOf(NotebookFormat format) =>
      format.leftLeafWidth + spineOverlap;

  static double get stackWidth => stackWidthOf(NotebookFormat.defaults);

  /// 封面内侧纸在封面板局部坐标。枢纽 x=0；rotateY(π) 后与静止左叶重合。
  static const coverInsideLeft = -spineOverlap;

  static BorderRadius borderRadius({
    required bool spineOnLeft,
    double outerRadius = BookVersoLeaf.outerRadius,
    double spineRadius = BookVersoLeaf.spineRadius,
  }) {
    final outer = Radius.circular(outerRadius);
    final spine = Radius.circular(spineRadius);
    return BorderRadius.only(
      topLeft: spineOnLeft ? spine : outer,
      bottomLeft: spineOnLeft ? spine : outer,
      topRight: spineOnLeft ? outer : spine,
      bottomRight: spineOnLeft ? outer : spine,
    );
  }
}

/// 已翻到左边的纸背：平铺纸纹 + 书脊明暗。封面内侧用 [spineOnLeft] 镜像，翻 180° 后与静止左叶同一套几何。
class BookVersoPage extends StatelessWidget {
  const BookVersoPage({
    required this.edge,
    this.spineOnLeft = false,
    super.key,
  });

  final Color edge;
  final bool spineOnLeft;

  @override
  Widget build(BuildContext context) {
    final format = PaperNotebookScope.formatOf(context);
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BookVersoLeaf.borderRadius(
          spineOnLeft: spineOnLeft,
          outerRadius: format.pageOuterRadius,
          spineRadius: format.spineRadius,
        ),
        child: PaperNotebookSurface(
          child: CustomPaint(
            painter: _BookVersoPagePainter(
              edge: edge,
              spineOnLeft: spineOnLeft,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _BookVersoPagePainter extends CustomPainter {
  const _BookVersoPagePainter({required this.edge, required this.spineOnLeft});

  final Color edge;
  final bool spineOnLeft;

  @override
  void paint(Canvas canvas, Size size) {
    paintBookVersoShading(
      canvas,
      Offset.zero & size,
      edge: edge,
      spineOnLeft: spineOnLeft,
    );
  }

  @override
  bool shouldRepaint(covariant _BookVersoPagePainter oldDelegate) {
    return oldDelegate.edge != edge || oldDelegate.spineOnLeft != spineOnLeft;
  }
}

/// 纸瓣明暗：按包围盒左右渐变的暗部（无亮高光）。
/// [spineOnLeft] 为 true 时左右对调，供折页镜像后与左叶对齐。
void paintFoldFlapLighting(
  Canvas canvas,
  Rect rect, {
  required double strength,
  bool spineOnLeft = false,
}) {
  final s = strength.clamp(0.0, 1.0);
  if (s < 0.001) return;
  final outer = spineOnLeft ? Alignment.centerRight : Alignment.centerLeft;
  final inner = spineOnLeft ? Alignment.centerLeft : Alignment.centerRight;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: outer,
        end: inner,
        colors: [
          Colors.black.withValues(alpha: 0.08 * s),
          Colors.black.withValues(alpha: 0.015 * s),
          Colors.transparent,
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(rect),
  );
  canvas.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: inner,
        end: outer,
        colors: [
          Colors.black.withValues(alpha: 0.06 * s),
          const Color(0x00000000),
        ],
        stops: const [0.0, 0.28],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
}

/// 书脊侧由深到浅。左叶：右缘装订处最深；[spineOnLeft] 则左缘最深。
/// [extraAlpha] 只叠加深部（翻页开始用），不重复画基底。
void paintSpineShade(
  Canvas canvas,
  Rect rect, {
  double amount = 1.0,
  double extraAlpha = 0.0,
  bool spineOnLeft = false,
}) {
  final a = amount.clamp(0.0, 1.0);
  final depth = BookVersoLeaf.spineShadeAlpha * a + extraAlpha.clamp(0.0, 0.3);
  if (depth < 0.001) return;
  final w = BookVersoLeaf.spineShadeWidth.clamp(0.02, 0.5);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: spineOnLeft ? Alignment.centerLeft : Alignment.centerRight,
        end: spineOnLeft ? Alignment.centerRight : Alignment.centerLeft,
        colors: [
          Colors.black.withValues(alpha: depth),
          Colors.black.withValues(alpha: depth * 0.35),
          const Color(0x00000000),
        ],
        stops: [0.0, w * 0.45, w],
      ).createShader(rect),
  );
}

/// 左页纸背：纯纸色 + 书脊深→浅 + 纸瓣暗部（无亮高光）。
void paintBookVersoPaper(
  Canvas canvas,
  Size size, {
  required Color paper,
  Color? edge,
  double amount = 1.0,
}) {
  paintBookVersoInRect(
    canvas,
    Offset.zero & size,
    paper: paper,
    edge: edge,
    amount: amount,
  );
}

/// [amount] 0→1：明暗从无到落定强度。
void paintBookVersoInRect(
  Canvas canvas,
  Rect rect, {
  required Color paper,
  Color? edge,
  double amount = 1.0,
}) {
  canvas.drawRect(rect, Paint()..color = paper);
  paintBookVersoShading(canvas, rect, edge: edge, amount: amount);
}

/// 左叶书脊暗部 + 纸瓣暗部 + 装订线（不含底色）。
/// [spineOnLeft] 左右对调，画在页坐标系里再经折页镜像，静止时与左叶重合。
void paintBookVersoShading(
  Canvas canvas,
  Rect rect, {
  Color? edge,
  double amount = 1.0,
  bool spineOnLeft = false,
}) {
  final a = amount.clamp(0.0, 1.0);
  if (a < 0.001) return;
  paintSpineShade(canvas, rect, amount: a, spineOnLeft: spineOnLeft);
  paintFoldFlapLighting(
    canvas,
    rect,
    strength: BookVersoLeaf.landedLight * a,
    spineOnLeft: spineOnLeft,
  );
  if (edge == null) return;
  final x = spineOnLeft ? rect.left + 1 : rect.right - 1;
  canvas.drawLine(
    Offset(x, rect.top + 8),
    Offset(x, rect.bottom - 8),
    Paint()
      ..color = edge.withValues(alpha: 0.55 * a)
      ..strokeWidth = 1,
  );
}

/// 纸瓣还有多少看起来像落定左叶。只跟 fold.progress 有关：靠近 1 在左叶，离开后到 0。
/// 左滑下一页是右滑上一页的逆过程，共用这一条。
double foldRestOnLeft({required double progress}) {
  final t = progress.clamp(0.0, 1.0);
  return Curves.easeOut.transform(
    ((t - BookVersoLeaf.backRestProgress) /
            (1.0 - BookVersoLeaf.backRestProgress))
        .clamp(0.0, 1.0),
  );
}

/// 折页纸瓣明暗。只跟 progress 有关：t=1 贴左叶（无额外暗部），其余保持可见掀起暗部，中间最暗。
class FoldFlapLight {
  const FoldFlapLight({
    required this.rest,
    required this.strength,
    required this.crease,
    required this.shade,
  });

  final double rest;
  final double strength;
  final double crease;
  final double shade;
}

FoldFlapLight foldFlapLight({required double progress}) {
  final t = progress.clamp(0.0, 1.0);
  final rest = foldRestOnLeft(progress: t);
  final curl = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.85;
  // 离开左叶后立刻用落定强度接手；贴右叶时也不收掉，否则刚掀起看不出翻起。
  // t=1 时 rest=1，strength 仍为 0，按下左页不会跳变。
  // 中间峰值压到 0.85，暗部略亮一点。
  final fromRest = (1.0 - rest) * BookVersoLeaf.landedLight;
  return FoldFlapLight(
    rest: rest,
    strength: math.max(curl, fromRest),
    crease: math.max(curl, 0.45 * (1.0 - rest)),
    shade: math.max(
      (1.0 - Curves.easeInOut.transform(t)).clamp(0.0, 1.0),
      0.18 * (1.0 - rest),
    ),
  );
}

/// 画完整左叶纸背（圆角 + 纸瓣同款明暗 + 书脊线）。
void paintBookVersoLeaf(
  Canvas canvas,
  Size page, {
  required Color paper,
  required Color edge,
  double opacity = 1.0,
}) {
  final a = opacity.clamp(0.0, 1.0);
  if (a < 0.001) return;
  final leaf = BookVersoLeaf.rrectInPage(page);
  final bounds = leaf.outerRect.inflate(2);
  canvas.save();
  if (a < 0.999) {
    canvas.saveLayer(
      bounds,
      Paint()
        ..colorFilter = ColorFilter.mode(
          Color.fromARGB((255 * a).round(), 255, 255, 255),
          BlendMode.modulate,
        ),
    );
  }
  canvas.clipRRect(leaf);
  paintBookVersoInRect(canvas, leaf.outerRect, paper: paper, edge: edge);
  if (a < 0.999) canvas.restore();
  canvas.restore();
}

CustomClipper<Path> paperFoldClipper({
  required Size size,
  required double progress,
  required bool forward,
  PageFoldGeometry? fold,
}) {
  final geometry =
      fold ??
      PageFoldGeometry.lerp(size: size, progress: progress, forward: forward);
  if (geometry != null) return PathClipper(geometry.remaining);
  return progress >= 0.97 ? const EmptyPageClipper() : const FullPageClipper();
}

PageFoldGeometry? paperFoldOf({
  required Size size,
  required double progress,
  required bool forward,
  Offset? origin,
  Offset? grab,
}) {
  if (origin != null && grab != null) {
    return PageFoldGeometry.fromPointer(
      size: size,
      origin: origin,
      grab: grab,
      forward: forward,
    );
  }
  return PageFoldGeometry.lerp(
    size: size,
    progress: progress,
    forward: forward,
  );
}

class PathClipper extends CustomClipper<Path> {
  const PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant PathClipper oldClipper) => true;
}

class FullPageClipper extends CustomClipper<Path> {
  const FullPageClipper();

  @override
  Path getClip(Size size) => Path()..addRect(Offset.zero & size);

  @override
  bool shouldReclip(covariant FullPageClipper oldClipper) => false;
}

class EmptyPageClipper extends CustomClipper<Path> {
  const EmptyPageClipper();

  @override
  Path getClip(Size size) => Path();

  @override
  bool shouldReclip(covariant EmptyPageClipper oldClipper) => false;
}

/// 把原页面的圆角轮廓沿折痕镜像，再与纸瓣求交。
///
/// 纸瓣脱离静止页的 [ClipRRect] 后仍需保留同一组圆角；否则翻起的外缘会退回直角。
Path roundedFoldFlapPath({
  required PageFoldGeometry fold,
  required BorderRadius pageBorderRadius,
}) {
  final pageShape = Path()
    ..addRRect(pageBorderRadius.toRRect(Offset.zero & fold.size));
  return Path.combine(
    PathOperation.intersect,
    fold.flap,
    pageShape.transform(fold.mirror.storage),
  );
}

Path _roundedPeeledPagePath({
  required PageFoldGeometry fold,
  required BorderRadius pageBorderRadius,
}) {
  final pageShape = Path()
    ..addRRect(pageBorderRadius.toRRect(Offset.zero & fold.size));
  return Path.combine(PathOperation.intersect, fold.peeled, pageShape);
}

class PaperFoldOverlay extends StatefulWidget {
  const PaperFoldOverlay({
    required this.fold,
    required this.progress,
    required this.paperColor,
    required this.edgeColor,
    required this.pageBorderRadius,
    this.tileAsset,
    this.tileScale = PaperNotebookPattern.tileScale,
    this.tilePackage = PaperNotebookPattern.packageName,
    this.settleToLeft = true,
    this.paintOrigin = Offset.zero,
    super.key,
  });

  final PageFoldGeometry fold;
  final double progress;
  final Color paperColor;
  final Color edgeColor;
  final BorderRadius pageBorderRadius;
  final String? tileAsset;
  final String? tilePackage;
  final double tileScale;

  /// 正向翻完落在左叶；回翻时为 false，避免一开始就按「已落定左叶」画导致纸瓣发透。
  final bool settleToLeft;

  /// 折页坐标原点在画布上的位置（可见纸页左上角）。
  final Offset paintOrigin;

  @override
  State<PaperFoldOverlay> createState() => _PaperFoldOverlayState();
}

class _PaperFoldOverlayState extends State<PaperFoldOverlay> {
  ui.Image? _tile;
  var _imageScale = 1.0;
  ImageStream? _stream;
  late final ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener(_onTile);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveTile();
  }

  @override
  void didUpdateWidget(covariant PaperFoldOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tileAsset != widget.tileAsset ||
        oldWidget.tilePackage != widget.tilePackage) {
      _resolveTile();
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  void _resolveTile() {
    final asset = widget.tileAsset;
    if (asset == null) {
      _stream?.removeListener(_listener);
      _stream = null;
      if (_tile != null) {
        setState(() => _tile = null);
      }
      return;
    }
    final stream = AssetImage(
      asset,
      package: widget.tilePackage,
    ).resolve(createLocalImageConfiguration(context));
    if (identical(stream, _stream)) return;
    _stream?.removeListener(_listener);
    _stream = stream;
    stream.addListener(_listener);
  }

  void _onTile(ImageInfo info, bool synchronousCall) {
    if (!mounted) return;
    if (identical(_tile, info.image) && _imageScale == info.scale) return;
    setState(() {
      _tile = info.image;
      _imageScale = info.scale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FoldShadowPainter(
        fold: widget.fold,
        progress: widget.progress,
        paperColor: widget.paperColor,
        edgeColor: widget.edgeColor,
        pageBorderRadius: widget.pageBorderRadius,
        settleToLeft: widget.settleToLeft,
        paintOrigin: widget.paintOrigin,
        tileImage: _tile,
        tileScale: widget.tileScale * _imageScale,
      ),
    );
  }
}

class _FoldShadowPainter extends CustomPainter {
  const _FoldShadowPainter({
    required this.fold,
    required this.progress,
    required this.paperColor,
    required this.edgeColor,
    required this.pageBorderRadius,
    required this.settleToLeft,
    required this.paintOrigin,
    required this.tileScale,
    this.tileImage,
  });

  final PageFoldGeometry fold;
  final double progress;
  final Color paperColor;
  final Color edgeColor;
  final BorderRadius pageBorderRadius;
  final bool settleToLeft;
  final Offset paintOrigin;
  final ui.Image? tileImage;
  final double tileScale;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final light = foldFlapLight(progress: t);
    final rest = light.rest;
    final strength = light.strength;
    final crease = light.crease;
    final shade = light.shade;
    final flapShape = roundedFoldFlapPath(
      fold: fold,
      pageBorderRadius: pageBorderRadius,
    );
    final peeledShape = _roundedPeeledPagePath(
      fold: fold,
      pageBorderRadius: pageBorderRadius,
    );
    canvas.save();
    canvas.translate(paintOrigin.dx, paintOrigin.dy);
    _paintUnderPageShade(canvas, peeledShape, shade, crease);
    _paintFlapFill(canvas, flapShape, rest);
    if (strength > 0.001) {
      canvas.save();
      canvas.clipPath(flapShape);
      paintFoldFlapLighting(canvas, flapShape.getBounds(), strength: strength);
      canvas.restore();
    }
    _paintCrease(canvas, crease);
    canvas.restore();
  }

  /// 不透明纸瓣。底纹和左叶明暗都印在纸上，再经折页镜像到纸瓣。
  void _paintFlapFill(Canvas canvas, Path flapShape, double restOnLeft) {
    final bounds = flapShape.getBounds().inflate(4);
    canvas.saveLayer(bounds, Paint());
    canvas.drawPath(
      flapShape,
      Paint()
        ..color = paperColor
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.src,
    );
    _paintFlapPrint(canvas, flapShape, restOnLeft);
    canvas.drawPath(
      flapShape,
      Paint()
        ..color = paperColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..blendMode = BlendMode.src,
    );
    canvas.restore();
  }

  void _paintFlapPrint(Canvas canvas, Path flapShape, double restOnLeft) {
    canvas.save();
    canvas.clipPath(flapShape);
    canvas.transform(Matrix4.copy(fold.mirror).storage);
    final page = Offset.zero & fold.size;
    _paintPageTiles(canvas, page);
    if (restOnLeft > 0.001) {
      paintBookVersoShading(
        canvas,
        page,
        edge: edgeColor,
        amount: restOnLeft,
        spineOnLeft: true,
      );
    }
    canvas.restore();
  }

  void _paintPageTiles(Canvas canvas, Rect rect) {
    final tile = tileImage;
    if (tile == null || rect.isEmpty) return;
    paintImage(
      canvas: canvas,
      rect: rect,
      image: tile,
      scale: tileScale,
      alignment: Alignment.topLeft,
      repeat: ImageRepeat.repeat,
      filterQuality: FilterQuality.none,
    );
  }

  void _paintCrease(Canvas canvas, double curl) {
    if (curl < 0.001) return;
    canvas.save();
    // 折痕在书脊处会贴着 x=0；裁到右页会把线切掉一半。
    // 回翻开始时折痕就在这里，必须包含左叶才能看见。
    final page = Offset.zero & fold.size;
    final left = BookVersoLeaf.rectInPage(fold.size);
    canvas.clipRect(page.expandToInclude(left).inflate(fold.size.width));
    canvas.drawLine(
      fold.foldA,
      fold.foldB,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22 * curl)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
    );
    canvas.drawLine(
      fold.foldA,
      fold.foldB,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14 * curl)
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _paintUnderPageShade(
    Canvas canvas,
    Path peeledShape,
    double shade,
    double curl,
  ) {
    canvas.save();
    canvas.clipPath(peeledShape);
    canvas.drawPath(
      peeledShape,
      Paint()..color = Colors.black.withValues(alpha: 0.025 * shade),
    );
    final d = fold.normal.distance;
    if (d > 1e-6) {
      final nx = fold.normal.dx / d;
      final ny = fold.normal.dy / d;
      final start = fold.mid;
      if (shade > 0.001) {
        canvas.drawPath(
          peeledShape,
          Paint()
            ..shader = ui.Gradient.linear(
              start,
              start + Offset(nx, ny) * (fold.size.shortestSide * 0.7),
              [
                Colors.black.withValues(alpha: 0.05 * shade),
                const Color(0x00000000),
              ],
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
      }
      if (curl > 0.001) {
        canvas.drawPath(
          peeledShape,
          Paint()
            ..shader = ui.Gradient.linear(
              start,
              start + Offset(nx, ny) * (fold.size.shortestSide * 0.16),
              [
                Colors.black.withValues(alpha: 0.16 * curl),
                const Color(0x00000000),
              ],
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FoldShadowPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fold != fold ||
        oldDelegate.paperColor != paperColor ||
        oldDelegate.edgeColor != edgeColor ||
        oldDelegate.pageBorderRadius != pageBorderRadius ||
        oldDelegate.settleToLeft != settleToLeft ||
        oldDelegate.paintOrigin != paintOrigin ||
        oldDelegate.tileImage != tileImage ||
        oldDelegate.tileScale != tileScale;
  }
}
