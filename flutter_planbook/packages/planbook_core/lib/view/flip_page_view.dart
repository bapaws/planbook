import 'dart:math' as math;

import 'package:flutter/material.dart';

enum FlipPageDirection {
  left(-1),
  right(1);

  const FlipPageDirection(this.value);

  final int value;
}

/// A controller for [FlipPageView] that allows programmatic control
/// of the current spread (page pair) being displayed.
///
/// The controller's [value] represents the current spread index.
/// Each spread consists of a left page (odd index) and a right page
/// (even index).
///
/// Unlike [PageController], this controller holds a direct reference
/// to the [FlipPageView]'s state, eliminating the need for multiple
/// callback layers.
class FlipPageController extends ValueNotifier<int> {
  FlipPageController({int initialPage = 0})
    : assert(
        initialPage >= 0,
        'initialPage must be greater than or equal to 0',
      ),
      super(initialPage);

  _FlipPageViewState? _state;

  bool get hasClients => _state != null;

  // ignore: use_setters_to_change_properties, lifecycle method
  void _attach(_FlipPageViewState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// Animates the [FlipPageView] to the given spread [page].
  Future<void> animateToPage(
    int page, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    return _state?._animateToPage(page, duration: duration, curve: curve) ??
        Future.value();
  }

  /// Jumps the [FlipPageView] to the given spread [page] without animation.
  void jumpToPage(int page) {
    _state?._jumpToPage(page);
  }

  /// Animates the [FlipPageView] to the next spread.
  Future<void> nextPage({
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    if (_state == null) return Future.value();
    final sc = _state!._spreadCount;
    final next = (value + 1) % sc;
    return animateToPage(next, duration: duration, curve: curve);
  }

  /// Animates the [FlipPageView] to the previous spread.
  Future<void> previousPage({
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    if (_state == null) return Future.value();
    final sc = _state!._spreadCount;
    final prev = (value - 1 + sc) % sc;
    return animateToPage(prev, duration: duration, curve: curve);
  }

  void _notifyPageChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}

/// A 3D book-style flip page view.
///
/// The [itemBuilder] is called with individual page indices where:
/// - **Even indices** (0, 2, 4, ...) produce **right-side** pages
/// - **Odd indices** (1, 3, 5, ...) produce **left-side** pages
///
/// For spread `s`, the right page index is `2*s` and the left page index
/// is `2*s + 1`. The [itemBuilder] should return properly sized widgets
/// for each page — no internal clipping or alignment is applied.
///
/// [itemsCount] is the total number of individual pages (should be even).
/// The number of spreads equals `itemsCount ~/ 2`.
class FlipPageView extends StatefulWidget {
  const FlipPageView({
    required this.itemBuilder,
    required this.itemsCount,
    required this.controller,
    this.spacing,
    this.borderRadius,
    super.key,
  });

  final int itemsCount;
  final IndexedWidgetBuilder itemBuilder;
  final FlipPageController controller;
  final double? spacing;

  /// Border radius applied to each page's outer edges.
  ///
  /// Left pages get rounded top-left and bottom-left corners;
  /// right pages get rounded top-right and bottom-right corners.
  final BorderRadius? borderRadius;

  @override
  State<FlipPageView> createState() => _FlipPageViewState();
}

class _FlipPageViewState extends State<FlipPageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int? _beforeDragIndex;
  double? _dragStartX;
  double _dragProgress = 0;
  double _leftAngle = -_defaultAngle;
  double _rightAngle = _defaultAngle;
  bool _isAnimating = false;

  static const _perspective = 0.0002;
  static const _zeroAngle = 0.0001;
  static const double _defaultAngle = math.pi / 6.5;
  static const double _maxAngle = math.pi / 2;

  int get _spreadCount => widget.itemsCount ~/ 2;

  int get _currentIndex => widget.controller.value;
  set _currentIndex(int value) {
    widget.controller.value = value;
  }

  int _leftPageOf(int spread) => 2 * spread + 1;
  int _rightPageOf(int spread) => 2 * spread;
  int _wrapSpread(int s) => (s % _spreadCount + _spreadCount) % _spreadCount;

  Widget _clipLeft(Widget child) {
    final br = widget.borderRadius;
    if (br == null) return ClipRect(child: child);
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: br.topLeft,
        bottomLeft: br.bottomLeft,
      ),
      child: child,
    );
  }

  Widget _clipRight(Widget child) {
    final br = widget.borderRadius;
    if (br == null) return ClipRect(child: child);
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topRight: br.topRight,
        bottomRight: br.bottomRight,
      ),
      child: child,
    );
  }

  void _updateAngles(double progress) {
    if (progress >= 0.5) {
      _leftAngle = -_defaultAngle;
      _rightAngle =
          _maxAngle - (progress - 0.5) * 2 * (_maxAngle - _defaultAngle);
    } else if (progress >= 0) {
      _leftAngle =
          -_defaultAngle - ((progress * 2) * (_maxAngle - _defaultAngle));
      _rightAngle = _defaultAngle;
    } else if (progress >= -0.5) {
      _leftAngle = -_defaultAngle;
      _rightAngle =
          _maxAngle - (progress + 0.5) * 2 * (_maxAngle - _defaultAngle);
    } else {
      _leftAngle =
          -_maxAngle - (progress + 0.5) * 2 * (_maxAngle - _defaultAngle);
      _rightAngle = _defaultAngle;
    }
  }

  void _onProgressUpdate(double progress) {
    _updateAngles(progress);

    final sc = _spreadCount;
    if (progress > 0.5) {
      _currentIndex = (_beforeDragIndex! - 1 + sc) % sc;
    } else if (progress < -0.5) {
      _currentIndex = (_beforeDragIndex! + 1) % sc;
    } else {
      _currentIndex = _beforeDragIndex!;
    }

    _dragProgress = progress;
    setState(() {});
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isAnimating) return;

    _dragStartX = details.globalPosition.dx;
    _leftAngle = -_defaultAngle;
    _rightAngle = _defaultAngle;
    _beforeDragIndex = _currentIndex;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_dragStartX == null || _beforeDragIndex == null || _isAnimating) return;

    final dragDistance = details.globalPosition.dx - _dragStartX!;
    final screenWidth = MediaQuery.of(context).size.width;
    final progress = (dragDistance / (screenWidth * 0.5)).clamp(-1.0, 1.0);
    _onProgressUpdate(progress);
  }

  Future<void> _onHorizontalDragEnd(DragEndDetails details) async {
    if (_dragStartX == null || _beforeDragIndex == null || _isAnimating) {
      return;
    }

    final velocity = details.velocity.pixelsPerSecond.dx;
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.15;

    final shouldComplete =
        _dragProgress.abs() > 0.3 ||
        (details.primaryVelocity?.abs() ?? 0) > threshold ||
        (velocity.abs() > 500 && (velocity > 0) == (_dragProgress > 0));

    _isAnimating = true;
    _controller.reset();

    final tween = Tween<double>(begin: 0, end: 1);
    final animation = tween.animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    void animationListener() {
      final progress = _dragProgress > 0 ? animation.value : -animation.value;
      _onProgressUpdate(progress);
    }

    animation.addListener(animationListener);

    if (shouldComplete) {
      await _controller.forward(from: _dragProgress.abs());
    } else {
      await _controller.reverse(from: _dragProgress.abs());
    }

    animation.removeListener(animationListener);
    _resetDragState();
    widget.controller._notifyPageChanged();
    setState(() {});
  }

  void _resetDragState() {
    _leftAngle = -_defaultAngle;
    _rightAngle = _defaultAngle;
    _dragProgress = 0;
    _dragStartX = null;
    _beforeDragIndex = null;
    _isAnimating = false;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    widget.controller._attach(this);
  }

  @override
  void didUpdateWidget(covariant FlipPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach();
      widget.controller._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller._detach();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _animateToTargetPage(
    int targetPage,
    FlipPageDirection direction, {
    required Duration duration,
    Curve curve = Curves.easeInOut,
  }) async {
    if (_currentIndex == targetPage) return;

    _beforeDragIndex = _currentIndex;
    _dragStartX = null;
    _leftAngle = -_defaultAngle;
    _rightAngle = _defaultAngle;

    _controller.duration = duration;
    _controller.reset();

    final tween = Tween<double>(begin: 0, end: 1);
    final animation = tween.animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );

    void animationListener() {
      final progress = direction == FlipPageDirection.left
          ? animation.value
          : -animation.value;
      _updateAngles(progress);

      if (progress.abs() > 0.5) {
        _currentIndex = targetPage;
      }

      _dragProgress = progress;
      setState(() {});
    }

    animation.addListener(animationListener);
    await _controller.forward();
    animation.removeListener(animationListener);

    _currentIndex = targetPage;
    _leftAngle = -_defaultAngle;
    _rightAngle = _defaultAngle;
    _dragProgress = 0;
    _dragStartX = null;
    _beforeDragIndex = null;
  }

  Future<void> _animateToPage(
    int page, {
    required Duration duration,
    Curve curve = Curves.easeInOut,
  }) async {
    if (_isAnimating) return;
    final sc = _spreadCount;
    if (page < 0 || page >= sc) return;
    if (page == _currentIndex) return;

    _isAnimating = true;

    final startIndex = _currentIndex;
    final distance = (page - startIndex).abs() % sc;
    final direction =
        page > startIndex ? FlipPageDirection.right : FlipPageDirection.left;

    const maxAnimatedPages = 5;
    final animatedPageCount = math.min(distance, maxAnimatedPages);
    final singlePageDuration = Duration(
      milliseconds: duration.inMilliseconds ~/ animatedPageCount,
    );
    final stepSize =
        distance > maxAnimatedPages ? distance / maxAnimatedPages : 1;

    final pages = List.generate(
      animatedPageCount,
      (index) =>
          (startIndex + ((index + 1) * stepSize).round() * direction.value) %
          sc,
    );
    for (final p in pages) {
      await _animateToTargetPage(
        p,
        direction,
        duration: singlePageDuration,
        curve: curve,
      );
    }
    _currentIndex = page;

    _resetDragState();
    widget.controller._notifyPageChanged();
    setState(() {});
  }

  void _jumpToPage(int page) {
    final sc = _spreadCount;
    if (page < 0 || page >= sc) return;
    if (page == _currentIndex) return;

    _currentIndex = page;
    _resetDragState();
    widget.controller._notifyPageChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _currentIndex;

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.surfaceContainerHighest,
              blurRadius: 20,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(10, 0),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if ((_dragProgress > 0 && _dragProgress < 0.5) ||
                      (_dragProgress < -0.5))
                    Transform(
                      key: ValueKey(_leftPageOf(_wrapSpread(s - 2))),
                      alignment: Alignment.centerRight,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, _perspective)
                        ..rotateY(_zeroAngle),
                      child: _clipLeft(
                        widget.itemBuilder(
                          context,
                          _leftPageOf(_wrapSpread(s - 2)),
                        ),
                      ),
                    ),
                  Transform(
                    key: ValueKey(_leftPageOf(_wrapSpread(s - 1))),
                    alignment: Alignment.centerRight,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, _perspective)
                      ..rotateY(
                        _dragProgress > 0 && _dragProgress < 0.5
                            ? _zeroAngle - _dragProgress * 2 * _defaultAngle
                            : (_dragProgress < -0.5
                                  ? _zeroAngle -
                                        (1 + _dragProgress) * 2 * _defaultAngle
                                  : _zeroAngle),
                      ),
                    child: _clipLeft(
                      widget.itemBuilder(
                        context,
                        _leftPageOf(_wrapSpread(s - 1)),
                      ),
                    ),
                  ),
                  Transform(
                    key: ValueKey(_leftPageOf(s)),
                    alignment: Alignment.centerRight,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, _perspective)
                      ..rotateY(_leftAngle),
                    child: _clipLeft(
                      widget.itemBuilder(context, _leftPageOf(s)),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.spacing != null) SizedBox(width: widget.spacing),
            Stack(
              clipBehavior: Clip.none,
              children: [
                if ((_dragProgress < 0 && _dragProgress > -0.5) ||
                    (_dragProgress > 0.5 && _dragProgress < 1))
                  Transform(
                    key: ValueKey(_rightPageOf(_wrapSpread(s + 2))),
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, _perspective)
                      ..rotateY(_zeroAngle),
                    child: _clipRight(
                      widget.itemBuilder(
                        context,
                        _rightPageOf(_wrapSpread(s + 2)),
                      ),
                    ),
                  ),
                Transform(
                  key: ValueKey(_rightPageOf(_wrapSpread(s + 1))),
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, _perspective)
                    ..rotateY(
                      _dragProgress > 0.5
                          ? _zeroAngle + (1 - _dragProgress) * 2 * _defaultAngle
                          : ((_dragProgress < 0 && _dragProgress > -0.5)
                                ? _zeroAngle -
                                      _dragProgress * 2 * _defaultAngle
                                : _zeroAngle),
                    ),
                  child: _clipRight(
                    widget.itemBuilder(
                      context,
                      _rightPageOf(_wrapSpread(s + 1)),
                    ),
                  ),
                ),
                Transform(
                  key: ValueKey(_rightPageOf(s)),
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, _perspective)
                    ..rotateY(_rightAngle),
                  child: _clipRight(
                    widget.itemBuilder(context, _rightPageOf(s)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
