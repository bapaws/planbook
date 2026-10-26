import 'package:flutter/material.dart';
import 'package:paper_notebook/src/engine/page_fold_geometry.dart';
import 'package:paper_notebook/src/engine/turnable_paper_flip.dart';
import 'package:paper_notebook/src/layout/notebook_format.dart';
import 'package:paper_notebook/src/paper_notebook_pattern.dart';
import 'package:paper_notebook/src/paper_notebook_scope.dart';
import 'package:paper_notebook/src/paper_notebook_style.dart';
import 'package:paper_notebook/src/paper_notebook_surface.dart';

/// 翻页：双页全开时右页有内容，左页是空白纸背；
/// 往回翻是把左堆上的那页再翻回来（正向折页倒放），不是从左边缘掀起。
/// 封面开合在 [NotebookShell] 的牛皮纸右扇上，不走纸页。
class PaperPageTurn extends StatefulWidget {
  const PaperPageTurn({
    required this.current,
    required this.next,
    required this.previous,
    required this.onForward,
    required this.onBack,
    this.gesturesEnabled = true,
    this.closesCoverOnBack = false,
    this.closesCoverOnForward = false,
    this.onCloseCover,
    this.onAnimationChanged,
    this.controller,
    super.key,
  });

  final Widget current;
  final Widget next;
  final Widget previous;
  final VoidCallback onForward;
  final VoidCallback onBack;
  final bool gesturesEnabled;

  /// 第一页再往回翻：左侧拖动合上牛皮纸，不走纸折页。
  final bool closesCoverOnBack;

  /// 最后一页再往前翻：右侧拖动合上牛皮纸，不走纸折页。
  final bool closesCoverOnForward;
  final VoidCallback? onCloseCover;

  /// 手势开始、翻页完成和回弹取消后通知外部重新读取动画状态。
  final VoidCallback? onAnimationChanged;
  final PaperPageTurnController? controller;

  /// 折瓣会画出纸页，画布四周留出余量以免被裁掉。
  static const foldOverflow = 420.0;

  /// 超过这个进度才翻到下一页；否则弹回。
  /// 进度按两倍页宽计算，0.19 约等于拖过页面宽度的 38%。
  static const commitThreshold = 0.19;

  /// 快速甩动时也要先翻过这么多，才算翻页。
  /// 0.07 约等于页面宽度的 14%，避免轻微横移误触。
  static const flingThreshold = 0.07;

  /// 真机上容易达到、同时能过滤普通点击抖动的水平甩动速度。
  static const flingVelocity = 650.0;

  /// 自动翻页时页角抬起的高度（占页高的比例），折痕靠它才有倾斜。
  static const autoFoldTilt = 0.3;

  /// 自动翻页的速度曲线：起手快、落定缓，别像匀速推格子。
  static const autoFoldCurve = Curves.easeOutCubic;

  @override
  State<PaperPageTurn> createState() => _PaperPageTurnState();
}

class PaperPageTurnController {
  _PaperPageTurnState? _state;

  void _attach(_PaperPageTurnState state) => _state = state;

  /// 被替换掉的 state 要到帧末才 dispose，那时新 state 已经接上了。
  /// 所以只有还挂着自己时才摘，否则会把新 state 抹成 null，
  /// 之后 [playForward] / [playBack] 全部变成空操作。
  void _detach(_PaperPageTurnState state) {
    if (identical(_state, state)) _state = null;
  }

  Future<void> playForward([Duration? duration]) {
    final state = _state;
    if (state == null) return Future.value();
    return state._playForward(duration ?? state._style.pageTurn);
  }

  Future<void> playRitualForward() {
    final state = _state;
    if (state == null) return Future.value();
    return state._playForward(state._style.coverOpen);
  }

  Future<void> playBack([Duration? duration]) {
    final state = _state;
    if (state == null) return Future.value();
    return state._playBack(duration ?? state._style.pageTurn);
  }

  bool get isAnimating => _state?._isBusy ?? false;
}

enum _TurnCommit { none, forward, back }

class _PaperPageTurnState extends State<PaperPageTurn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _forward = true;
  var _busy = false;
  var _dragging = false;
  var _commit = _TurnCommit.none;
  PageFoldCorner _corner = PageFoldCorner.bottomRight;
  Offset? _origin;
  Offset? _grab;
  Offset? _pointerStart;
  Offset? _settleFromGrab;
  var _settleFromT = 0.0;
  var _settleToT = 1.0;
  var _coverCloseDrag = false;
  var _coverCloseForward = false;
  var _coverCloseDx = 0.0;

  PaperNotebookStyle get _style => PaperNotebookScope.styleOf(context);

  bool get _isBusy => _controller.isAnimating || _dragging || _busy;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _controller.addStatusListener(_onStatus);
    widget.controller?._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = _style.pageTurn;
  }

  @override
  void didUpdateWidget(covariant PaperPageTurn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (!identical(oldWidget.current, widget.current)) {
      _commit = _TurnCommit.none;
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  void _resetGrab() {
    _dragging = false;
    _origin = null;
    _grab = null;
    _pointerStart = null;
    _settleFromGrab = null;
    _coverCloseDrag = false;
    _coverCloseForward = false;
    _coverCloseDx = 0;
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _resetGrab();
      if (!_busy) widget.onAnimationChanged?.call();
      return;
    }
    if (status != AnimationStatus.completed || _busy) return;
    if (_controller.value < 0.999) {
      _resetGrab();
      return;
    }
    _busy = true;
    final forward = _forward;
    _commit = forward ? _TurnCommit.forward : _TurnCommit.back;
    if (forward) {
      widget.onForward();
    } else {
      widget.onBack();
    }
    _controller.reset();
    _resetGrab();
    _busy = false;
    // 页码回调执行时仍处于 busy；必须在全部清理后再通知等待合书的调用方。
    widget.onAnimationChanged?.call();
  }

  Future<void> _playForward(Duration duration) async {
    if (!mounted) return;
    _forward = true;
    _corner = PageFoldCorner.bottomRight;
    _resetGrab();
    _controller.value = 0;
    await _controller.animateTo(
      1,
      duration: duration,
      curve: PaperPageTurn.autoFoldCurve,
    );
  }

  Future<void> _playBack(Duration duration) async {
    if (!mounted) return;
    _forward = false;
    _corner = PageFoldCorner.bottomRight;
    _resetGrab();
    _controller.value = 0.001;
    await _controller.animateTo(
      1,
      duration: duration,
      curve: PaperPageTurn.autoFoldCurve,
    );
  }

  Size _boxSize() {
    final box = context.findRenderObject() as RenderBox?;
    return box?.size ?? Size.zero;
  }

  _BookFrame _frame(Size _) => _BookFrame(PaperNotebookScope.formatOf(context));

  Offset _rightOrigin(Size page, Offset pageLocal) {
    return pageFoldEdgeOrigin(size: page, local: pageLocal, forward: true);
  }

  Offset _restingLeftGrab(Size page, Offset origin) {
    return Offset(-page.width, origin.dy);
  }

  Offset _grabFromPointer(Size full, Offset local) {
    final frame = _frame(full);
    final start = _pointerStart ?? local;
    final origin = _origin ?? _rightOrigin(frame.page, frame.toPage(start));
    final delta = frame.toPage(local) - frame.toPage(start);
    if (_forward) return origin + delta;
    return _restingLeftGrab(frame.page, origin) + delta;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.gesturesEnabled || _controller.isAnimating) return;
    _commit = _TurnCommit.none;
    _settleFromGrab = null;
    final full = _boxSize();
    if (full.width < 8) return;
    final local = details.localPosition;
    final frame = _frame(full);
    final pageLocal = frame.toPage(local);
    final fromLeft = pageLocal.dx < frame.page.width * 0.45;
    if (fromLeft && widget.closesCoverOnBack) {
      _coverCloseDrag = true;
      _coverCloseForward = false;
      _pointerStart = local;
      _coverCloseDx = 0;
      _dragging = true;
      widget.onAnimationChanged?.call();
      return;
    }
    if (!fromLeft && widget.closesCoverOnForward) {
      _coverCloseDrag = true;
      _coverCloseForward = true;
      _pointerStart = local;
      _coverCloseDx = 0;
      _dragging = true;
      widget.onAnimationChanged?.call();
      return;
    }
    _forward = !fromLeft;
    _pointerStart = local;
    _origin = _rightOrigin(frame.page, pageLocal);
    _corner = PageFoldCorner.at(
      local: pageLocal,
      size: frame.page,
      forward: true,
    );
    _grab = _forward ? _origin : _restingLeftGrab(frame.page, _origin!);
    _dragging = true;
    _controller.duration = _style.pageTurn;
    _controller.value = 0.001;
    widget.onAnimationChanged?.call();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.gesturesEnabled || _controller.isAnimating || !_dragging) {
      return;
    }
    final full = _boxSize();
    final local = details.localPosition;
    final start = _pointerStart ?? local;
    final frame = _frame(full);
    if (_coverCloseDrag) {
      _coverCloseDx += details.delta.dx;
      return;
    }
    if (_controller.value <= 0.04) {
      final dx = local.dx - start.dx;
      if (dx.abs() > 6) {
        final forward = dx < 0;
        if (forward && widget.closesCoverOnForward) {
          _coverCloseDrag = true;
          _coverCloseForward = true;
          _controller.value = 0;
          return;
        }
        if (!forward && widget.closesCoverOnBack) {
          _coverCloseDrag = true;
          _coverCloseForward = false;
          _controller.value = 0;
          return;
        }
        if (forward != _forward) {
          _forward = forward;
          _origin = _rightOrigin(frame.page, frame.toPage(start));
          _corner = PageFoldCorner.at(
            local: frame.toPage(start),
            size: frame.page,
            forward: true,
          );
        }
      }
    }
    final origin = _origin ?? _rightOrigin(frame.page, frame.toPage(start));
    _grab = _grabFromPointer(full, local);
    final fold = PageFoldGeometry.fromPointer(
      size: frame.page,
      origin: origin,
      grab: _grab!,
      forward: true,
    );
    final foldT = fold?.progress ?? _progressOf(origin, _grab!, frame.page);
    final t = _forward ? foldT : 1 - foldT;
    _controller.value = t.clamp(0.001, 0.99);
  }

  void _onPanEnd(DragEndDetails details) {
    _finishPan(details.velocity.pixelsPerSecond.dx);
  }

  void _onPanCancel() {
    _finishPan(0, cancelled: true);
  }

  void _finishPan(double vx, {bool cancelled = false}) {
    if (!widget.gesturesEnabled || _controller.isAnimating || !_dragging) {
      return;
    }
    if (_coverCloseDrag) {
      final dx = _coverCloseDx;
      final fling = _coverCloseForward ? vx < -800 : vx > 800;
      final pulled = _coverCloseForward ? dx < -48 : dx > 48;
      final complete = !cancelled && (pulled || fling);
      _resetGrab();
      if (complete) widget.onCloseCover?.call();
      widget.onAnimationChanged?.call();
      return;
    }
    _dragging = false;
    final t = _controller.value;
    final fling = _forward
        ? vx < -PaperPageTurn.flingVelocity
        : vx > PaperPageTurn.flingVelocity;
    final complete =
        !cancelled &&
        (t >= PaperPageTurn.commitThreshold ||
            (fling && t >= PaperPageTurn.flingThreshold));
    _armSettleGrab(complete: complete, fromT: t);
    final remaining = complete ? 1 - t : t;
    final settleMs = _style.pageSettle.inMilliseconds;
    final minMs = complete ? 240 : 220;
    final ms = (settleMs * remaining.clamp(0.35, 1.0)).round().clamp(
      minMs,
      settleMs,
    );
    final duration = Duration(milliseconds: ms);
    if (complete) {
      _controller.animateTo(
        1,
        duration: duration,
        curve: Curves.easeInOutCubic,
      );
    } else {
      _controller.animateBack(
        0,
        duration: duration,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _armSettleGrab({required bool complete, required double fromT}) {
    if (_grab == null) {
      _settleFromGrab = null;
      return;
    }
    _settleFromGrab = _grab;
    _settleFromT = fromT;
    _settleToT = complete ? 1.0 : 0.0;
  }

  Offset? _grabFor(Size page, double t, Offset origin) {
    if (_dragging && _grab != null) return _grab;
    final from = _settleFromGrab;
    if (from == null) return _grab;
    final span = _settleToT - _settleFromT;
    final u = span.abs() < 1e-6
        ? 1.0
        : ((t - _settleFromT) / span).clamp(0.0, 1.0);
    return pageFoldSettleGrab(
      size: page,
      origin: origin,
      from: from,
      t: u,
      complete: _settleToT > 0.5,
      forward: _forward,
    );
  }

  double _progressOf(Offset origin, Offset grab, Size size) {
    final span = size.width * 2;
    if (span < 1) return 0;
    return ((origin.dx - grab.dx) / span).clamp(0.0, 1.0);
  }

  PageFoldGeometry? _foldFor(Size page, double t) {
    if (t <= 0) return null;
    final corner = _corner.forward ? _corner : PageFoldCorner.bottomRight;
    final origin =
        _origin ??
        pageFoldEdgeOrigin(
          size: page,
          local: corner.originOf(page),
          forward: true,
        );
    final grab = _grabFor(page, t, origin);
    if (grab != null) {
      return PageFoldGeometry.fromPointer(
        size: page,
        origin: origin,
        grab: grab,
        forward: true,
      );
    }
    return PageFoldGeometry.lerp(
      size: page,
      progress: _forward ? t.clamp(0.001, 0.999) : (1 - t).clamp(0.02, 0.999),
      forward: true,
      corner: corner,
      origin: origin,
      tilt: PaperPageTurn.autoFoldTilt,
    );
  }

  Key _pageKey(Widget page, String fallback) =>
      page.key ?? ValueKey<String>(fallback);

  Widget _paperStack({
    required Size page,
    required double t,
    required bool flipping,
  }) {
    final fold = _foldFor(page, t);
    final foldProgress = fold?.progress ?? t;
    final turningClip = paperFoldClipper(
      size: page,
      progress: foldProgress,
      forward: true,
      fold: fold,
    );
    final showNext = flipping && _forward && _commit == _TurnCommit.none;
    final restoring = flipping && !_forward && _commit == _TurnCommit.none;
    final previousLanded =
        restoring && (fold == null || fold.progress <= 0.06 || t >= 0.92);
    return Stack(
      fit: StackFit.expand,
      children: [
        _PageSlot(
          key: _pageKey(widget.next, 'next'),
          visible: showNext || _commit == _TurnCommit.forward,
          clipper: const FullPageClipper(),
          child: widget.next,
        ),
        _PageSlot(
          key: _pageKey(widget.current, 'current'),
          visible: _commit != _TurnCommit.forward,
          clipper: showNext ? turningClip : const FullPageClipper(),
          child: widget.current,
        ),
        _PageSlot(
          key: _pageKey(widget.previous, 'previous'),
          visible: restoring || _commit == _TurnCommit.back,
          clipper: _commit == _TurnCommit.back || previousLanded
              ? const FullPageClipper()
              : (fold == null ? const EmptyPageClipper() : turningClip),
          child: widget.previous,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final pattern = PaperNotebookScope.patternOf(context);
    final format = PaperNotebookScope.formatOf(context);
    final paper = pattern.fallbackColor(brightness);
    final edge = BookVersoLeaf.edgeColor(brightness);
    final pages = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return LayoutBuilder(
          builder: (context, _) {
            final flipping = t > 0;
            final frame = _BookFrame(format);
            final fold = flipping ? _foldFor(frame.page, t) : null;
            final landedBack =
                !_forward &&
                (fold == null || fold.progress <= 0.06 || t >= 0.92);
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: BookVersoLeaf.stackLeft(
                    frame.left,
                    format.leftLeafWidth,
                  ),
                  top: frame.top,
                  width: BookVersoLeaf.stackWidthOf(format),
                  height: frame.page.height,
                  child: BookVersoPage(
                    key: const Key('turned-page-back'),
                    edge: edge,
                  ),
                ),
                Positioned(
                  left: frame.left,
                  top: frame.top,
                  width: frame.page.width,
                  height: frame.page.height,
                  child: ClipRRect(
                    borderRadius: BookVersoLeaf.borderRadius(
                      spineOnLeft: true,
                      outerRadius: format.pageOuterRadius,
                      spineRadius: format.spineRadius,
                    ),
                    child: PaperNotebookSurface(
                      child: _paperStack(
                        page: frame.page,
                        t: t,
                        flipping: flipping,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -PaperPageTurn.foldOverflow,
                  top: -PaperPageTurn.foldOverflow,
                  right: -PaperPageTurn.foldOverflow,
                  bottom: -PaperPageTurn.foldOverflow,
                  child: IgnorePointer(
                    child: fold == null || landedBack
                        ? const SizedBox.expand()
                        : PaperFoldOverlay(
                            key: const Key('paper-fold-overlay'),
                            fold: fold,
                            progress: fold.progress,
                            paperColor: paper,
                            edgeColor: edge,
                            pageBorderRadius: BookVersoLeaf.borderRadius(
                              spineOnLeft: true,
                              outerRadius: format.pageOuterRadius,
                              spineRadius: format.spineRadius,
                            ),
                            tileAsset: pattern.hasTile
                                ? pattern.assetFor(brightness)
                                : null,
                            tilePackage: PaperNotebookPattern.packageName,
                            settleToLeft: _forward,
                            paintOrigin:
                                frame.origin +
                                const Offset(
                                  PaperPageTurn.foldOverflow,
                                  PaperPageTurn.foldOverflow,
                                ),
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // 手势开关切换时不能改变这棵子树的结构：换掉根节点会让三页内容整体重建，
    // 页面里的 bloc / 滚动位置全丢，看起来就像“刷新”了一次。
    final enabled = widget.gesturesEnabled;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: enabled ? _onPanStart : null,
      onHorizontalDragUpdate: enabled ? _onPanUpdate : null,
      onHorizontalDragEnd: enabled ? _onPanEnd : null,
      onHorizontalDragCancel: enabled ? _onPanCancel : null,
      child: pages,
    );
  }
}

class _PageSlot extends StatelessWidget {
  const _PageSlot({
    required super.key,
    required this.visible,
    required this.clipper,
    required this.child,
  });

  final bool visible;
  final CustomClipper<Path> clipper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Offstage 仍在树上，Hero 收集会扫到；不可见槽位关掉 HeroMode，
    // 否则邻页预挂与当前页若共享同一 tag（例如周志/日志同条目附件）会断言失败。
    return HeroMode(
      enabled: visible,
      child: TickerMode(
        enabled: visible,
        child: Offstage(
          offstage: !visible,
          child: ClipPath(
            clipper: clipper,
            child: RepaintBoundary(child: child),
          ),
        ),
      ),
    );
  }
}

/// 右页是内容页；左页是同宽空白纸，相对 [NotebookFormat.pageLeft] 落在书脊左侧。
class _BookFrame {
  const _BookFrame(this.format);

  final NotebookFormat format;

  double get left => format.pageLeft;
  double get top => format.pageTop;
  Size get page => format.pageSize;

  Offset get origin => Offset(left, top);

  Offset toPage(Offset local) => Offset(local.dx - left, local.dy - top);
}
