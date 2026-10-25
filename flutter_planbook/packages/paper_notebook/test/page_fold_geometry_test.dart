import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_notebook/src/engine/page_fold_geometry.dart';

void main() {
  const size = Size(300, 500);

  test('forward fold peels from the right and grows', () {
    final early = PageFoldGeometry.lerp(
      size: size,
      progress: 0.15,
      forward: true,
    );
    final mid = PageFoldGeometry.lerp(size: size, progress: 0.5, forward: true);
    expect(early, isNotNull);
    expect(mid, isNotNull);
    expect(early!.grab.dx, greaterThan(mid!.grab.dx));
    expect(early.grab.dx, lessThan(size.width));
    expect(mid.grab.dx, lessThan(size.width / 2));
  });

  test('back fold peels from the left', () {
    final fold = PageFoldGeometry.lerp(
      size: size,
      progress: 0.3,
      forward: false,
    );
    expect(fold, isNotNull);
    expect(fold!.grab.dx, greaterThan(0));
    expect(fold.origin.dx, 0);
  });

  test('restore start is a forward fold almost finished', () {
    final start = PageFoldGeometry.lerp(
      size: size,
      progress: 0.85,
      forward: true,
    );
    final end = PageFoldGeometry.lerp(size: size, progress: 0.2, forward: true);
    expect(start, isNotNull);
    expect(end, isNotNull);
    expect(start!.origin.dx, size.width);
    expect(start.grab.dx, lessThan(end!.grab.dx));
    expect(start.remaining.contains(Offset(1, size.height / 2)), isTrue);
  });

  test('tilt lifts the corner mid-turn and lays it flat at both ends', () {
    PageFoldGeometry foldAt(double t) => PageFoldGeometry.lerp(
      size: size,
      progress: t,
      forward: true,
      tilt: 0.3,
    )!;

    // 没有倾斜时折痕是竖的，看起来像整页水平推走。
    final flat = PageFoldGeometry.lerp(
      size: size,
      progress: 0.5,
      forward: true,
    )!;
    expect(flat.isVerticalFold, isTrue);

    final mid = foldAt(0.5);
    expect(mid.isVerticalFold, isFalse);
    expect(mid.grab.dy, lessThan(mid.origin.dy));
    expect((mid.foldA.dx - mid.foldB.dx).abs(), greaterThan(8));

    // 起手贴着右下角，落定回到书脊高度，两端都不歪。
    expect(foldAt(0.02).grab.dy, closeTo(size.height - 1, 12));
    expect(foldAt(0.99).grab.dy, closeTo(size.height - 1, 12));
  });

  test('idle progress has no fold', () {
    expect(
      PageFoldGeometry.lerp(size: size, progress: 0, forward: true),
      isNull,
    );
  });

  test('forward fold keeps the left spine planted', () {
    for (final t in [0.1, 0.3, 0.5, 0.7, 0.9]) {
      final fold = PageFoldGeometry.lerp(
        size: size,
        progress: t,
        forward: true,
      );
      expect(fold, isNotNull, reason: 't=$t');
      final remaining = fold!.remaining;
      expect(
        remaining.contains(const Offset(1, 1)),
        isTrue,
        reason: 'top of spine must stay at t=$t',
      );
      expect(
        remaining.contains(Offset(1, size.height - 1)),
        isTrue,
        reason: 'bottom of spine must stay at t=$t',
      );
    }
  });

  test('pointer grab tilts the fold with finger Y', () {
    const origin = Offset(300, 500);
    final fold = PageFoldGeometry.fromPointer(
      size: size,
      origin: origin,
      grab: const Offset(180, 320),
      forward: true,
    );
    expect(fold, isNotNull);
    expect(fold!.isVerticalFold, isFalse);
    expect((fold.foldA.dx - fold.foldB.dx).abs(), greaterThan(8));
    expect(fold.remaining.contains(const Offset(1, 1)), isTrue);
    expect(fold.remaining.contains(Offset(1, size.height - 1)), isTrue);
  });

  test('top-right corner grab peels from the top', () {
    const origin = Offset(300, 0);
    final fold = PageFoldGeometry.fromPointer(
      size: size,
      origin: origin,
      grab: const Offset(190, 140),
      forward: true,
    );
    expect(fold, isNotNull);
    expect(fold!.origin.dy, 0);
    expect(fold.isVerticalFold, isFalse);
    expect(fold.remaining.contains(const Offset(1, 1)), isTrue);
  });

  test('edge origin sits on the page edge at finger Y', () {
    expect(
      pageFoldEdgeOrigin(
        size: size,
        local: const Offset(280, 120),
        forward: true,
      ),
      const Offset(300, 120),
    );
    expect(
      pageFoldEdgeOrigin(
        size: size,
        local: const Offset(20, 400),
        forward: false,
      ),
      const Offset(0, 400),
    );
  });

  test('fold crease stays on the page', () {
    final fold = PageFoldGeometry.lerp(
      size: size,
      progress: 0.35,
      forward: true,
    );
    expect(fold, isNotNull);
    final page = Offset.zero & size;
    expect(page.inflate(0.5).contains(fold!.foldA), isTrue);
    expect(page.inflate(0.5).contains(fold.foldB), isTrue);
  });

  test('settle interpolates a tilted grab without flattening', () {
    const origin = Offset(300, 200);
    const from = Offset(160, 80);
    final start = PageFoldGeometry.fromPointer(
      size: size,
      origin: origin,
      grab: from,
      forward: true,
    );
    final midGrab = pageFoldSettleGrab(
      size: size,
      origin: origin,
      from: from,
      t: 0.35,
      complete: true,
      forward: true,
    );
    final mid = PageFoldGeometry.fromPointer(
      size: size,
      origin: origin,
      grab: midGrab,
      forward: true,
    );
    expect(start, isNotNull);
    expect(mid, isNotNull);
    expect(start!.isVerticalFold, isFalse);
    expect(mid!.isVerticalFold, isFalse);
    expect((mid.grab.dy - from.dy).abs(), lessThan(1));
    expect((mid.foldA.dx - mid.foldB.dx).abs(), greaterThan(8));
  });

  test('settle grab starts at the finger and lands flat on complete', () {
    const origin = Offset(300, 200);
    const from = Offset(160, 80);
    expect(
      pageFoldSettleGrab(
        size: size,
        origin: origin,
        from: from,
        t: 0,
        complete: true,
        forward: true,
      ),
      from,
    );
    final backLand = pageFoldSettleGrab(
      size: size,
      origin: origin,
      from: from,
      t: 1,
      complete: true,
      forward: false,
    );
    expect(backLand.dx, closeTo(origin.dx, 1));
    expect(backLand.dy, closeTo(origin.dy, 1));
  });

  test('completing a tilted fold keeps the crease translating', () {
    const origin = Offset(300, 200);
    const from = Offset(80, 80);
    final start = PageFoldGeometry.fromPointer(
      size: size,
      origin: origin,
      grab: from,
      forward: true,
    );
    expect(start, isNotNull);
    final startTilt = (start!.foldA.dx - start.foldB.dx).abs();
    expect(startTilt, greaterThan(20));

    final endGrab = pageFoldSettleGrab(
      size: size,
      origin: origin,
      from: from,
      t: 1,
      complete: true,
      forward: true,
    );
    // 方案 A：完成 settle 的后半段会把折痕从倾斜过渡到更接近竖直，
    // 因此 endGrab.dy 会向 origin.dy 收敛。
    expect(endGrab.dy, closeTo(origin.dy, 1));
    expect(endGrab.dx, lessThan(0));

    final midGrab = pageFoldSettleGrab(
      size: size,
      origin: origin,
      from: from,
      t: 0.5,
      complete: true,
      forward: true,
    );
    expect(midGrab.dy, closeTo(from.dy, 1));
    expect(midGrab.dx, closeTo((from.dx + endGrab.dx) / 2, 1));
  });

  test('tilted crease slides as a whole instead of pivoting on the spine', () {
    const origin = Offset(300, 500);
    const grab = Offset(180, 320);
    final fold = PageFoldGeometry.fromPointer(
      size: size,
      origin: origin,
      grab: grab,
      forward: true,
    );
    expect(fold, isNotNull);
    expect(fold!.isVerticalFold, isFalse);
    expect(
      fold.grab.dx,
      closeTo(grab.dx, 1),
      reason: 'grab must not be pulled onto the spine circle',
    );
    expect(fold.grab.dy, closeTo(grab.dy, 1));
    final minX = fold.foldA.dx < fold.foldB.dx ? fold.foldA.dx : fold.foldB.dx;
    expect(
      minX,
      greaterThan(8),
      reason: 'crease should not plant one end on the spine',
    );
    expect(fold.remaining.contains(const Offset(1, 1)), isTrue);
    expect(fold.remaining.contains(Offset(1, size.height - 1)), isTrue);
  });

  test('mid-edge grab peels from finger height not the bottom corner', () {
    final origin = pageFoldEdgeOrigin(
      size: size,
      local: const Offset(290, 200),
      forward: true,
    );
    final fold = PageFoldGeometry.fromPointer(
      size: size,
      origin: origin,
      grab: const Offset(160, 160),
      forward: true,
    );
    expect(fold, isNotNull);
    expect(fold!.origin.dy, closeTo(200, 1));
    expect(fold.origin.dy, isNot(size.height));
    expect(fold.isVerticalFold, isFalse);
  });
}
