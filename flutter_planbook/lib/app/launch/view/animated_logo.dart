import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({
    this.strokeColor,
    this.size = const Size(200, 200),
    this.onStatusChanged,
    super.key,
  });

  final Color? strokeColor;
  final Size size;
  final AnimationStatusListener? onStatusChanged;

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Durations.long2,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller
      ..addStatusListener((status) {
        widget.onStatusChanged?.call(status);
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LogoView(
      width: widget.size.width,
      height: widget.size.height,
      strokeColor: widget.strokeColor,
      animationValue: _animation.value,
    );
  }
}

class LogoView extends StatelessWidget {
  const LogoView({
    super.key,
    this.width = 200,
    this.height = 200,
    this.strokeColor,
    this.animationValue = 1,
  });

  final double width;
  final double height;
  final Color? strokeColor;
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      width: width,
      height: height,
      child: Hero(
        tag: 'animated_logo',
        child: Center(
          child: CustomPaint(
            size: Size(width, height),
            painter: _AnimatedLogoPainter(
              animationValue: animationValue,
              strokeColor: strokeColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogoPainter extends CustomPainter {
  _AnimatedLogoPainter({required this.animationValue, this.strokeColor});
  final double animationValue;
  final Color? strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.1;
    final paint = Paint()
      ..color = strokeColor ?? Colors.black
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final left = size.width * 0.3;
    final top = size.height * 0.8;

    // 绘制竖线部分
    final path = Path()
      ..moveTo(left + strokeWidth, top)
      ..lineTo(
        left + strokeWidth,
        animationValue >= 0.5
            ? top - size.height * 0.5
            : top - (size.height * 0.5 * animationValue * 2),
      );
    canvas.drawPath(path, paint);

    // 绘制半圆形部分
    if (animationValue >= 0.3) {
      final rect = Rect.fromLTWH(
        left,
        size.height - top,
        size.width * 0.4,
        size.height * 0.4,
      );
      canvas.drawArc(
        rect,
        -math.pi,
        (math.pi + math.pi / 2) * (animationValue - 0.3) * 10 / 7,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
