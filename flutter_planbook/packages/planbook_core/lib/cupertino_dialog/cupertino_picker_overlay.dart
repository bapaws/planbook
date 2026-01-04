import 'package:flutter/material.dart';
import 'package:planbook_core/cupertino_dialog/cupertino_picker_container.dart';
import 'package:planbook_core/cupertino_dialog/picker_container_decoration.dart';

class CupertinoPickerOverlay extends StatefulWidget {
  const CupertinoPickerOverlay({
    required this.widgetRenderBox,
    required this.horizontalSpacing,
    required this.verticalSpacing,
    required this.offset,
    required this.outsideTapDismissable,
    required this.height,
    required this.width,
    required this.containerDecoration,
    required this.child,
    super.key,
  });

  final double height;
  final double width;
  final double horizontalSpacing;
  final double verticalSpacing;
  final Offset offset;
  final RenderBox? widgetRenderBox;
  final bool outsideTapDismissable;
  final PickerContainerDecoration? containerDecoration;
  final Widget child;

  @override
  State<CupertinoPickerOverlay> createState() => _CupertinoPickerOverlayState();
}

class _CupertinoPickerOverlayState extends State<CupertinoPickerOverlay> {
  AnimationController? _controller;
  Offset? _widgetPosition;

  void _onInitialized(AnimationController animationController) {
    _controller = animationController;
    _controller?.forward();
    _controller?.addStatusListener(_statusListener);
  }

  void _statusListener(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      Navigator.of(context).pop();
    }
  }

  void _onOutsideTap() {
    _closeOverlay();
  }

  void _closeOverlay() {
    if (_controller != null) {
      final isReverseInProgress =
          _controller!.status == AnimationStatus.reverse;
      if (!isReverseInProgress) {
        _controller?.reverse(from: 0.75);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = widget.height;

    final renderBox = widget.widgetRenderBox;
    final horizontalSpacing = widget.horizontalSpacing;
    final verticalSpacing = widget.verticalSpacing;
    final offset = widget.offset;

    final screenSize = MediaQuery.sizeOf(context);
    final safeArea = MediaQuery.viewPaddingOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final isAttached = renderBox?.attached ?? false;
    if (isAttached) {
      _widgetPosition = renderBox?.localToGlobal(Offset.zero);
    }

    final widgetPosition = _widgetPosition ?? Offset.zero;
    final widgetSize = renderBox?.size ?? Size.zero;
    final widgetWidth = widgetSize.width;
    final widgetHeight = widgetSize.height;
    final widgetHalfWidth = widgetWidth / 2;
    final widgetCenterX = widgetPosition.dx + widgetHalfWidth;
    final widgetTopCenterY = widgetPosition.dy;
    final widgetBottomCenterY = widgetPosition.dy + widgetHeight;

    final spaceOnTop =
        widgetTopCenterY - offset.dy - verticalSpacing - safeArea.top;
    final spaceOnLeft = widgetCenterX - horizontalSpacing - safeArea.left;
    final spaceOnRight =
        screenWidth - widgetCenterX - horizontalSpacing - safeArea.right;
    final spaceOnBottom =
        screenHeight -
        widgetBottomCenterY -
        offset.dy -
        verticalSpacing -
        safeArea.bottom;

    final halfWidth = width / 2;
    final neededSpaceOnRight = spaceOnLeft < halfWidth
        ? width - spaceOnLeft
        : halfWidth;
    final neededSpaceOnLeft = spaceOnRight < halfWidth
        ? width - spaceOnRight
        : halfWidth;

    final fitsOnTop = spaceOnTop >= spaceOnBottom;
    final fitsOnLeft = spaceOnLeft >= neededSpaceOnLeft;
    final fitsOnRight = spaceOnRight >= neededSpaceOnRight;
    final fitsHorizontally = fitsOnLeft && fitsOnRight;

    double? top;
    double? left;
    double? right;
    double? bottom;

    if (fitsOnTop) {
      top = widgetTopCenterY - height - offset.dy;
    } else {
      top = widgetBottomCenterY + offset.dy;
    }

    if (fitsHorizontally) {
      left = widgetCenterX - halfWidth;
    } else if (fitsOnLeft) {
      left = screenWidth - width - horizontalSpacing;
    } else if (fitsOnRight) {
      left = horizontalSpacing;
    } else {
      left = 0;
      right = 0;
    }

    left += offset.dx;

    final verticalSpace = fitsOnTop ? spaceOnTop : spaceOnBottom;

    double xAlignment;

    if (!fitsOnRight && !fitsOnLeft) {
      xAlignment = 0.0;
    } else if (!fitsOnRight) {
      final offsetOnRight = neededSpaceOnRight - spaceOnRight;
      xAlignment = offsetOnRight / halfWidth;
    } else if (!fitsOnLeft) {
      final offsetOnLeft = neededSpaceOnLeft - spaceOnLeft;
      xAlignment = -offsetOnLeft / halfWidth;
    } else {
      xAlignment = 0.0;
    }

    final scaleAligment = Alignment(
      xAlignment,
      fitsOnTop ? 1.0 : -1.0,
    );

    var maxScale = 1.0;

    final availableWidth = screenWidth - (horizontalSpacing * 2) - offset.dx;
    final availableHeight = verticalSpace;
    if (availableHeight < height) {
      maxScale = availableHeight / height;
    }

    if (availableWidth < width) {
      final newMaxScale = availableWidth / width;
      if (newMaxScale < maxScale) {
        maxScale = newMaxScale;
      }

      if (maxScale < 1.0) {
        if (left == right) {
          left = -width * 2;
          right = -width * 2;
        } else {
          left = 0;
          right = 0;
        }
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _closeOverlay(),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.outsideTapDismissable ? _onOutsideTap : null,
              behavior: HitTestBehavior.translucent,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: top,
            left: left,
            right: right,
            bottom: bottom,
            child: Material(
              color: Colors.transparent,
              child: CupertinoPickerContainer(
                height: height,
                width: width,
                onInitialized: _onInitialized,
                decoration:
                    widget.containerDecoration ??
                    PickerContainerDecoration.withDynamicColor(context),
                maxScale: maxScale,
                scaleAlignment: scaleAligment,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeStatusListener(_statusListener);
    super.dispose();
  }
}
