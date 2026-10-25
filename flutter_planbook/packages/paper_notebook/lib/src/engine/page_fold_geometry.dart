import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 抓起的页角。向前翻右边，向后翻左边。
enum PageFoldCorner {
  topRight,
  bottomRight,
  topLeft,
  bottomLeft;

  bool get forward =>
      this == PageFoldCorner.topRight || this == PageFoldCorner.bottomRight;

  Offset originOf(Size size) => switch (this) {
    PageFoldCorner.topRight => Offset(size.width, 0),
    PageFoldCorner.bottomRight => Offset(size.width, size.height),
    PageFoldCorner.topLeft => Offset.zero,
    PageFoldCorner.bottomLeft => Offset(0, size.height),
  };

  static PageFoldCorner at({
    required Offset local,
    required Size size,
    required bool forward,
  }) {
    final top = local.dy < size.height / 2;
    if (forward) {
      return top ? PageFoldCorner.topRight : PageFoldCorner.bottomRight;
    }
    return top ? PageFoldCorner.topLeft : PageFoldCorner.bottomLeft;
  }
}

/// 起卷点：书页左右边缘上与手指同高的位置（iOS 书本翻页）。
Offset pageFoldEdgeOrigin({
  required Size size,
  required Offset local,
  required bool forward,
}) {
  final maxY = math.max(1.0, size.height - 1.0);
  final y = local.dy.clamp(1.0, maxY).toDouble();
  return Offset(forward ? size.width : 0.0, y);
}

/// StPageFlip 式折页几何：抓角沿折线翻到纸背（MIT：Nodlik/StPageFlip 的折线思路）。
class PageFoldGeometry {
  const PageFoldGeometry({
    required this.size,
    required this.origin,
    required this.grab,
    required this.mid,
    required this.normal,
    required this.foldA,
    required this.foldB,
    required this.peeled,
    required this.flap,
    required this.remaining,
  });

  final Size size;
  final Offset origin;
  final Offset grab;
  final Offset mid;
  final Offset normal;
  final Offset foldA;
  final Offset foldB;
  final Path peeled;
  final Path flap;
  final Path remaining;

  /// 折线是否接近竖直（抓点与原点同高）。
  bool get isVerticalFold => (grab.dy - origin.dy).abs() < 1.5;

  /// 翻页进度 0→1：抓点沿水平走过约两倍页宽。
  double get progress {
    final span = size.width * 2;
    if (span < 1) return 0;
    if (origin.dx > size.width / 2) {
      return ((origin.dx - grab.dx) / span).clamp(0.0, 1.0);
    }
    return ((grab.dx - origin.dx) / span).clamp(0.0, 1.0);
  }

  /// [progress] 0→1：自动翻页时沿底角走；[corner] 可指定顶角。
  /// [origin] 保留松手时的起卷点，避免补间跳到页角。
  /// [grab] 保留掀起的高度，松手后按这个角度把页角补完，而不是收成水平折。
  ///
  /// [tilt] 是抓点中途往上抬的高度（占页高的比例）。抬起来折痕才会倾斜，
  /// 像手从右下角把页角掀起；两端都抬 0，起手和落定仍然贴着页角和书脊。
  static PageFoldGeometry? lerp({
    required Size size,
    required double progress,
    required bool forward,
    PageFoldCorner? corner,
    Offset? origin,
    Offset? grab,
    double tilt = 0,
  }) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0.001 || size.width < 8 || size.height < 8) return null;
    final resolved =
        corner ??
        (forward ? PageFoldCorner.bottomRight : PageFoldCorner.bottomLeft);
    final start = origin ?? resolved.originOf(size);
    final lift = tilt <= 0 ? 0.0 : size.height * tilt * math.sin(t * math.pi);
    final raw = Offset(
      forward ? size.width * (1 - 2 * t) : size.width * (2 * t),
      (grab?.dy ?? start.dy) - lift,
    );
    return fromPointer(size: size, origin: start, grab: raw, forward: forward);
  }

  /// 手指位置驱动的折页：抓点可与原点不同高，折线随手指倾斜。
  static PageFoldGeometry? fromPointer({
    required Size size,
    required Offset origin,
    required Offset grab,
    required bool forward,
  }) {
    if (size.width < 8 || size.height < 8) return null;
    final hit = fromGrab(size: size, origin: origin, grab: grab);
    if (hit != null) return hit;
    return _farthestValid(size: size, origin: origin, grab: grab);
  }

  static PageFoldGeometry? fromGrab({
    required Size size,
    required Offset origin,
    required Offset grab,
  }) {
    final delta = grab - origin;
    if (delta.distance < 4) return null;
    final mid = Offset((origin.dx + grab.dx) / 2, (origin.dy + grab.dy) / 2);
    final normal = origin - grab;
    final peeledPts = _clipRect(size, mid, normal);
    final remainingPts = _clipRect(size, mid, -normal);
    if (peeledPts.length < 3 || remainingPts.length < 3) return null;
    final boundX = origin.dx > size.width / 2 ? 0.0 : size.width;
    if (_strictlyInside(Offset(boundX, 0), mid, normal) ||
        _strictlyInside(Offset(boundX, size.height), mid, normal)) {
      return null;
    }
    final peeled = _polygon(peeledPts);
    final flapPts = [for (final p in peeledPts) _reflect(p, mid, normal)];
    final fold = _foldEnds(size, mid, normal);
    return PageFoldGeometry(
      size: size,
      origin: origin,
      grab: grab,
      mid: mid,
      normal: normal,
      foldA: fold.$1,
      foldB: fold.$2,
      peeled: peeled,
      flap: _polygon(flapPts),
      remaining: _polygon(remainingPts),
    );
  }

  Matrix4 get mirror {
    final d = normal.distance;
    if (d < 1e-6) return Matrix4.identity();
    final nx = normal.dx / d;
    final ny = normal.dy / d;
    return Matrix4.identity()
      ..translateByDouble(mid.dx, mid.dy, 0, 1)
      ..multiply(
        Matrix4(
          1 - 2 * nx * nx,
          -2 * nx * ny,
          0,
          0,
          -2 * nx * ny,
          1 - 2 * ny * ny,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          1,
        ),
      )
      ..translateByDouble(-mid.dx, -mid.dy, 0, 1);
  }
}

/// 松手后把抓点补到落点。保持掀起高度，整条折痕一起平移，不绕书脊转平。
Offset pageFoldSettleGrab({
  required Size size,
  required Offset origin,
  required Offset from,
  required double t,
  required bool complete,
  required bool forward,
}) {
  final u = t.clamp(0.0, 1.0);
  if (u <= 0) return from;
  if (complete && forward) {
    // 只在 settle 后半段把折痕从「倾斜」过渡到「更接近竖直」，
    // 避免斜折时一端先贴到书脊导致几何被边界条件卡住后出现闪跳。
    //
    // u 早期保持 from.dy 不变（配合已有单测：不提前“转平”）。
    const rotateStart = 0.75;
    final rotU = ((u - rotateStart) / (1.0 - rotateStart)).clamp(0.0, 1.0);
    final rot = Curves.easeInOutCubic.transform(rotU);

    final settledDx = from.dx + (-size.width - from.dx) * u;
    final settledDy = from.dy + (origin.dy - from.dy) * rot;
    return Offset(settledDx, settledDy);
  }
  if (!complete && !forward) {
    return Offset.lerp(from, Offset(-size.width, from.dy), u)!;
  }
  return Offset.lerp(from, origin, u)!;
}

PageFoldGeometry? _farthestValid({
  required Size size,
  required Offset origin,
  required Offset grab,
}) {
  var lo = 0.0;
  var hi = 1.0;
  Offset? best;
  for (var i = 0; i < 10; i++) {
    final mid = (lo + hi) / 2;
    final g = Offset.lerp(origin, grab, mid)!;
    if (PageFoldGeometry.fromGrab(size: size, origin: origin, grab: g) !=
        null) {
      best = g;
      lo = mid;
    } else {
      hi = mid;
    }
  }
  if (best == null) return null;
  return PageFoldGeometry.fromGrab(size: size, origin: origin, grab: best);
}

Offset _reflect(Offset point, Offset mid, Offset normal) {
  final d = normal.distance;
  if (d < 1e-6) return point;
  final nx = normal.dx / d;
  final ny = normal.dy / d;
  final dist = (point.dx - mid.dx) * nx + (point.dy - mid.dy) * ny;
  return Offset(point.dx - 2 * dist * nx, point.dy - 2 * dist * ny);
}

bool _strictlyInside(Offset point, Offset mid, Offset normal) {
  return (point.dx - mid.dx) * normal.dx + (point.dy - mid.dy) * normal.dy >
      1.0;
}

bool _inside(Offset point, Offset mid, Offset normal) {
  return (point.dx - mid.dx) * normal.dx + (point.dy - mid.dy) * normal.dy >=
      -0.35;
}

List<Offset> _clipRect(Size size, Offset mid, Offset normal) {
  final corners = [
    Offset.zero,
    Offset(size.width, 0),
    Offset(size.width, size.height),
    Offset(0, size.height),
  ];
  final out = <Offset>[];
  for (var i = 0; i < 4; i++) {
    final a = corners[i];
    final b = corners[(i + 1) % 4];
    final aIn = _inside(a, mid, normal);
    final bIn = _inside(b, mid, normal);
    if (aIn) out.add(a);
    if (aIn != bIn) {
      final t = _hit(a, b, mid, normal);
      if (t != null) out.add(Offset.lerp(a, b, t)!);
    }
  }
  return out;
}

double? _hit(Offset a, Offset b, Offset mid, Offset normal) {
  final ab = b - a;
  final den = ab.dx * normal.dx + ab.dy * normal.dy;
  if (den.abs() < 1e-8) return null;
  final t = ((mid.dx - a.dx) * normal.dx + (mid.dy - a.dy) * normal.dy) / den;
  if (t < 0 || t > 1) return null;
  return t;
}

(Offset, Offset) _foldEnds(Size size, Offset mid, Offset normal) {
  final dir = Offset(-normal.dy, normal.dx);
  final len = math.sqrt(size.width * size.width + size.height * size.height);
  if (dir.distance < 1e-6) {
    return (Offset(mid.dx, 0), Offset(mid.dx, size.height));
  }
  final u = dir / dir.distance;
  final raw = (mid - u * len, mid + u * len);
  return _clipSegmentToRect(raw.$1, raw.$2, Offset.zero & size) ?? raw;
}

(Offset, Offset)? _clipSegmentToRect(Offset a, Offset b, Rect rect) {
  var t0 = 0.0;
  var t1 = 1.0;
  final dx = b.dx - a.dx;
  final dy = b.dy - a.dy;

  bool clip(double p, double q) {
    if (p.abs() < 1e-12) return q >= 0;
    final r = q / p;
    if (p < 0) {
      if (r > t1) return false;
      if (r > t0) t0 = r;
    } else {
      if (r < t0) return false;
      if (r < t1) t1 = r;
    }
    return true;
  }

  if (!clip(-dx, a.dx - rect.left) ||
      !clip(dx, rect.right - a.dx) ||
      !clip(-dy, a.dy - rect.top) ||
      !clip(dy, rect.bottom - a.dy)) {
    return null;
  }
  return (Offset.lerp(a, b, t0)!, Offset.lerp(a, b, t1)!);
}

Path _polygon(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var i = 1; i < points.length; i++) {
    path.lineTo(points[i].dx, points[i].dy);
  }
  return path..close();
}
