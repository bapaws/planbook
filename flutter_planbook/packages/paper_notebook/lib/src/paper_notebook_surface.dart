import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:paper_notebook/src/paper_notebook_pattern.dart';
import 'package:paper_notebook/src/paper_notebook_scope.dart';

/// 纸页底：有 tile 则平铺，素纸只铺底色。缺 scope 时默认点阵。
class PaperNotebookSurface extends StatelessWidget {
  const PaperNotebookSurface({required this.child, this.pattern, super.key});

  final Widget child;
  final PaperNotebookPattern? pattern;

  @override
  Widget build(BuildContext context) {
    final resolved =
        pattern ??
        PaperNotebookScope.maybeOf(context)?.pattern ??
        PaperNotebookPattern.dots;
    return _TiledPaper(pattern: resolved, child: child);
  }
}

class _TiledPaper extends StatefulWidget {
  const _TiledPaper({required this.pattern, required this.child});

  final PaperNotebookPattern pattern;
  final Widget child;

  @override
  State<_TiledPaper> createState() => _TiledPaperState();
}

class _TiledPaperState extends State<_TiledPaper> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _info;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _TiledPaper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pattern != widget.pattern) _resolve();
  }

  @override
  void dispose() {
    _detach();
    _info?.dispose();
    super.dispose();
  }

  void _detach() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  void _resolve() {
    final provider = widget.pattern.imageFor(Theme.of(context).brightness);
    _detach();
    if (provider == null) {
      if (_info != null) {
        _info?.dispose();
        _info = null;
        if (mounted) setState(() {});
      }
      return;
    }
    final stream = provider.resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener(_onImage);
    _stream = stream;
    stream.addListener(_listener!);
  }

  void _onImage(ImageInfo info, bool synchronousCall) {
    final previous = _info;
    _info = info;
    previous?.dispose();
    if (!synchronousCall && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaperTilePainter(
        color: widget.pattern.fallbackColor(Theme.of(context).brightness),
        tile: _info?.image,
        tileScale: PaperNotebookPattern.tileScale,
      ),
      child: widget.child,
    );
  }
}

class _PaperTilePainter extends CustomPainter {
  const _PaperTilePainter({
    required this.color,
    required this.tile,
    required this.tileScale,
  });

  final Color color;
  final ui.Image? tile;
  final double tileScale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final image = tile;
    if (image == null || size.isEmpty) return;
    final dstW = image.width / tileScale;
    final dstH = image.height / tileScale;
    if (dstW < 1 || dstH < 1) return;
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (var y = 0.0; y < size.height; y += dstH) {
      for (var x = 0.0; x < size.width; x += dstW) {
        canvas.drawImageRect(image, src, Rect.fromLTWH(x, y, dstW, dstH), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTilePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.tile != tile ||
        oldDelegate.tileScale != tileScale;
  }
}
