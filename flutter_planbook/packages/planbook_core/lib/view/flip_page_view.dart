import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum FlipPageDirection { left, right }

class FlipPageView extends StatefulWidget {
  const FlipPageView({
    required this.itemBuilder,
    required this.itemsCount,
    this.initialPage = 0,
    super.key,
  });

  final int itemsCount;
  final IndexedWidgetBuilder? itemBuilder;
  final int initialPage;

  @override
  State<FlipPageView> createState() => _FlipPageViewState();
}

class _FlipPageViewState extends State<FlipPageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late int _currentIndex = 0;
  late int? _beforeDragIndex;

  double? _dragStartX;
  double _dragProgress = 0;
  double _leftAngle = -math.pi / 6;
  double _rightAngle = math.pi / 6;
  bool _isAnimating = false;

  static const _perspective = 0.001;
  static const _zeroAngle = 0.0001;
  static const double _defaultAngle = math.pi / 6;
  static const double _maxAngle = math.pi / 2;

  void _onProgressUpdate(double progress) {
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
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPage;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Row(
        children: [
          Stack(
            children: [
              if ((_dragProgress > 0 && _dragProgress < 0.5) ||
                  (_dragProgress < -0.5))
                Transform(
                  alignment: Alignment.centerRight,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, _perspective)
                    ..rotateY(_zeroAngle),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.5,
                      child: widget.itemBuilder!(
                        context,
                        _currentIndex <= 1
                            ? widget.itemsCount - 2 + _currentIndex
                            : _currentIndex - 2,
                      ),
                    ),
                  ),
                ),
              Transform(
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
                    child: widget.itemBuilder!(
                      context,
                      _currentIndex == 0
                          ? widget.itemsCount - 1
                          : _currentIndex - 1,
                    ),
                  ),
                ),
              ),
              Transform(
                alignment: Alignment.centerRight,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateY(_leftAngle),
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.5,
                    child: widget.itemBuilder!(
                      context,
                      _currentIndex,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 2),
          Stack(
            children: [
              if ((_dragProgress < 0 && _dragProgress > -0.5) ||
                  (_dragProgress > 0.5 && _dragProgress < 1))
                Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, _perspective)
                    ..rotateY(_zeroAngle),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.centerRight,
                      widthFactor: 0.5,
                      child: widget.itemBuilder!(
                        context,
                        _currentIndex >= widget.itemsCount - 2
                            ? _currentIndex - widget.itemsCount + 2
                            : _currentIndex + 2,
                      ),
                    ),
                  ),
                ),
              Transform(
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
                    child: widget.itemBuilder!(
                      context,
                      _currentIndex == widget.itemsCount - 1
                          ? 0
                          : _currentIndex + 1,
                    ),
                  ),
                ),
              ),
              Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateY(_rightAngle),
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: 0.5,
                    child: widget.itemBuilder!(context, _currentIndex),
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
