import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum FlipPageDirection {
  left(-1),
  right(1);

  const FlipPageDirection(this.value);

  final int value;
}

/// Callback type for animating to a page.
typedef _AnimateToPageCallback =
    Future<void> Function(
      int page, {
      required Duration duration,
      Curve curve,
    });

/// Callback type for jumping to a page.
typedef _JumpToPageCallback = void Function(int page);

/// Callback type for getting items count.
typedef _GetItemsCountCallback = int Function();

/// A controller for [FlipPageView] that allows programmatic control
/// of the page being displayed.
///
/// Similar to [PageController], this controller provides methods to
/// animate or jump to a specific page in the [FlipPageView].
///
/// The controller maintains its own state and directly controls the page view
/// through callbacks, reducing coupling between the controller and the view.
class FlipPageController extends ValueNotifier<int> {
  /// Creates a controller for a [FlipPageView].
  ///
  /// The [initialPage] argument must not be null.
  FlipPageController({int initialPage = 0})
    : assert(
        initialPage >= 0,
        'initialPage must be greater than or equal to 0',
      ),
      super(initialPage);

  /// 当前页面的 RenderRepaintBoundary（用于截图）
  RenderRepaintBoundary? _currentBoundary;

  _AnimateToPageCallback? _animateToPageCallback;
  _JumpToPageCallback? _jumpToPageCallback;
  _GetItemsCountCallback? _getItemsCountCallback;

  /// 注册当前页面的 RenderRepaintBoundary（由 FlipPageView 内部调用）
  void _registerCurrentBoundary(RenderRepaintBoundary? boundary) {
    if (_currentBoundary == boundary) return;
    _currentBoundary = boundary;
  }

  /// Whether this controller is attached to a [FlipPageView].
  bool get hasClients =>
      _animateToPageCallback != null && _jumpToPageCallback != null;

  /// Animates the [FlipPageView] from the current page to the given page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] completes when the animation completes.
  ///
  /// The [page] argument must be a valid page index.
  Future<void> animateToPage(
    int page, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    if (_animateToPageCallback == null) {
      return Future.value();
    }
    return _animateToPageCallback!(page, duration: duration, curve: curve);
  }

  /// Jumps the [FlipPageView] from the current page to the given page
  /// without animation.
  ///
  /// The [page] argument must be a valid page index.
  void jumpToPage(int page) {
    _jumpToPageCallback?.call(page);
  }

  /// Animates the [FlipPageView] to the next page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] completes when the animation completes.
  Future<void> nextPage({
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    if (!hasClients) return Future.value();
    final itemsCount = _getItemsCountCallback?.call() ?? 1;
    final nextPageIndex = (value + 1) % itemsCount;
    return animateToPage(nextPageIndex, duration: duration, curve: curve);
  }

  /// Animates the [FlipPageView] to the previous page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] completes when the animation completes.
  Future<void> previousPage({
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    if (!hasClients) return Future.value();
    final itemsCount = _getItemsCountCallback?.call() ?? 1;
    final prevPageIndex = value == 0 ? itemsCount - 1 : value - 1;
    return animateToPage(prevPageIndex, duration: duration, curve: curve);
  }

  /// 将当前页面捕获为图片
  ///
  /// [pixelRatio] 图片的像素密度，默认为 1.0
  /// 返回 [ui.Image]，可通过 `toByteData()` 转换为字节数据
  Future<ui.Image?> captureToImage({double pixelRatio = 1.0}) async {
    if (_currentBoundary == null) return null;
    return _currentBoundary!.toImage(pixelRatio: pixelRatio);
  }

  void _attach({
    required _AnimateToPageCallback animateToPage,
    required _JumpToPageCallback jumpToPage,
    required _GetItemsCountCallback getItemsCount,
  }) {
    _animateToPageCallback = animateToPage;
    _jumpToPageCallback = jumpToPage;
    _getItemsCountCallback = getItemsCount;
  }

  void _detach() {
    _animateToPageCallback = null;
    _jumpToPageCallback = null;
    _getItemsCountCallback = null;
    _currentBoundary = null; // 清除对 RenderObject 的引用，避免内存泄漏
  }

  void _notifyPageChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }
}

class FlipPageView extends StatefulWidget {
  const FlipPageView({
    required this.itemBuilder,
    required this.itemsCount,
    required this.controller,
    this.initialPage = 0,
    this.spacing,
    super.key,
  });

  final int itemsCount;
  final IndexedWidgetBuilder? itemBuilder;
  final int initialPage;
  final FlipPageController controller;
  final double? spacing;

  @override
  State<FlipPageView> createState() => _FlipPageViewState();
}

class _FlipPageViewState extends State<FlipPageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late int? _beforeDragIndex;

  double? _dragStartX;
  double _dragProgress = 0;
  double _leftAngle = -math.pi / 8;
  double _rightAngle = math.pi / 8;
  bool _isAnimating = false;

  static const _perspective = 0.0002;
  static const _zeroAngle = 0.0001;
  static const double _defaultAngle = math.pi / 8;
  static const double _maxAngle = math.pi / 2;

  int get _currentIndex => widget.controller.value;
  set _currentIndex(int value) {
    widget.controller.value = value;
  }

  /// 更新角度（根据进度值）
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

    if (progress > 0.5) {
      _currentIndex = _beforeDragIndex == 0
          ? widget.itemsCount - 1
          : _beforeDragIndex! - 1;
    } else if (progress < -0.5) {
      _currentIndex = _beforeDragIndex == widget.itemsCount - 1
          ? 0
          : _beforeDragIndex! + 1;
    } else {
      _currentIndex = _beforeDragIndex!;
    }

    _dragProgress = progress;
    if (kDebugMode) {
      print('dragProgress: $_dragProgress');
    }

    setState(() {});
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isAnimating) return;

    _dragStartX = details.globalPosition.dx;
    // Reset angles to default when starting drag
    _leftAngle = -_defaultAngle;
    _rightAngle = _defaultAngle;

    _beforeDragIndex = _currentIndex;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_dragStartX == null || _beforeDragIndex == null || _isAnimating) return;

    final dragDistance = details.globalPosition.dx - _dragStartX!;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate progress: -1.0 to 1.0
    final progress = (dragDistance / (screenWidth * 0.5)).clamp(-1.0, 1.0);
    _onProgressUpdate(progress);
  }

  Future<void> _onHorizontalDragEnd(DragEndDetails details) async {
    if (_dragStartX == null || _beforeDragIndex == null || _isAnimating) {
      return;
    }

    final velocity = details.velocity.pixelsPerSecond.dx;
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3; // 30% of screen width

    // Determine if we should complete the flip
    final shouldComplete =
        _dragProgress.abs() > 0.5 ||
        (details.primaryVelocity?.abs() ?? 0) > threshold ||
        (velocity.abs() > 500 && (velocity > 0) == (_dragProgress > 0));

    // Animate from current state to target state
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

    _leftAngle = -_defaultAngle;
    _rightAngle = _defaultAngle;
    _dragProgress = 0;
    _dragStartX = null;
    _beforeDragIndex = null;
    _isAnimating = false;
    widget.controller._notifyPageChanged();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Register callbacks with controller for direct control
    widget.controller._attach(
      animateToPage: _animateToPage,
      jumpToPage: _jumpToPage,
      getItemsCount: () => widget.itemsCount,
    );
  }

  @override
  void dispose() {
    widget.controller._detach();
    _controller.dispose();
    super.dispose();
  }

  /// 执行翻页动画到指定目标页面（支持跨多页）
  Future<void> _animateToTargetPage(
    int targetPage,
    FlipPageDirection direction, {
    required Duration duration,
    Curve curve = Curves.easeInOut,
  }) async {
    final startPage = _currentIndex;
    if (startPage == targetPage) return;

    _beforeDragIndex = startPage;
    _dragStartX = null;
    _leftAngle = -_defaultAngle;
    _rightAngle = _defaultAngle;

    _controller.duration = duration;
    _controller.reset();

    // 动画范围从 0 到 pageCount
    final tween = Tween<double>(begin: 0, end: 1);
    final animation = tween.animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );

    void animationListener() {
      final animationValue = animation.value;
      final progress = direction == FlipPageDirection.left
          ? animationValue
          : -animationValue;
      if (kDebugMode) {
        print('progress: $progress');
      }
      _updateAngles(progress);

      if (progress > 0.5) {
        _currentIndex = targetPage;
      } else if (progress < -0.5) {
        _currentIndex = targetPage;
      }

      _dragProgress = progress;
      if (kDebugMode) {
        print('dragProgress: $_dragProgress');
      }

      setState(() {});
    }

    animation.addListener(animationListener);
    await _controller.forward();
    animation.removeListener(animationListener);

    // 确保最终状态正确
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
    if (page < 0 || page >= widget.itemsCount) return;
    if (page == _currentIndex) return;

    _isAnimating = true;

    final targetIndex = page;
    final startIndex = _currentIndex;

    // 计算需要翻多少页
    final distance = (targetIndex - startIndex).abs() % widget.itemsCount;
    final direction = targetIndex > startIndex
        ? FlipPageDirection.right
        : FlipPageDirection.left;

    // 限制最多翻5页，超过则使用等步长翻页
    const maxAnimatedPages = 5;
    final animatedPageCount = math.min(distance, maxAnimatedPages);
    final singlePageDuration = Duration(
      milliseconds: duration.inMilliseconds ~/ animatedPageCount,
    );
    final stepSize = distance > maxAnimatedPages
        ? distance / maxAnimatedPages
        : 1;

    final pages = List.generate(
      animatedPageCount,
      (index) =>
          (startIndex + ((index + 1) * stepSize).round() * direction.value) %
          widget.itemsCount,
    );
    for (final page in pages) {
      await _animateToTargetPage(
        page,
        direction,
        duration: singlePageDuration,
        curve: curve,
      );
    }
    _currentIndex = targetIndex;

    // 清理状态
    _leftAngle = -_defaultAngle;
    _rightAngle = _defaultAngle;
    _dragProgress = 0;
    _dragStartX = null;
    _beforeDragIndex = null;
    _isAnimating = false;
    widget.controller._notifyPageChanged();
    setState(() {});
  }

  void _jumpToPage(int page) {
    if (page < 0 || page >= widget.itemsCount) return;
    if (page == _currentIndex) return;

    _currentIndex = page;
    _leftAngle = -_defaultAngle;
    _rightAngle = _defaultAngle;
    _dragProgress = 0;
    _dragStartX = null;
    _beforeDragIndex = null;
    widget.controller._notifyPageChanged();
    setState(() {});
  }

  /// 构建页面内容，所有页面使用相同结构
  /// [index] 页面索引
  /// [isCurrentPage] 是否是当前页面（用于注册截图 boundary）
  Widget _buildPageContent(int index, {required bool isCurrentPage}) {
    return RepaintBoundary(
      child: Builder(
        builder: (context) {
          if (isCurrentPage) {
            // 在 frame 结束后注册 boundary，避免在 build 中同步调用
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final boundary = context
                  .findAncestorRenderObjectOfType<RenderRepaintBoundary>();
              widget.controller._registerCurrentBoundary(boundary);
            });
          }
          return widget.itemBuilder!(context, index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              if ((_dragProgress > 0 && _dragProgress < 0.5) ||
                  (_dragProgress < -0.5))
                Transform(
                  key: ValueKey(
                    _currentIndex <= 1
                        ? widget.itemsCount - 2 + _currentIndex
                        : _currentIndex - 2,
                  ),
                  alignment: Alignment.centerRight,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, _perspective)
                    ..rotateY(_zeroAngle),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.5,
                      child: _buildPageContent(
                        _currentIndex <= 1
                            ? widget.itemsCount - 2 + _currentIndex
                            : _currentIndex - 2,
                        isCurrentPage: false,
                      ),
                    ),
                  ),
                ),
              Transform(
                key: ValueKey(
                  _currentIndex == 0
                      ? widget.itemsCount - 1
                      : _currentIndex - 1,
                ),
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
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.5,
                    child: _buildPageContent(
                      _currentIndex == 0
                          ? widget.itemsCount - 1
                          : _currentIndex - 1,
                      isCurrentPage: false,
                    ),
                  ),
                ),
              ),
              Transform(
                key: ValueKey(_currentIndex),
                alignment: Alignment.centerRight,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateY(_leftAngle),
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.5,
                    child: _buildPageContent(
                      _currentIndex,
                      isCurrentPage: false, // 左半边不需要注册，右半边注册
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.spacing != null) SizedBox(width: widget.spacing),
          Stack(
            clipBehavior: Clip.none,
            children: [
              if ((_dragProgress < 0 && _dragProgress > -0.5) ||
                  (_dragProgress > 0.5 && _dragProgress < 1))
                Transform(
                  key: ValueKey(
                    _currentIndex >= widget.itemsCount - 2
                        ? _currentIndex - widget.itemsCount + 2
                        : _currentIndex + 2,
                  ),
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, _perspective)
                    ..rotateY(_zeroAngle),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.centerRight,
                      widthFactor: 0.5,
                      child: _buildPageContent(
                        _currentIndex >= widget.itemsCount - 2
                            ? _currentIndex - widget.itemsCount + 2
                            : _currentIndex + 2,
                        isCurrentPage: false,
                      ),
                    ),
                  ),
                ),
              Transform(
                key: ValueKey(
                  _currentIndex == widget.itemsCount - 1
                      ? 0
                      : _currentIndex + 1,
                ),
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
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: 0.5,
                    child: _buildPageContent(
                      _currentIndex == widget.itemsCount - 1
                          ? 0
                          : _currentIndex + 1,
                      isCurrentPage: false,
                    ),
                  ),
                ),
              ),
              Transform(
                key: ValueKey(_currentIndex),
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateY(_rightAngle),
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: 0.5,
                    child: _buildPageContent(
                      _currentIndex,
                      isCurrentPage: true, // 右半边注册用于截图
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
