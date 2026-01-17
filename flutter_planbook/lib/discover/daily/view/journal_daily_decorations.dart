import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';

/// 虚线绘制器
class DashedLinePainter extends CustomPainter {
  DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    var startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 手账笔记贴纸装饰视图（可选用）
class JournalNoteStickerDecoration extends StatelessWidget {
  const JournalNoteStickerDecoration({
    required this.child,
    this.showTopTape = false,
    this.showCornerSticker = false,
    this.tapeColor,
    super.key,
  });

  final Widget child;
  final bool showTopTape;
  final bool showCornerSticker;
  final Color? tapeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = context.pinkColorScheme;
    final effectiveTapeColor = tapeColor ?? colorScheme.primaryContainer;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        // 顶部胶带
        if (showTopTape)
          Positioned(
            top: -8,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: -0.05,
                child: Container(
                  width: 50,
                  height: 16,
                  decoration: BoxDecoration(
                    color: effectiveTapeColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        // 角落贴纸
        if (showCornerSticker)
          Positioned(
            top: -6,
            right: -6,
            child: Transform.rotate(
              angle: 0.3,
              child: Text(
                '⭐',
                style: TextStyle(
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: theme.shadowColor.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 构建装饰元素
List<Widget> buildJournalDecorations(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = context.amberColorScheme;

  return [
    // 右上角装饰星星
    Positioned(
      top: 0,
      right: 20,
      child: Text(
        '✧',
        style: TextStyle(
          fontSize: 18,
          color: colorScheme.primary.withOpacity(0.4),
        ),
      ),
    ),
    // 左下角装饰圆点
    Positioned(
      bottom: 40,
      left: 10,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: context.tealColorScheme.primary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
    ),
    // 右侧装饰线条
    Positioned(
      right: 0,
      top: 60,
      child: Container(
        width: 2,
        height: 30,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.2),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    ),
  ];
}
