import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/model/app_color_schemes.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';
import 'package:planbook_api/entity/note_entity.dart';

/// 笔记卡片样式枚举（纯卡片，不含胶带）
enum NoteCardStyle {
  /// 拍立得风格 - 经典白边相片
  polaroid,

  /// 相片长条 - 影展相片条
  strip,
}

/// 胶带样式
enum TapeStyle {
  /// 斜线纹理
  stripe,

  /// 圆点纹理
  dots,

  /// 格子纹理
  grid,

  /// 渐变透明
  gradient,

  /// 和纸胶带（小花纹）
  washi,
}

/// 手账笔记卡片视图
class JournalDailyNoteView extends StatelessWidget {
  const JournalDailyNoteView({
    required this.note,
    required this.width,
    this.style = NoteCardStyle.polaroid,
    this.tapeStyle,
    this.tapeColorScheme,
    this.onTap,
    super.key,
  });

  final NoteEntity note;
  final NoteCardStyle style;
  final TapeStyle? tapeStyle;
  final ColorScheme? tapeColorScheme;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hashCode = note.id.hashCode;
    final style = NoteCardStyle.values[hashCode % NoteCardStyle.values.length];
    final tapeStyle = TapeStyle.values[hashCode % TapeStyle.values.length];
    final baseCard = switch (style) {
      NoteCardStyle.polaroid => _PolaroidNoteCard(
        note: note,
        width: width,
        onTap: onTap,
      ),
      NoteCardStyle.strip => _PhotoStripNoteCard(
        note: note,
        width: width,
        onTap: onTap,
      ),
    };

    final effectiveTapeScheme =
        tapeColorScheme ?? _resolveTapeScheme(context, tapeStyle);

    return _TapeOverlay(
      note: note,
      tapeStyle: tapeStyle,
      tapeColorScheme: effectiveTapeScheme,
      child: baseCard,
    );
  }
}

ColorScheme _resolveTapeScheme(BuildContext context, TapeStyle tapeStyle) {
  return switch (tapeStyle) {
    TapeStyle.stripe => context.pinkColorScheme,
    TapeStyle.dots => context.tealColorScheme,
    TapeStyle.grid => context.amberColorScheme,
    TapeStyle.gradient => context.purpleColorScheme,
    TapeStyle.washi => context.orangeColorScheme,
  };
}

/// 图片拼贴（展示多张图片，而非仅提示）
class _NoteImagesCollage extends StatelessWidget {
  const _NoteImagesCollage({
    required this.images,
    required this.width,
    required this.height,
  });

  final List<String> images;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final display = images.take(4).toList();
    final more = images.length - display.length;

    return SizedBox(
      width: width,
      height: height,
      child: _buildLayout(display, more),
    );
  }

  Widget _buildLayout(List<String> display, int more) {
    if (display.length == 1) {
      return AppNetworkImage(
        url: display[0],
        width: width,
        height: height,
      );
    }
    if (display.length == 2) {
      final tileWidth = ((width - 4) / 2).floorToDouble();
      return Row(
        children: [
          AppNetworkImage(
            url: display[0],
            width: tileWidth,
            height: height,
          ),
          const SizedBox(width: 4),
          AppNetworkImage(
            url: display[1],
            width: tileWidth,
            height: height,
          ),
        ],
      );
    }

    final tileWidth = (width - 4) / 2;
    final tileHeight = (height - 4) / 2;
    return Column(
      children: [
        Row(
          children: [
            AppNetworkImage(
              url: display[0],
              width: tileWidth,
              height: tileHeight,
            ),
            const SizedBox(width: 4),
            AppNetworkImage(
              url: display[1],
              width: tileWidth,
              height: tileHeight,
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (display.length == 3)
          AppNetworkImage(
            url: display[2],
            width: width,
            height: tileHeight,
          )
        else if (display.length == 4)
          Row(
            children: [
              AppNetworkImage(
                url: display[2],
                width: tileWidth,
                height: tileHeight,
              ),
              const SizedBox(width: 4),
              AppNetworkImage(
                url: display[3],
                width: tileWidth,
                height: tileHeight,
              ),
            ],
          )
        else
          Row(
            children: [
              AppNetworkImage(
                url: display[2],
                width: tileWidth,
                height: tileHeight,
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: tileWidth,
                height: tileHeight,
                child: Stack(
                  children: [
                    AppNetworkImage(
                      url: display[3],
                      width: tileWidth,
                      height: tileHeight,
                    ),
                    Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: Text(
                        '+$more',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// 胶带覆盖层（可选）
class _TapeOverlay extends StatelessWidget {
  const _TapeOverlay({
    required this.note,
    required this.child,
    required this.tapeStyle,
    required this.tapeColorScheme,
  });

  final NoteEntity note;
  final Widget child;
  final TapeStyle tapeStyle;
  final ColorScheme tapeColorScheme;

  @override
  Widget build(BuildContext context) {
    final random = math.Random(note.id.hashCode);
    final tapeRotation = (random.nextDouble() - 0.5) * 0.12;
    final tapeWidth = 55.0 + (note.id.hashCode % 20);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -8,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.rotate(
              angle: tapeRotation,
              child: SizedBox(
                width: tapeWidth,
                height: 18,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: CustomPaint(
                    painter: _TapePainter(
                      style: tapeStyle,
                      primaryColor: tapeColorScheme.primaryContainer,
                      patternColor: tapeColorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 胶带绘制器
class _TapePainter extends CustomPainter {
  _TapePainter({
    required this.style,
    required this.primaryColor,
    required this.patternColor,
  });

  final TapeStyle style;
  final Color primaryColor;
  final Color patternColor;

  @override
  void paint(Canvas canvas, Size size) {
    // 胶带背景（半透明效果）
    final bgPaint = Paint()..color = primaryColor.withOpacity(0.85);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final patternPaint = Paint()
      ..color = patternColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    switch (style) {
      case TapeStyle.stripe:
        _drawStripePattern(canvas, size, patternPaint);
      case TapeStyle.dots:
        _drawDotsPattern(canvas, size, patternPaint);
      case TapeStyle.grid:
        _drawGridPattern(canvas, size, patternPaint);
      case TapeStyle.gradient:
        _drawGradientPattern(canvas, size);
      case TapeStyle.washi:
        _drawWashiPattern(canvas, size, patternPaint);
    }

    // 胶带边缘半透明渐变效果
    _drawEdgeFade(canvas, size);
  }

  /// 斜线纹理
  void _drawStripePattern(Canvas canvas, Size size, Paint paint) {
    for (var i = -size.height; i < size.width + size.height; i += 4) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  /// 圆点纹理
  void _drawDotsPattern(Canvas canvas, Size size, Paint paint) {
    paint.style = PaintingStyle.fill;
    const dotRadius = 1.5;
    const spacing = 6.0;

    for (var x = spacing / 2; x < size.width; x += spacing) {
      for (var y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  /// 格子纹理
  void _drawGridPattern(Canvas canvas, Size size, Paint paint) {
    const spacing = 5.0;

    // 横线
    for (var y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // 竖线
    for (var x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  /// 渐变透明
  void _drawGradientPattern(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: [
        primaryColor.withOpacity(0.3),
        primaryColor.withOpacity(0.7),
        primaryColor.withOpacity(0.3),
      ],
    );
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  /// 和纸胶带花纹
  void _drawWashiPattern(Canvas canvas, Size size, Paint paint) {
    paint.style = PaintingStyle.fill;
    final random = math.Random(42);

    // 小花点缀
    for (var i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      const petalCount = 5;
      const petalRadius = 2.0;

      for (var j = 0; j < petalCount; j++) {
        final angle = (j * 2 * math.pi) / petalCount;
        final px = x + math.cos(angle) * petalRadius;
        final py = y + math.sin(angle) * petalRadius;
        canvas.drawCircle(Offset(px, py), 0.8, paint);
      }
      // 花心
      canvas.drawCircle(Offset(x, y), 0.6, paint..color = patternColor);
    }

    // 小叶子点缀
    for (var i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final leafPath = Path()
        ..moveTo(x, y - 2)
        ..quadraticBezierTo(x + 1.5, y, x, y + 2)
        ..quadraticBezierTo(x - 1.5, y, x, y - 2);
      canvas.drawPath(leafPath, paint..style = PaintingStyle.fill);
    }
  }

  /// 边缘渐变效果
  void _drawEdgeFade(Canvas canvas, Size size) {
    // 左边缘
    final leftGradient = LinearGradient(
      colors: [Colors.white.withOpacity(0.3), Colors.transparent],
    );
    final leftRect = Rect.fromLTWH(0, 0, 3, size.height);
    canvas.drawRect(
      leftRect,
      Paint()..shader = leftGradient.createShader(leftRect),
    );

    // 右边缘
    final rightGradient = LinearGradient(
      colors: [Colors.transparent, Colors.white.withOpacity(0.3)],
    );
    final rightRect = Rect.fromLTWH(size.width - 3, 0, 3, size.height);
    canvas.drawRect(
      rightRect,
      Paint()..shader = rightGradient.createShader(rightRect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ============================================
/// 相片长条卡片
/// ============================================
class _PhotoStripNoteCard extends StatelessWidget {
  const _PhotoStripNoteCard({
    required this.note,
    required this.width,
    this.onTap,
  });

  final NoteEntity note;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = context.blueGreyColorScheme;
    final hasImage = note.images.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.surfaceContainerHighest,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 相片条：展示至多 3 张
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: note.images.length == 1
                    ? AppNetworkImage(
                        url: note.images.first,
                        width: width - 26,
                        height: ((width - 26) / 16 * 9).floorToDouble(),
                      )
                    : Stack(
                        children: [
                          AppNetworkImage(
                            url: note.images.first,
                            width: width - 26,
                            height: ((width - 26) / 16 * 9).floorToDouble(),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${note.images.length - 1}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              note.createdAt.yMMMd,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (note.title.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
            if (note.content != null && note.content!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note.content!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ============================================
/// 拍立得风格卡片
/// ============================================
class _PolaroidNoteCard extends StatelessWidget {
  const _PolaroidNoteCard({
    required this.note,
    required this.width,
    this.onTap,
  });

  final NoteEntity note;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final random = math.Random(note.id.hashCode);
    final rotation = (random.nextDouble() - 0.5) * 0.06;

    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (note.images.isNotEmpty)
                _NoteImagesCollage(
                  images: note.images,
                  width: width - 24,
                  height: width - 24,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: theme.colorScheme.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16, width: double.infinity),
                      Icon(
                        Icons.format_quote,
                        size: 24,
                        color: theme.colorScheme.outline,
                      ),
                      if (note.title.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            note.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // 底部白边区域
              if (note.images.isNotEmpty && note.title.isNotEmpty)
                Text(
                  note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 8),
              if (note.content != null && note.content!.isNotEmpty) ...[
                Text(
                  note.content!,
                  // maxLines: 12,
                  // overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ] else
                Text(
                  note.createdAt.yMMMd,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
