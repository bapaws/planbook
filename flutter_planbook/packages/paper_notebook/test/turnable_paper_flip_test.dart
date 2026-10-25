import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_notebook/src/engine/turnable_paper_flip.dart';

void main() {
  test('right page has the large radius on the outer right', () {
    final right = BookVersoLeaf.borderRadius(spineOnLeft: true);
    expect(right.topRight, const Radius.circular(BookVersoLeaf.outerRadius));
    expect(right.bottomRight, const Radius.circular(BookVersoLeaf.outerRadius));
    expect(right.topLeft, const Radius.circular(BookVersoLeaf.spineRadius));
    expect(right.bottomLeft, const Radius.circular(BookVersoLeaf.spineRadius));
  });

  test('lifted flap keeps the rounded outer corner', () {
    const size = Size(320, 480);
    final fold = paperFoldOf(size: size, progress: 0.25, forward: true)!;
    final flap = roundedFoldFlapPath(
      fold: fold,
      pageBorderRadius: BookVersoLeaf.borderRadius(spineOnLeft: true),
    );
    final matrix = fold.mirror;

    final outerCorner = MatrixUtils.transformPoint(
      matrix,
      Offset(size.width - 1, size.height - 1),
    );
    final insideCorner = MatrixUtils.transformPoint(
      matrix,
      Offset(size.width - 12, size.height - 12),
    );

    expect(flap.contains(outerCorner), isFalse);
    expect(flap.contains(insideCorner), isTrue);
  });

  test('rest on left only near progress 1', () {
    expect(foldRestOnLeft(progress: 1), 1);
    expect(foldRestOnLeft(progress: 0.999), closeTo(1, 0.02));
    expect(foldRestOnLeft(progress: 0.5), 0);
    expect(foldRestOnLeft(progress: 0.75), 0);
    expect(foldRestOnLeft(progress: BookVersoLeaf.backRestProgress), 0);
  });

  test('left-swipe restore uses the same lighting as right-swipe', () {
    const samples = [0.0, 0.08, 0.35, 0.5, 0.92, 0.94, 1.0];
    for (final t in samples) {
      final light = foldFlapLight(progress: t);
      expect(light.rest, foldRestOnLeft(progress: t), reason: 't=$t');
    }
    final startLeft = foldFlapLight(progress: 1);
    expect(startLeft.rest, 1);
    expect(startLeft.strength, 0);
    expect(startLeft.crease, 0);
  });

  test('near the right leaf keeps flap shading', () {
    final atRight = foldFlapLight(progress: 0);
    expect(atRight.rest, 0);
    expect(atRight.strength, closeTo(BookVersoLeaf.landedLight, 0.02));
    expect(atRight.crease, greaterThan(0.4));
    final smallLift = foldFlapLight(progress: 0.08);
    expect(smallLift.strength, closeTo(BookVersoLeaf.landedLight, 0.02));
    expect(smallLift.crease, greaterThan(0.4));
  });

  test('leaving the left leaf keeps flap shading', () {
    final light = foldFlapLight(progress: 0.92);
    expect(light.rest, 0);
    expect(light.strength, closeTo(BookVersoLeaf.landedLight, 0.02));
    expect(light.crease, greaterThan(0.4));
  });

  test('lighting hands off as left rest fades', () {
    final atRestEdge = foldFlapLight(progress: BookVersoLeaf.backRestProgress);
    expect(atRestEdge.rest, 0);
    expect(atRestEdge.strength, closeTo(BookVersoLeaf.landedLight, 0.02));
  });

  test('mid-flip is the lighting peak', () {
    final light = foldFlapLight(progress: 0.5);
    expect(light.strength, closeTo(0.85, 0.02));
    expect(light.crease, closeTo(0.85, 0.02));
  });
}
