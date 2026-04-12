import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum FlipPageDirection {
  left(-1),
  right(1);

  const FlipPageDirection(this.value);

  final int value;
}

@immutable
final class FlipPageIndex {
  const FlipPageIndex({required this.left, required this.right});
  factory FlipPageIndex.fromLeft(int index) {
    return FlipPageIndex(left: index, right: index + 1);
  }
  factory FlipPageIndex.fromRight(int index) {
    return FlipPageIndex(left: index - 1, right: index);
  }
  final int left;
  final int right;

  static const zero = FlipPageIndex(left: 0, right: 0);

  FlipPageIndex get next => FlipPageIndex(left: left + 2, right: right + 2);
  FlipPageIndex get previous => FlipPageIndex(left: left - 2, right: right - 2);

  FlipPageIndex clamp(FlipPageIndex min, FlipPageIndex max) {
    return FlipPageIndex(
      left: left.clamp(min.left, max.left),
      right: right.clamp(min.right, max.right),
    );
  }

  FlipPageIndex operator +(FlipPageIndex other) {
    return FlipPageIndex(left: left + other.left, right: right + other.right);
  }

  FlipPageIndex operator -(FlipPageIndex other) {
    return FlipPageIndex(left: left - other.left, right: right - other.right);
  }

  bool operator <(FlipPageIndex other) {
    return left < other.left && right < other.right;
  }

  bool operator >(FlipPageIndex other) {
    return left > other.left && right > other.right;
  }

  bool operator <=(FlipPageIndex other) {
    return left <= other.left && right <= other.right;
  }

  bool operator >=(FlipPageIndex other) {
    return left >= other.left && right >= other.right;
  }

  @override
  bool operator ==(Object other) {
    if (other is FlipPageIndex) {
      return left == other.left && right == other.right;
    }
    return false;
  }

  @override
  int get hashCode => left.hashCode ^ right.hashCode;

  @override
  String toString() {
    return 'FlipPageIndex(left: $left, right: $right)';
  }
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
class FlipPageController extends ValueNotifier<FlipPageIndex> {
  FlipPageController({
    FlipPageIndex initialPage = FlipPageIndex.zero,
  }) : super(initialPage);

  _FlipPageViewState? _state;

  FlipPageIndex get minIndex => _state?.minIndex ?? FlipPageIndex.zero;
  FlipPageIndex get maxIndex => _state?.maxIndex ?? FlipPageIndex.zero;

  bool get hasClients => _state != null;

  // ignore: use_setters_to_change_properties, lifecycle method
  void _attach(_FlipPageViewState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// 判断页码是否有效
  bool isPageValid(FlipPageIndex page) {
    return page >= minIndex && page <= maxIndex;
  }

  /// 判断页码是否为封面
  bool isCoverPage(FlipPageIndex page) {
    return page == minIndex;
  }

  /// 判断页码是否为封底
  bool isBackCoverPage(FlipPageIndex page) {
    return page == maxIndex;
  }

  /// 判断页码是否为内容页
  bool isContentPage(FlipPageIndex page) {
    return page > minIndex && page < maxIndex;
  }

  /// Animates the [FlipPageView] to the given spread [page].
  /// [page] 可以是 -1（封面）、0 到 spreadCount-1（内容页）、spreadCount（封底）
  Future<void> animateToPage(
    FlipPageIndex page, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    return _state?._animateToPage(page, duration: duration, curve: curve) ??
        Future.value();
  }

  /// Jumps the [FlipPageView] to the given spread [page] without animation.
  void jumpToPage(FlipPageIndex page) {
    _state?._jumpToPage(page);
  }

  /// Animates the [FlipPageView] to the next spread.
  Future<void> nextPage({
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    if (_state == null) return Future.value();
    final next = value.next.clamp(minIndex, maxIndex);
    return animateToPage(next, duration: duration, curve: curve);
  }

  /// Animates the [FlipPageView] to the previous spread.
  Future<void> previousPage({
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    if (_state == null) return Future.value();
    final prev = value.previous.clamp(minIndex, maxIndex);
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
///
/// [coverBuilder] 封面构建器，当在第一页往右滑时显示
/// [backCoverBuilder] 封底构建器，当在最后一页往左滑时显示
class FlipPageView extends StatefulWidget {
  const FlipPageView({
    required this.itemBuilder,
    required this.itemsCount,
    required this.controller,
    required this.pageSize,
    required this.coverBuilder,
    required this.backCoverBuilder,
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

  /// 封面构建器，当在第一页往右滑时显示
  final WidgetBuilder coverBuilder;

  /// 封底构建器，当在最后一页往左滑时显示
  final WidgetBuilder backCoverBuilder;

  /// 页面尺寸
  final Size pageSize;

  @override
  State<FlipPageView> createState() => _FlipPageViewState();
}

class _FlipPageViewState extends State<FlipPageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  FlipPageIndex? _beforeDragIndex;
  double? _dragStartX;
  double _dragProgress = 0;
  double _leftAngle = -_defaultAngle;
  double _rightAngle = _defaultAngle;
  bool _isAnimating = false;
  late double _leftWidth = widget.controller.value == minIndex
      ? widget.pageSize.width * 0.5
      : 0;

  static const _perspective = 0.0002;
  static const _zeroAngle = 0.0001;
  static const double _defaultAngle = math.pi / 6.5;
  static const double _maxAngle = math.pi / 2;

  /// 当前 spread 索引，-1 表示封面，_spreadCount 表示封底，0 到 _spreadCount-1 表示内容页
  FlipPageIndex get _currentIndex => widget.controller.value;
  set _currentIndex(FlipPageIndex value) {
    widget.controller.value = value;
  }

  FlipPageIndex get minIndex => FlipPageIndex.fromLeft(-2);
  FlipPageIndex get maxIndex => FlipPageIndex.fromLeft(widget.itemsCount);

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

  void _updateLeftWidth(FlipPageIndex targetIndex, double progress) {
    if (targetIndex == minIndex) {
      if (progress > -0.5 && progress <= 0) {
        _leftWidth = widget.pageSize.width * (0.5 - progress);
      } else if (progress > 0.5 && progress < 1) {
        _leftWidth = widget.pageSize.width * (1 - progress + 0.5);
      } else {
        _leftWidth = widget.pageSize.width * 0.5;
      }
    } else if (targetIndex == maxIndex) {
      if (progress < -0.5) {
        _leftWidth = widget.pageSize.width * (-progress - 0.5);
      } else if (progress < 0.5 && progress >= 0) {
        _leftWidth = widget.pageSize.width * (0.5 - progress);
      } else {
        _leftWidth = 0;
      }
    } else {
      _leftWidth = 0;
    }
  }

  void _onProgressUpdate(double progress) {
    _updateAngles(progress);

    // 计算目标索引
    FlipPageIndex targetIndex;
    if (progress > 0.5) {
      // 往右翻页（显示左边的内容）
      targetIndex = _beforeDragIndex!.previous;
    } else if (progress < -0.5) {
      // 往左翻页（显示右边的内容）
      targetIndex = _beforeDragIndex!.next;
    } else {
      targetIndex = _beforeDragIndex!;
    }
    targetIndex = targetIndex.clamp(minIndex, maxIndex);

    _updateLeftWidth(targetIndex, progress);

    // 应用边界限制
    _currentIndex = targetIndex;
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
    var progress = (dragDistance / (screenWidth * 0.5)).clamp(-1.0, 1.0);

    // 如果已经在最左边（封面或第一页），不能再往右翻
    if (_beforeDragIndex! == minIndex && progress > 0) {
      progress = 0.0;
    }
    // 如果已经在最右边（封底或最后一页），不能再往左翻
    if (_beforeDragIndex! == maxIndex && progress < 0) {
      progress = 0.0;
    }

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
    FlipPageIndex targetPage,
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

      _updateLeftWidth(_currentIndex, progress);
      _dragProgress = progress;
      setState(() {});
    }

    animation.addListener(animationListener);
    await _controller.forward();
    animation.removeListener(animationListener);

    _currentIndex = targetPage;
    _leftAngle = -_defaultAngle;
    _rightAngle = _defaultAngle;
    _updateLeftWidth(targetPage, 0);
    _dragProgress = 0;
    _dragStartX = null;
    _beforeDragIndex = null;
  }

  Future<void> _animateToPage(
    FlipPageIndex page, {
    required Duration duration,
    Curve curve = Curves.easeInOut,
  }) async {
    if (_isAnimating) return;

    if (!widget.controller.isPageValid(page)) return;
    if (page == _currentIndex) return;

    _isAnimating = true;

    final startIndex = _currentIndex;
    final distance = (page - startIndex).left.abs();
    final direction = page.left > startIndex.left
        ? FlipPageDirection.right
        : FlipPageDirection.left;

    // const maxAnimatedPages = 5;
    // final animatedPageCount = math.min(distance, maxAnimatedPages);
    // final singlePageDuration = Duration(
    //   milliseconds: duration.inMilliseconds ~/ animatedPageCount,
    // );
    // final stepSize = distance > maxAnimatedPages
    //     ? distance / maxAnimatedPages
    //     : 1;

    // final pages = List.generate(
    //   animatedPageCount,
    //   (index) {
    //     final delta = ((index + 1) * stepSize).round() * direction.value;
    //     return FlipPageIndex(
    //       left: startIndex.left + delta,
    //       right: startIndex.right + delta,
    //     );
    //   },
    // );
    // for (final p in pages) {
    //   await _animateToTargetPage(
    //     p,
    //     direction,
    //     duration: singlePageDuration,
    //     curve: curve,
    //   );
    // }
    // _currentIndex = page;
    await _animateToTargetPage(
      page,
      direction,
      duration: duration,
      curve: curve,
    );

    _resetDragState();
    widget.controller._notifyPageChanged();
    setState(() {});
  }

  void _jumpToPage(FlipPageIndex page) {
    if (!widget.controller.isPageValid(page)) return;
    if (page == _currentIndex) return;

    _currentIndex = page;
    _resetDragState();
    widget.controller._notifyPageChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.pageSize.width * 2 + 2,
        height: widget.pageSize.height,
        // decoration: BoxDecoration(
        //   boxShadow: [
        //     BoxShadow(
        //       color: theme.colorScheme.surfaceContainerHighest,
        //       blurRadius: 20,
        //       offset: const Offset(0, 20),
        //     ),
        //   ],
        // ),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: _leftWidth, height: widget.pageSize.height),
            if (_currentIndex.left != minIndex.left)
              _buildLeftPage(_currentIndex.left),
            if (widget.spacing != null)
              Container(
                width: widget.spacing,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            if (_currentIndex.right != maxIndex.right)
              _buildRightPage(_currentIndex.right),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPage(int index) {
    final children = <Widget>[];
    const bottomAngle = _zeroAngle;
    final middleAngle = _dragProgress > 0 && _dragProgress < 0.5
        ? _zeroAngle - _dragProgress * 2 * _defaultAngle
        : (_dragProgress < -0.5
              ? _zeroAngle - (1 + _dragProgress) * 2 * _defaultAngle
              : _zeroAngle);
    print(index);
    children.add(
      Transform(
        key: const ValueKey('cover_left'),
        alignment: Alignment.centerRight,
        transform: Matrix4.identity()
          ..setEntry(3, 2, _perspective)
          ..rotateY(
            index == 0
                ? _leftAngle
                : index == 2
                ? middleAngle
                : bottomAngle,
          )
          ..scaleByDouble(1.02, 1, 1, 1),
        child: _clipLeft(widget.coverBuilder(context)),
      ),
    );

    // 封面或前一页
    final bottomIndex = index - 4;
    if (bottomIndex > minIndex.left &&
        ((_dragProgress > 0 && _dragProgress < 0.5) ||
            (_dragProgress < -0.5))) {
      children.add(
        Transform(
          key: ValueKey(bottomIndex),
          alignment: Alignment.centerRight,
          transform: Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateY(bottomAngle),
          child: _clipLeft(widget.itemBuilder(context, bottomIndex)),
        ),
      );
    }

    final middleIndex = index - 2;
    if (middleIndex > minIndex.left) {
      children.add(
        Transform(
          key: ValueKey(middleIndex),
          alignment: Alignment.centerRight,
          transform: Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateY(middleAngle),
          child: _clipLeft(widget.itemBuilder(context, middleIndex)),
        ),
      );
    }

    children.add(
      Transform(
        key: ValueKey(
          index,
        ),
        alignment: Alignment.centerRight,
        transform: Matrix4.identity()
          ..setEntry(3, 2, _perspective)
          ..rotateY(_leftAngle),
        child: _clipLeft(
          index == maxIndex.left
              ? widget.backCoverBuilder(context)
              : widget.itemBuilder(context, index),
        ),
      ),
    );

    return Stack(clipBehavior: Clip.none, children: children);
  }

  Widget _buildRightPage(int index) {
    final children = <Widget>[];
    // 封底或后一页
    final bottomIndex = index + 4;
    if (bottomIndex < maxIndex.right &&
        ((_dragProgress < 0 && _dragProgress > -0.5) ||
            (_dragProgress > 0.5 && _dragProgress < 1))) {
      children.add(
        Transform(
          key: ValueKey(bottomIndex),
          alignment: Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateY(_zeroAngle),
          child: _clipRight(widget.itemBuilder(context, bottomIndex)),
        ),
      );
    }
    // 当前翻动的右页
    final middleIndex = index + 2;
    if (middleIndex < maxIndex.right) {
      children.add(
        Transform(
          key: ValueKey(middleIndex),
          alignment: Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateY(
              _dragProgress > 0.5
                  ? _zeroAngle + (1 - _dragProgress) * 2 * _defaultAngle
                  : ((_dragProgress < 0 && _dragProgress > -0.5)
                        ? _zeroAngle - _dragProgress * 2 * _defaultAngle
                        : _zeroAngle),
            ),
          child: _clipRight(widget.itemBuilder(context, middleIndex)),
        ),
      );
    }

    /// 当前右页
    final transform = Matrix4.identity()
      ..setEntry(3, 2, _perspective)
      ..rotateY(_rightAngle);
    children.add(
      Transform(
        key: ValueKey(index == maxIndex.right ? 'backcover_right' : index),
        alignment: Alignment.centerLeft,
        transform: transform,
        child: _clipRight(
          index == minIndex.right
              ? widget.coverBuilder(context)
              : widget.itemBuilder(context, index),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: children,
    );
  }
}
