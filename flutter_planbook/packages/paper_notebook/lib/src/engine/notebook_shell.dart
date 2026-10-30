import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:paper_notebook/src/engine/turnable_paper_flip.dart';
import 'package:paper_notebook/src/layout/notebook_format.dart';
import 'package:paper_notebook/src/paper_notebook_cover.dart';
import 'package:paper_notebook/src/paper_notebook_cover_style.dart';
import 'package:paper_notebook/src/paper_notebook_scope.dart';
import 'package:paper_notebook/src/paper_notebook_style.dart';
import 'package:paper_notebook/src/paper_notebook_theme.dart';

/// 皮革笔记本：合上按双页画布缩放居中；打开落定后放大右页铺满屏幕。
/// 合上时右扇牛皮纸是封面；打开动画作用在这一扇上。
class NotebookShell extends StatefulWidget {
  const NotebookShell({
    required this.child,
    this.cover,
    this.coverBuilder,
    this.coverClosed = false,
    this.coverGesturesEnabled = false,
    this.controller,
    this.onCoverOpened,
    this.onCoverClosed,
    super.key,
  });

  final Widget child;
  final Widget? cover;
  final Widget Function(BuildContext context)? coverBuilder;
  final bool coverClosed;
  final bool coverGesturesEnabled;
  final CoverTurnController? controller;
  final VoidCallback? onCoverOpened;
  final VoidCallback? onCoverClosed;

  static const canvasKey = Key('book-a4-canvas');
  static const viewportKey = Key('book-a4-viewport');
  static const frontCoverKey = Key('book-front-cover');
  static const coverInsideKey = Key('book-cover-inside-page');
  static const openShiftKey = Key('book-notebook-open-shift');
  static const landedCoverKey = Key('book-landed-cover');
  static const coverBackgroundKey = Key('book-cover-background');

  /// 封面从合上翻到摊在左边（180°）。90° 出现在进度一半，之后才露出左页。
  static const openAngle = math.pi;

  @override
  State<NotebookShell> createState() => _NotebookShellState();
}

class CoverTurnController {
  _NotebookShellState? _state;

  void _attach(_NotebookShellState state) => _state = state;

  /// 被替换掉的 state 要到帧末才 dispose，那时新 state 已经接上了。
  /// 只有还挂着自己时才摘，否则会把新 state 抹成 null。
  void _detach(_NotebookShellState state) {
    if (identical(_state, state)) _state = null;
  }

  Future<void> open() {
    final state = _state;
    if (state == null) return Future.value();
    return state._playOpen(state._style.coverOpen);
  }

  Future<void> close() {
    final state = _state;
    if (state == null) return Future.value();
    return state._playClose(state._style.coverClose);
  }

  bool get isAnimating => _state?._isBusy ?? false;
}

class _NotebookShellState extends State<NotebookShell>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _zoom;
  var _commitOpen = false;
  var _commitClose = false;
  var _dragging = false;
  Offset? _pointerStart;

  bool get _hasCover => widget.cover != null || widget.coverBuilder != null;

  bool get _isBusy => _controller.isAnimating || _zoom.isAnimating || _dragging;

  PaperNotebookStyle get _style => PaperNotebookScope.styleOf(context);

  double get _closedValue => widget.coverClosed && _hasCover ? 0.0 : 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      value: _closedValue,
    );
    _zoom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: _closedValue,
    );
    widget.controller?._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final style = _style;
    _controller.duration = style.coverOpen;
    _zoom.duration = style.pageFill;
  }

  @override
  void didUpdateWidget(covariant NotebookShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (!_hasCover) {
      _controller.value = 1;
      _zoom.value = 1;
      return;
    }
    if (oldWidget.coverClosed != widget.coverClosed &&
        !_controller.isAnimating &&
        !_zoom.isAnimating &&
        !_dragging) {
      _controller.value = widget.coverClosed ? 0 : 1;
      _zoom.value = widget.coverClosed ? 0 : 1;
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _controller.dispose();
    _zoom.dispose();
    super.dispose();
  }

  Future<void> _playOpen(Duration duration) async {
    if (!mounted || !_hasCover) return;
    final fillOpened = _style.fillOpenedView;
    if (_controller.value >= 0.999 && (!fillOpened || _zoom.value >= 0.999)) {
      return;
    }
    _commitOpen = true;
    _commitClose = false;
    _dragging = false;
    _pointerStart = null;
    if (_controller.value < 0.999) {
      _controller.duration = duration;
      await _controller.forward();
    }
    if (!mounted || !_commitOpen) return;
    if (fillOpened && _zoom.value < 0.999) {
      _zoom.duration = _style.pageFill;
      await _zoom.forward();
    }
    if (!mounted || !_commitOpen) return;
    _commitOpen = false;
    widget.onCoverOpened?.call();
  }

  Future<void> _playClose(Duration duration) async {
    if (!mounted || !_hasCover) return;
    if (_controller.value <= 0.001 && _zoom.value <= 0.001) return;
    _commitClose = true;
    _commitOpen = false;
    _dragging = false;
    _pointerStart = null;
    if (_zoom.value > 0.001) {
      _zoom.duration = _style.pageFill;
      await _zoom.reverse();
    }
    if (!mounted || !_commitClose) return;
    if (_controller.value > 0.001) {
      _controller.duration = duration;
      await _controller.reverse();
    }
    if (!mounted || !_commitClose) return;
    _commitClose = false;
    widget.onCoverClosed?.call();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.coverGesturesEnabled ||
        !_hasCover ||
        _controller.isAnimating ||
        _zoom.isAnimating ||
        _controller.value > 0.02) {
      return;
    }
    _commitOpen = false;
    _commitClose = false;
    _dragging = true;
    _pointerStart = details.localPosition;
    _controller.duration = _style.coverClose;
    _controller.value = 0.001;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    final format = PaperNotebookScope.formatOf(context);
    final start = _pointerStart ?? details.localPosition;
    final delta = start.dx - details.localPosition.dx;
    _controller.value = (delta / format.frontCoverWidth).clamp(0.001, 0.99);
  }

  void _onPanEnd(DragEndDetails details) {
    _finishPan(details.velocity.pixelsPerSecond.dx);
  }

  void _onPanCancel() {
    _finishPan(0, cancelled: true);
  }

  void _finishPan(double vx, {bool cancelled = false}) {
    if (!_dragging) return;
    _dragging = false;
    _pointerStart = null;
    final t = _controller.value;
    final fling = vx < -800;
    final complete = !cancelled && (t >= 0.32 || (fling && t >= 0.16));
    final remaining = complete ? 1 - t : t;
    final settleMs = _style.coverClose.inMilliseconds;
    final ms = (settleMs * remaining.clamp(0.35, 1.0)).round().clamp(
      220,
      settleMs,
    );
    final duration = Duration(milliseconds: ms);
    if (complete) {
      _commitOpen = true;
      _controller
          .animateTo(1, duration: duration, curve: Curves.easeInOutCubic)
          .whenComplete(() {
            if (!mounted || !_commitOpen) return;
            if (!_style.fillOpenedView) {
              _commitOpen = false;
              widget.onCoverOpened?.call();
              return;
            }
            _zoom.duration = _style.pageFill;
            _zoom.forward().whenComplete(() {
              if (!mounted || !_commitOpen) return;
              _commitOpen = false;
              widget.onCoverOpened?.call();
            });
          });
    } else {
      _commitOpen = false;
      _zoom.value = 0;
      _controller.animateBack(
        0,
        duration: duration,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = PaperNotebookScope.formatOf(context);
    final palette = PaperNotebookScope.themeOf(
      context,
    ).paletteFor(Theme.of(context).brightness);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fillOpened = format.style.fillOpenedView;
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: Listenable.merge([_controller, _zoom]),
          builder: (context, _) {
            final t = _hasCover ? _controller.value : 1.0;
            final zoom = !_hasCover
                ? (fillOpened ? 1.0 : 0.0)
                : (fillOpened ? _zoom.value : 0.0);
            final spreadScale = format.fitScale(constraints.biggest);
            final pageScale = format.fitRightPageScale(constraints.biggest);
            final scale = spreadScale + (pageScale - spreadScale) * zoom;
            final viewW = format.viewWidth * scale;
            final viewH = format.designHeight * scale;
            return Align(
              alignment: Alignment.center,
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                alignment: Alignment.center,
                child: SizedBox(
                  key: NotebookShell.viewportKey,
                  width: viewW,
                  height: viewH,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    clipBehavior: Clip.none,
                    child: SizedBox(
                      key: NotebookShell.canvasKey,
                      width: format.designWidth,
                      height: format.designHeight,
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          size: format.size,
                          padding: EdgeInsets.zero,
                          viewPadding: EdgeInsets.zero,
                          viewInsets: EdgeInsets.zero,
                        ),
                        child: _NotebookCanvas(
                          t: t,
                          zoom: zoom,
                          format: format,
                          cover: widget.cover,
                          coverBuilder: widget.coverBuilder,
                          palette: palette,
                          dark: dark,
                          coverGesturesEnabled: widget.coverGesturesEnabled,
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          onPanCancel: _onPanCancel,
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NotebookCanvas extends StatelessWidget {
  const _NotebookCanvas({
    required this.t,
    required this.zoom,
    required this.format,
    required this.cover,
    this.coverBuilder,
    required this.palette,
    required this.dark,
    required this.coverGesturesEnabled,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
    required this.child,
  });

  final double t;
  final double zoom;
  final NotebookFormat format;
  final Widget? cover;
  final Widget Function(BuildContext context)? coverBuilder;
  final PaperNotebookPalette palette;
  final bool dark;
  final bool coverGesturesEnabled;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final GestureDragCancelCallback onPanCancel;
  final Widget child;

  Widget _buildCover(BuildContext context) {
    // 封面是固定比例的装饰，正文则保留分页时使用的系统字号。
    return MediaQuery.withNoTextScaling(
      child: Builder(
        builder: (context) =>
            coverBuilder?.call(context) ?? cover ?? const PaperNotebookCover(),
      ),
    );
  }

  Widget _coverFace({
    required BuildContext context,
    required BorderRadius corners,
    required Widget child,
  }) {
    final theme = PaperNotebookScope.themeOf(context);
    return _CoverFace(
      leather: palette.leather,
      edge: palette.leatherEdge,
      pageEdge: palette.pageEdge,
      texture: theme.texture,
      corners: corners,
      background: theme.coverBackground,
      onCover: theme.onCover,
      child: child,
    );
  }

  bool get _hasCover => cover != null || coverBuilder != null;

  @override
  Widget build(BuildContext context) {
    final leatherSheet = Padding(
      padding: format.leatherInsets,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(format.leatherRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.45 : 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _LeatherCoverPainter(
              leather: palette.leather,
              edge: palette.leatherEdge,
              pageEdge: palette.pageEdge,
              texture: PaperNotebookScope.themeOf(context).texture,
              corners: BorderRadius.circular(format.leatherRadius),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    if (!_hasCover) {
      return Transform.translate(
        key: NotebookShell.openShiftKey,
        offset: Offset(format.openShiftX(1, zoom), 0),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [leatherSheet, child],
        ),
      );
    }
    final angle = t * NotebookShell.openAngle;
    final showInsidePage = angle >= math.pi / 2;
    final settle = t >= 0.92;
    final fade = settle ? ((1 - t) / 0.08).clamp(0.0, 1.0) : 1.0;
    final showCover = fade > 0.001;
    final canSplitCover = coverBuilder != null;
    final landedOpacity = canSplitCover
        ? (settle ? 1 - fade : 0.0)
        : (showCover ? 0.0 : 1.0);
    final landedRadius = BorderRadius.only(
      topLeft: Radius.circular(format.leatherRadius),
      bottomLeft: Radius.circular(format.leatherRadius),
    );
    final hasCoverImage =
        PaperNotebookScope.themeOf(context).coverBackground != null;
    final spread = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        leatherSheet,
        // 始终保留落地封面的槽位。若在动画末段才把它插到 child 前面，
        // Flutter 会把纸页误认为换了位置并卸载重建，页面就会闪一下。
        Positioned(
          left: format.backCoverLeft,
          top: format.frontCoverTop,
          width: format.frontCoverWidth,
          height: format.frontCoverHeight,
          child: IgnorePointer(
            child: landedOpacity <= 0.001
                ? const SizedBox.expand()
                : Opacity(
                    opacity: landedOpacity,
                    child: ClipRRect(
                      key: NotebookShell.landedCoverKey,
                      borderRadius: landedRadius,
                      child: PaperNotebookCoverHinge(
                        onRight: true,
                        child: hasCoverImage
                            ? _coverFace(
                                context: context,
                                corners: landedRadius,
                                child: _buildCover(context),
                              )
                            : _buildCover(context),
                      ),
                    ),
                  ),
          ),
        ),
        child,
      ],
    );
    // 打开过程中左页只画在封面内侧一起转；静止左页等到封面落定再露，避免 90° 突然蹦出来。
    // ClipRect 也必须常驻；动画末段从 ClipRect 换成裸 Stack 同样会重建纸页。
    final spreadLayer = ClipRect(
      clipper: _SpreadClipper(settle ? null : format.pageLeft),
      child: spread,
    );
    return Transform.translate(
      key: NotebookShell.openShiftKey,
      offset: Offset(format.openShiftX(t, zoom), 0),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          spreadLayer,
          if (showCover)
            Positioned(
              left: format.frontCoverLeft,
              top: format.frontCoverTop,
              width: format.frontCoverWidth,
              height: format.frontCoverHeight,
              child: Opacity(
                opacity: fade,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: coverGesturesEnabled
                      ? onPanStart
                      : null,
                  onHorizontalDragUpdate: coverGesturesEnabled
                      ? onPanUpdate
                      : null,
                  onHorizontalDragEnd: coverGesturesEnabled ? onPanEnd : null,
                  onHorizontalDragCancel: coverGesturesEnabled
                      ? onPanCancel
                      : null,
                  child: _FrontCoverFlap(
                    angle: angle,
                    showInsidePage: showInsidePage,
                    format: format,
                    palette: palette,
                    dark: dark,
                    cover: _buildCover(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FrontCoverFlap extends StatelessWidget {
  const _FrontCoverFlap({
    required this.angle,
    required this.showInsidePage,
    required this.format,
    required this.palette,
    required this.dark,
    required this.cover,
  });

  final double angle;
  final bool showInsidePage;
  final NotebookFormat format;
  final PaperNotebookPalette palette;
  final bool dark;
  final Widget cover;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topRight: Radius.circular(format.leatherRadius),
      bottomRight: Radius.circular(format.leatherRadius),
    );
    // 135°→180° 收透视和扇形阴影，落定前已经是平面，避免换成静止左叶时顿一下。
    final land = ((angle / math.pi - 0.75) / 0.25).clamp(0.0, 1.0);
    final perspective = angle <= 0 || land >= 1 ? 0.0 : 0.00085 * (1 - land);
    final edge = BookVersoLeaf.edgeColor(Theme.of(context).brightness);
    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, perspective)
        ..rotateY(angle),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha:
                    (dark ? 0.5 : 0.28) * (angle == 0 ? 0.35 : 1) * (1 - land),
              ),
              blurRadius: 18,
              offset: Offset(-6 * math.sin(angle.clamp(0, math.pi / 2)), 8),
            ),
          ],
        ),
        child: ClipPath(
          key: NotebookShell.frontCoverKey,
          clipper: _CoverFlapClipper(leatherRadius: format.leatherRadius),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              _CoverFace(
                leather: palette.leather,
                edge: palette.leatherEdge,
                pageEdge: palette.pageEdge,
                texture: PaperNotebookScope.themeOf(context).texture,
                corners: radius,
                background: PaperNotebookScope.themeOf(context).coverBackground,
                onCover: PaperNotebookScope.themeOf(context).onCover,
                child: cover,
              ),
              if (showInsidePage)
                Positioned(
                  left: BookVersoLeaf.coverInsideLeft,
                  top: format.leatherPeekTop,
                  width: BookVersoLeaf.stackWidthOf(format),
                  height: format.pageHeight,
                  child: BookVersoPage(
                    key: NotebookShell.coverInsideKey,
                    edge: edge,
                    spineOnLeft: true,
                  ),
                ),
              Offstage(
                offstage: angle <= 0,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 8,
                    child: ColoredBox(
                      color: Colors.black.withValues(
                        alpha:
                            (0.18 +
                                0.4 * math.sin(angle.clamp(0, math.pi / 2))) *
                            (1 - land),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverFace extends StatelessWidget {
  const _CoverFace({
    required this.leather,
    required this.edge,
    required this.pageEdge,
    required this.texture,
    required this.corners,
    required this.child,
    this.background,
    this.onCover,
  });

  final Color leather;
  final Color edge;
  final Color pageEdge;
  final PaperNotebookCoverTexture texture;
  final BorderRadius corners;
  final ImageProvider? background;
  final Color? onCover;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: corners,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (background != null)
            DecoratedBox(
              key: NotebookShell.coverBackgroundKey,
              decoration: BoxDecoration(
                color: leather,
                image: DecorationImage(image: background!, fit: BoxFit.cover),
              ),
            ),
          CustomPaint(
            painter: _LeatherCoverPainter(
              leather: leather,
              edge: edge,
              pageEdge: pageEdge,
              texture: texture,
              corners: corners,
              skipFill: background != null,
              onCover: onCover,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SpreadClipper extends CustomClipper<Rect> {
  const _SpreadClipper(this.left);

  final double? left;

  @override
  Rect getClip(Size size) {
    final clipLeft = left;
    if (clipLeft != null) {
      return Rect.fromLTRB(clipLeft, 0, size.width, size.height);
    }
    // 落定后等价于“不裁剪”，并给翻页纸角留下足够的越界绘制空间。
    return Rect.fromLTRB(
      -size.width * 4,
      -size.height * 4,
      size.width * 5,
      size.height * 5,
    );
  }

  @override
  bool shouldReclip(covariant _SpreadClipper oldClipper) {
    return oldClipper.left != left;
  }
}

class _CoverFlapClipper extends CustomClipper<Path> {
  const _CoverFlapClipper({required this.leatherRadius});

  final double leatherRadius;

  @override
  Path getClip(Size size) {
    final rect = Rect.fromLTWH(
      BookVersoLeaf.coverInsideLeft,
      0,
      size.width - BookVersoLeaf.coverInsideLeft,
      size.height,
    );
    return Path()..addRRect(
      RRect.fromRectAndCorners(
        rect,
        topRight: Radius.circular(leatherRadius),
        bottomRight: Radius.circular(leatherRadius),
      ),
    );
  }

  @override
  bool shouldReclip(covariant _CoverFlapClipper oldClipper) {
    return oldClipper.leatherRadius != leatherRadius;
  }
}

class _LeatherCoverPainter extends CustomPainter {
  const _LeatherCoverPainter({
    required this.leather,
    required this.edge,
    required this.pageEdge,
    required this.texture,
    required this.corners,
    this.skipFill = false,
    this.onCover,
  });

  final Color leather;
  final Color edge;
  final Color pageEdge;
  final PaperNotebookCoverTexture texture;
  final BorderRadius corners;
  final bool skipFill;
  final Color? onCover;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = corners.toRRect(rect);
    canvas.save();
    canvas.clipRRect(rrect);
    if (!skipFill) {
      canvas.drawRect(rect, Paint()..color = leather);
    }
    final bare = !skipFill && texture == PaperNotebookCoverTexture.none;
    final lightCover = skipFill
        ? (onCover ?? Colors.white).computeLuminance() < 0.5
        : leather.computeLuminance() > 0.5;
    if (!skipFill && !bare) {
      // 素面只用缎面高光；其余材质先叠体积渐变再画纹理。
      if (texture != PaperNotebookCoverTexture.smooth) {
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: lightCover
                  ? [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.05),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.22),
                    ],
              stops: const [0, 0.45, 1],
            ).createShader(rect),
        );
      }
      _paintTexture(canvas, size);
    }
    final spineAlpha = bare
        ? (lightCover ? 0.04 : 0.12)
        : (lightCover ? 0.12 : 0.38);
    final spineMid = bare
        ? (lightCover ? 0.015 : 0.04)
        : (lightCover ? 0.04 : 0.12);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 28, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withValues(alpha: spineAlpha),
            Colors.black.withValues(alpha: spineMid),
            Colors.transparent,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromLTWH(0, 0, 28, size.height)),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - 28, 0, 28, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Colors.black.withValues(alpha: spineAlpha),
            Colors.black.withValues(alpha: spineMid),
            Colors.transparent,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromLTWH(size.width - 28, 0, 28, size.height)),
    );
    for (final x in [8.0, 5.5, size.width - 8.0, size.width - 5.5]) {
      final outer = x == 8.0 || x == size.width - 8.0;
      canvas.drawLine(
        Offset(x, 16),
        Offset(x, size.height - 16),
        Paint()
          ..color = pageEdge.withValues(alpha: outer ? 0.7 : 0.4)
          ..strokeWidth = 1.2,
      );
    }
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  void _paintTexture(Canvas canvas, Size size) {
    final light = leather.computeLuminance() > 0.5;
    switch (texture) {
      case PaperNotebookCoverTexture.none:
        return;
      case PaperNotebookCoverTexture.smooth:
        _paintSmooth(canvas, Offset.zero & size);
      case PaperNotebookCoverTexture.leather:
        _paintLeather(canvas, size, light);
      case PaperNotebookCoverTexture.kraft:
        _paintKraft(canvas, size, light);
      case PaperNotebookCoverTexture.cloth:
        _paintCloth(canvas, size, light);
    }
  }

  /// 素面：对角缎面高光，无颗粒。
  void _paintSmooth(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-1, -0.85),
          end: const Alignment(0.75, 1),
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.1),
          ],
          stops: const [0, 0.38, 0.72, 1],
        ).createShader(rect),
    );
  }

  /// 皮革：粗荔枝纹，错位卵石。
  void _paintLeather(Canvas canvas, Size size, bool light) {
    final pit = Paint()
      ..color = Colors.black.withValues(alpha: light ? 0.11 : 0.18);
    final gleam = Paint()
      ..color = Colors.white.withValues(alpha: light ? 0.16 : 0.1);
    const step = 7.0;
    for (var row = 0.0, y = 0.0; y < size.height; y += step, row++) {
      final stagger = row.toInt().isOdd ? step * 0.5 : 0.0;
      for (var x = -stagger; x < size.width; x += step) {
        final n = _hash(x.toInt(), y.toInt());
        if (n < 0.1) continue;
        final center = Offset(x + n * 2.2, y + (1 - n) * 2.0);
        final r = 1.9 + n * 1.6;
        canvas.drawOval(
          Rect.fromCenter(center: center, width: r * 1.45, height: r * 1.05),
          pit,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(-r * 0.24, -r * 0.26),
            width: r * 0.62,
            height: r * 0.42,
          ),
          gleam,
        );
      }
    }
  }

  /// 牛皮纸：暖色纸屑 + 斜向长纤维。
  void _paintKraft(Canvas canvas, Size size, bool light) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = const Color(
          0xFF8B6914,
        ).withValues(alpha: light ? 0.05 : 0.08),
    );
    final fleckDark = Paint()
      ..color = const Color(0xFF5C4630).withValues(alpha: light ? 0.16 : 0.22);
    final fleckLight = Paint()
      ..color = const Color(0xFFE8D4B0).withValues(alpha: light ? 0.2 : 0.12);
    const speck = 5.2;
    for (var y = 0.0; y < size.height; y += speck) {
      for (var x = 0.0; x < size.width; x += speck) {
        final n = _hash(x.toInt() * 3, y.toInt());
        if (n < 0.4) continue;
        canvas.drawCircle(
          Offset(x + n * 2.2, y + (1 - n) * 2.2),
          0.7 + n * 1.2,
          n > 0.76 ? fleckLight : fleckDark,
        );
      }
    }
    final fiber = Paint()
      ..color = const Color(0xFF6A5136).withValues(alpha: light ? 0.12 : 0.16)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    for (var y = 9.0; y < size.height; y += 14) {
      var x = 0.0;
      var i = 0;
      while (x < size.width) {
        final n = _hash(i * 19, y.toInt());
        final len = 14 + n * 22;
        canvas.drawLine(
          Offset(x, y + n * 1.4),
          Offset(x + len, y + (n - 0.5) * 3.6),
          fiber,
        );
        x += len + 8 + n * 12;
        i++;
      }
    }
  }

  /// 布面：粗亚麻经纬，与纸屑颗粒明显不同。
  void _paintCloth(Canvas canvas, Size size, bool light) {
    const step = 6.5;
    final warp = Paint()
      ..color = Colors.black.withValues(alpha: light ? 0.1 : 0.16)
      ..strokeWidth = 1.05;
    final weft = Paint()
      ..color = Colors.white.withValues(alpha: light ? 0.14 : 0.09)
      ..strokeWidth = 0.95;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), warp);
      canvas.drawLine(Offset(x + 1.8, 0), Offset(x + 1.8, size.height), weft);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), warp);
      canvas.drawLine(Offset(0, y + 1.8), Offset(size.width, y + 1.8), weft);
    }
  }

  @override
  bool shouldRepaint(covariant _LeatherCoverPainter oldDelegate) {
    return oldDelegate.leather != leather ||
        oldDelegate.edge != edge ||
        oldDelegate.pageEdge != pageEdge ||
        oldDelegate.texture != texture ||
        oldDelegate.corners != corners ||
        oldDelegate.skipFill != skipFill ||
        oldDelegate.onCover != onCover;
  }
}

double _hash(int x, int y) {
  var n = x * 374761393 + y * 668265263;
  n = (n ^ (n >> 13)) * 1274126177;
  return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0;
}
